#include "analyzer/VectorizerOracle.h"

#include "analyzer/LLVMAnalyses.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/DiagnosticHandler.h>
#include <llvm/IR/DiagnosticInfo.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/Remarks/Remark.h>
#include <llvm/Remarks/RemarkParser.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/Path.h>
#include <llvm/Transforms/Utils/Cloning.h>
#include <llvm/Transforms/Utils/ValueMapper.h>
#include <llvm/Transforms/Vectorize/LoopVectorize.h>

namespace analyzer {

namespace {

/// Captures optimization remarks about the loops we care about. A remark's
/// code region is the loop header, or the block of the instruction it is
/// about, so every block of an asked-about loop maps to that loop's
/// (original) header.
class RemarkCollector : public llvm::DiagnosticHandler {
public:
  RemarkCollector(
      const std::map<const llvm::BasicBlock*, const llvm::BasicBlock*>& toOrig,
      std::map<const llvm::BasicBlock*, std::vector<VectorizerRemark>>& out)
      : toOrig(toOrig), out(out) {}

  // Enabling remarks also makes the vectorizer continue past the first
  // blocker (OptimizationRemarkEmitter::allowExtraAnalysis).
  bool isAnalysisRemarkEnabled(llvm::StringRef) const override {
    return true;
  }
  bool isMissedOptRemarkEnabled(llvm::StringRef) const override {
    return true;
  }
  bool isPassedOptRemarkEnabled(llvm::StringRef) const override {
    return true;
  }
  bool isAnyRemarkEnabled() const override {
    return true;
  }

