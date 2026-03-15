#ifndef ANALYZER_LOOP_CONTEXT_H
#define ANALYZER_LOOP_CONTEXT_H

#include <string>

namespace llvm {
class Loop;
}

namespace analyzer {

/// Trip count status when inferable.
enum class TripCountStatus { Unknown, Constant };

/// Stable loop descriptor for consistent diagnostic context.
struct LoopContext {
  std::string stableId;
  std::string headerBlockName;  // With % prefix for display when non-empty
  unsigned depth = 0;
  bool innermost = false;
  TripCountStatus tripCount = TripCountStatus::Unknown;
};

/// Build LoopContext from LLVM loop, function name, and preorder index.
LoopContext buildLoopContext(llvm::Loop* L, const std::string& functionName,
                             unsigned preorderIndex);

/// Format for Diagnostic::loopOrRegionContext, e.g.
/// "loop header %for.body, depth=1, innermost=true, trip count unknown"
std::string formatLoopContext(const LoopContext& ctx);

}  // namespace analyzer

#endif
