#include "analyzer/MemoryAccessAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/LoopContext.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/Dominators.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>

#include <map>
#include <string>

namespace analyzer {

namespace {

enum class AccessPattern { ContiguousLike, Strided, Irregular };

/// Get base pointer for naming (GEP base or the pointer itself).
llvm::Value* getBasePointer(llvm::Value* ptr) {
  if (auto* GEP = llvm::dyn_cast<llvm::GetElementPtrInst>(ptr))
    return GEP->getPointerOperand();
  return ptr;
}

std::string getBaseName(llvm::Value* base) {
  if (!base) return "ptr";
  if (base->hasName()) return base->getName().str();
  if (llvm::isa<llvm::Argument>(base))
    return "arg";
  return "base";
}

/// Heuristic: GEP with single loop-variant index that is phi or add(phi,const) => contiguous-like or strided.
bool isGEPWithLoopVariantIndex(llvm::Value* ptr, llvm::Loop* L, bool* outUnitStep) {
  *outUnitStep = false;
  llvm::GetElementPtrInst* GEP = llvm::dyn_cast<llvm::GetElementPtrInst>(ptr);
  if (!GEP) return false;
  for (unsigned i = 1; i < GEP->getNumOperands(); ++i) {
    llvm::Value* idx = GEP->getOperand(i);
    if (L->isLoopInvariant(idx)) continue;
    if (llvm::isa<llvm::PHINode>(idx)) {
      *outUnitStep = true;
      return true;
    }
    if (auto* add = llvm::dyn_cast<llvm::BinaryOperator>(idx)) {
      if (add->getOpcode() == llvm::Instruction::Add &&
          (llvm::isa<llvm::Constant>(add->getOperand(0)) || llvm::isa<llvm::Constant>(add->getOperand(1)))) {
        *outUnitStep = true;
        return true;
      }
      return true;
    }
    return true;
  }
  return false;
}

void analyzeLoopMemory(llvm::Loop* L, unsigned& loadCount, unsigned& storeCount,
                       AccessPattern& pattern, std::string& baseName,
                       unsigned& loadsFromSameBase) {
  loadCount = 0;
  storeCount = 0;
  pattern = AccessPattern::ContiguousLike;
  baseName.clear();
  loadsFromSameBase = 0;
  std::map<llvm::Value*, unsigned> loadsPerBase;

  for (llvm::BasicBlock* BB : L->blocks()) {
    for (llvm::Instruction& I : *BB) {
      if (auto* load = llvm::dyn_cast<llvm::LoadInst>(&I)) {
        ++loadCount;
        llvm::Value* ptr = load->getPointerOperand();
        llvm::Value* base = getBasePointer(ptr);
        loadsPerBase[base]++;
        if (baseName.empty()) baseName = getBaseName(base);

        if (!llvm::isa<llvm::GetElementPtrInst>(ptr)) {
          pattern = AccessPattern::Irregular;
        } else {
          bool unitStep = false;
          if (isGEPWithLoopVariantIndex(ptr, L, &unitStep)) {
            if (pattern != AccessPattern::Irregular)
              pattern = unitStep ? AccessPattern::ContiguousLike : AccessPattern::Strided;
            if (!unitStep) pattern = AccessPattern::Strided;
          }
        }
      } else if (auto* store = llvm::dyn_cast<llvm::StoreInst>(&I)) {
        ++storeCount;
        llvm::Value* ptr = store->getPointerOperand();
        llvm::Value* base = getBasePointer(ptr);
        if (baseName.empty()) baseName = getBaseName(base);
        if (!llvm::isa<llvm::GetElementPtrInst>(ptr))
          pattern = AccessPattern::Irregular;
        else {
          bool unitStep = false;
          if (isGEPWithLoopVariantIndex(ptr, L, &unitStep) && !unitStep)
            pattern = AccessPattern::Strided;
        }
      }
    }
  }

  for (const auto& p : loadsPerBase) {
    if (p.second > 1 && loadsFromSameBase < p.second)
      loadsFromSameBase = p.second;
  }
}

}  // namespace

void MemoryAccessAnalyzer::run(llvm::Function& F, AnalysisContext& ctx) {
  llvm::DominatorTree DT(F);
  llvm::LoopInfo LI(DT);
  std::string fnName = F.getName().str();

  unsigned preorderIndex = 0;
  for (llvm::Loop* L : LI.getLoopsInPreorder()) {
    LoopContext lctx = buildLoopContext(L, fnName, preorderIndex++);

    unsigned loadCount = 0, storeCount = 0;
    AccessPattern pattern = AccessPattern::ContiguousLike;
    std::string baseName;
    unsigned loadsFromSameBase = 0;
    analyzeLoopMemory(L, loadCount, storeCount, pattern, baseName, loadsFromSameBase);

    unsigned memOps = loadCount + storeCount;
    if (memOps == 0)
      continue;

    std::string innermostPrefix = lctx.innermost ? "Innermost loop: " : "";
    std::string baseStr = baseName.empty() ? "" : " from base %" + baseName;

    if (pattern == AccessPattern::Irregular) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::Memory;
      d.functionName = fnName;
      d.loopOrRegionContext = formatLoopContext(lctx);
      d.message = "Irregular memory access in loop.";
      d.evidence = innermostPrefix + "Load/store pointer is not a GEP (raw pointer or complex expression).";
      d.suggestions.push_back("Consider contiguous buffer layout or index simplification.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    } else if (pattern == AccessPattern::Strided) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::Memory;
      d.functionName = fnName;
      d.loopOrRegionContext = formatLoopContext(lctx);
      d.message = "Strided memory access in loop; may hurt locality.";
      d.evidence = innermostPrefix + "GEP indexed by induction variable with non-unit progression" + baseStr + ". " +
                   std::to_string(loadCount) + " loads, " + std::to_string(storeCount) + " stores.";
      if (loadsFromSameBase > 1)
        d.evidence += " " + std::to_string(loadsFromSameBase) + " loads from same base pointer with loop-variant offsets.";
      d.suggestions.push_back("Consider loop tiling to improve reuse.");
      d.suggestions.push_back("Review data layout (e.g. row-major vs column-major).");
      d.confidence = 0.6f;
      ctx.getEmitter().add(d);
    } else if (loadsFromSameBase > 1) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Note;
      d.category = DiagnosticCategory::Memory;
      d.functionName = fnName;
      d.loopOrRegionContext = formatLoopContext(lctx);
      d.message = "Multiple loads from same base in loop; consider reuse or hoisting.";
      d.evidence = innermostPrefix + std::to_string(loadsFromSameBase) + " loads from same base pointer with loop-variant offsets.";
      d.suggestions.push_back("Consider reusing loaded value or hoisting invariant loads.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    }

    if (memOps >= 4) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Note;
      d.category = DiagnosticCategory::Memory;
      d.functionName = fnName;
      d.loopOrRegionContext = formatLoopContext(lctx);
      d.message = "Loop has high memory op density; may be memory-bound.";
      d.evidence = innermostPrefix + "load/store density " + std::to_string(loadCount) + ":" + std::to_string(storeCount) +
                   " (" + std::to_string(memOps) + " memory ops in loop body).";
      d.suggestions.push_back("Consider loop tiling for better cache reuse.");
      d.suggestions.push_back("Check if invariant loads can be hoisted.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    }
  }
}

}  // namespace analyzer