  bool handleDiagnostics(const llvm::DiagnosticInfo& DI) override {
    const auto* R = llvm::dyn_cast<llvm::DiagnosticInfoIROptimization>(&DI);
    if (!R)
      return false;
    const auto* region =
        llvm::dyn_cast_or_null<llvm::BasicBlock>(R->getCodeRegion());
    auto it = region ? toOrig.find(region) : toOrig.end();
    if (it == toOrig.end())
      return true;  // A loop we didn't ask about; swallow it.

    VectorizerRemark remark;
    switch (DI.getKind()) {
      case llvm::DK_OptimizationRemark:
        remark.kind = VectorizerRemark::Kind::Passed;
        break;
      case llvm::DK_OptimizationRemarkMissed:
        remark.kind = VectorizerRemark::Kind::Missed;
        break;
      default:
        remark.kind = VectorizerRemark::Kind::Analysis;
        break;
    }
    remark.name = R->getRemarkName().str();
    remark.message = R->getMsg();
    if (R->isLocationAvailable())
      remark.location = R->getLocationStr();
    out[it->second].push_back(std::move(remark));
    return true;
  }

private:
  const std::map<const llvm::BasicBlock*, const llvm::BasicBlock*>& toOrig;
  std::map<const llvm::BasicBlock*, std::vector<VectorizerRemark>>& out;
};

/// Lets the vectorizer look at a loop it has already processed again.
void untag(llvm::Loop* L, llvm::LLVMContext& ctx) {
  if (!L->getLoopID())
    return;
  L->setLoopID(llvm::makePostTransformationMetadata(
      ctx, L->getLoopID(),
      {"llvm.loop.isvectorized", "llvm.loop.unroll.runtime.disable"}, {}));
}

using RemarkMap = std::map<const llvm::BasicBlock*, std::vector<VectorizerRemark>>;

/// Runs LoopVectorize over `functions`, capturing remarks for the blocks in
/// `toOrig`.
void runVectorizer(
    llvm::LLVMContext& ctx, llvm::FunctionAnalysisManager& FAM,
    const std::vector<llvm::Function*>& functions,
    const std::map<const llvm::BasicBlock*, const llvm::BasicBlock*>& toOrig,
    RemarkMap& out) {
  // Same context as the original module, so swap the handler in and out.
  std::unique_ptr<llvm::DiagnosticHandler> previous =
      ctx.getDiagnosticHandler();
  ctx.setDiagnosticHandler(std::make_unique<RemarkCollector>(toOrig, out));
  llvm::FunctionPassManager FPM;
  FPM.addPass(llvm::LoopVectorizePass());
  for (llvm::Function* F : functions)
    FPM.run(*F, FAM);
  ctx.setDiagnosticHandler(std::move(previous));
}

}  // namespace

VectorizerOracle::VectorizerOracle(llvm::Module& M, llvm::TargetMachine* TM,
                                   const Work& work)
    : M(M), TM(TM) {
  llvm::ValueToValueMapTy VMap;
  std::unique_ptr<llvm::Module> clone = llvm::CloneModule(M, VMap);

  // Map clone loop blocks back to the original headers, and note which
  // loops need the "already vectorized" tag removed before re-asking.
  std::map<const llvm::BasicBlock*, const llvm::BasicBlock*> toOrig;
  std::vector<llvm::BasicBlock*> needsUntag;
  std::vector<llvm::Function*> cloneFunctions;
  for (const auto& [F, catalog] : work) {
    bool any = false;
    for (const LogicalLoop& LL : catalog->loops()) {
      // The vectorizer only handles innermost loops by default.
      if (!LL.innermost || !LL.oracleCopy)
        continue;
      if (LL.state != VectorizerState::NotVectorized &&
          LL.state != VectorizerState::InterleavedOnly)
        continue;
      llvm::BasicBlock* header = LL.oracleCopy->getHeader();
      for (llvm::BasicBlock* BB : LL.oracleCopy->blocks())
        toOrig[llvm::cast<llvm::BasicBlock>(VMap[BB])] = header;
      if (llvm::getBooleanLoopAttribute(LL.oracleCopy,
                                        "llvm.loop.isvectorized"))
        needsUntag.push_back(llvm::cast<llvm::BasicBlock>(VMap[header]));
      any = true;
    }
    if (any)
      cloneFunctions.push_back(llvm::cast<llvm::Function>(VMap[F]));
  }
  if (cloneFunctions.empty())
    return;

  AnalysisStack stack(TM);
  llvm::FunctionAnalysisManager& FAM = stack.fam();
  for (llvm::BasicBlock* header : needsUntag) {
    llvm::LoopInfo& LI =
        FAM.getResult<llvm::LoopAnalysis>(*header->getParent());
    llvm::Loop* L = LI.getLoopFor(header);
    if (L && L->getHeader() == header)
      untag(L, clone->getContext());
  }
  runVectorizer(clone->getContext(), FAM, cloneFunctions, toOrig, remarks_);
}

const std::vector<VectorizerRemark>*
VectorizerOracle::remarksFor(const llvm::BasicBlock* header) const {
  auto it = remarks_.find(header);
  return it == remarks_.end() ? nullptr : &it->second;
}

VectorizerOracle::Retry VectorizerOracle::retry(llvm::Function& F,
                                                const LogicalLoop& LL,
                                                const Change& change) const {
  Retry result;
  if (!LL.oracleCopy)
    return result;
  llvm::ValueToValueMapTy VMap;
  std::unique_ptr<llvm::Module> clone = llvm::CloneModule(M, VMap);
  auto* cloneF = llvm::cast<llvm::Function>(VMap[&F]);
  auto* header =
      llvm::cast<llvm::BasicBlock>(VMap[LL.oracleCopy->getHeader()]);

  AnalysisStack stack(TM);
  llvm::FunctionAnalysisManager& FAM = stack.fam();
  llvm::Loop* L = FAM.getResult<llvm::LoopAnalysis>(*cloneF).getLoopFor(header);
  if (!L || L->getHeader() != header)
    return result;
  untag(L, clone->getContext());
  change(*cloneF, *L);
  std::map<const llvm::BasicBlock*, const llvm::BasicBlock*> toOrig;
  for (llvm::BasicBlock* BB : L->blocks())
    toOrig[BB] = header;
  FAM.invalidate(*cloneF, llvm::PreservedAnalyses::none());

  RemarkMap out;
  runVectorizer(clone->getContext(), FAM, {cloneF}, toOrig, out);
  for (const VectorizerRemark& R : out[header]) {
    if (R.kind == VectorizerRemark::Kind::Passed && R.name == "Vectorized") {
      result.vectorized = true;
      result.message = R.message;
      return result;
    }
    if (result.message.empty() && R.kind != VectorizerRemark::Kind::Passed &&
        R.name != "MissedDetails")
      result.message = R.message;
  }
  return result;
}

// --- CompileRemarks ---------------------------------------------------------

namespace {

std::string remarkKey(const std::string& function, llvm::StringRef file,
                      unsigned line, unsigned col) {
  return function + "|" + llvm::sys::path::filename(file).str() + ":" +
         std::to_string(line) + ":" + std::to_string(col);
}

std::string signature(const std::vector<VectorizerRemark>& remarks) {
  std::string out;
  for (const auto& R : remarks)
    out += R.name + ";";
  return out;
}

}  // namespace

std::unique_ptr<CompileRemarks> CompileRemarks::load(const std::string& path,
                                                     std::string& error) {
  auto buffer = llvm::MemoryBuffer::getFile(path);
  if (!buffer) {
    error = "can't read " + path + ": " + buffer.getError().message();
    return nullptr;
  }
  auto parser = llvm::remarks::createRemarkParser(llvm::remarks::Format::YAML,
                                                  (*buffer)->getBuffer());
  if (!parser) {
    error = llvm::toString(parser.takeError());
    return nullptr;
  }
  auto result = std::make_unique<CompileRemarks>();
  // The vectorizer emits a loop's analysis remarks (located at the
  // instruction they're about) and then one closing remark at the loop's
  // start: "vectorized loop", "interleaved loop", "loop not vectorized",
  // or the interleaving decision after a cost-model miss.
  std::map<std::string, std::vector<VectorizerRemark>> pending;
  while (true) {
    auto next = (*parser)->next();
    if (!next) {
      llvm::Error E = next.takeError();
      if (E.isA<llvm::remarks::EndOfFileError>()) {
        llvm::consumeError(std::move(E));
        break;
      }
      error = path + ": " + llvm::toString(std::move(E));
      return nullptr;
    }
    const llvm::remarks::Remark& R = **next;
    if (R.PassName != "loop-vectorize")
      continue;
    VectorizerRemark out;
    switch (R.RemarkType) {
      case llvm::remarks::Type::Passed:
        out.kind = VectorizerRemark::Kind::Passed;
        break;
      case llvm::remarks::Type::Missed:
        out.kind = VectorizerRemark::Kind::Missed;
        break;
      default:
        out.kind = VectorizerRemark::Kind::Analysis;
        break;
    }
    out.name = R.RemarkName.str();
    out.message = R.getArgsAsMsg();
    std::string function = R.FunctionName.str();
    std::string key;
    if (R.Loc) {
      out.location = llvm::sys::path::filename(R.Loc->SourceFilePath).str() +
                     ":" + std::to_string(R.Loc->SourceLine) + ":" +
                     std::to_string(R.Loc->SourceColumn);
      key = remarkKey(function, R.Loc->SourceFilePath, R.Loc->SourceLine,
                      R.Loc->SourceColumn);
    }
    std::vector<VectorizerRemark>& group = pending[function];
    group.push_back(std::move(out));
    const VectorizerRemark& last = group.back();
    bool closing = (last.kind != VectorizerRemark::Kind::Analysis &&
                    last.name != "VectorizationNotBeneficial") ||
                   last.name == "AllDisabled";
    if (!closing)
      continue;
    if (!key.empty())
      result->byLoop_[key].push_back(std::move(group));
    group.clear();
  }
  return result;
}

const std::vector<VectorizerRemark>*
CompileRemarks::find(const std::string& function, const llvm::DebugLoc& start,
                     bool* ambiguous) const {
  *ambiguous = false;
  if (!start)
    return nullptr;
  auto it = byLoop_.find(
      remarkKey(function, start->getFilename(), start.getLine(), start.getCol()));
  if (it == byLoop_.end() || it->second.empty())
    return nullptr;
  // Callers ask about loops the IR shows weren't vectorized, so an outcome
  // that ends in "vectorized loop" belongs to another copy.
  std::vector<const std::vector<VectorizerRemark>*> candidates;
  for (const auto& o : it->second) {
    bool vectorized = false;
    for (const auto& R : o)
      vectorized |= R.kind == VectorizerRemark::Kind::Passed &&
                    R.name == "Vectorized";
    if (!vectorized)
      candidates.push_back(&o);
  }
  if (candidates.empty())
    return nullptr;
  for (const auto* o : candidates)
    if (signature(*o) != signature(*candidates.front())) {
      *ambiguous = true;
      return nullptr;
    }
  return candidates.front();
}

}  // namespace analyzer
