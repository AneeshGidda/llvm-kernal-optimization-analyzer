#include "analyzer/LoopContext.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/BasicBlock.h>

#include <sstream>

namespace analyzer {

LoopContext buildLoopContext(llvm::Loop* L, const std::string& functionName,
                             unsigned preorderIndex) {
  LoopContext ctx;
  ctx.depth = L->getLoopDepth();
  ctx.innermost = L->getSubLoops().empty();
  ctx.tripCount = TripCountStatus::Unknown;

  llvm::StringRef nameRef = L->getHeader()->getName();
  if (nameRef.empty()) {
    ctx.headerBlockName = "unnamed." + std::to_string(preorderIndex);
  } else {
    ctx.headerBlockName = nameRef.str();
  }

  ctx.stableId = "loop_" + functionName + "_" + std::to_string(ctx.depth) + "_" +
                 ctx.headerBlockName + "_" + std::to_string(preorderIndex);

  return ctx;
}

std::string formatLoopContext(const LoopContext& ctx) {
  std::ostringstream out;
  out << "loop header %" << ctx.headerBlockName << ", depth=" << ctx.depth
      << ", innermost=" << (ctx.innermost ? "true" : "false");
  if (ctx.tripCount == TripCountStatus::Unknown) {
    out << ", trip count unknown";
  } else {
    out << ", trip count constant";
  }
  return out.str();
}

}  // namespace analyzer
