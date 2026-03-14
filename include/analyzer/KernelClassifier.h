#ifndef ANALYZER_KERNEL_CLASSIFIER_H
#define ANALYZER_KERNEL_CLASSIFIER_H

namespace llvm {
class Function;
}

namespace analyzer {

/// Heuristics to identify likely performance-sensitive kernel candidates.
class KernelClassifier {
public:
  /// Returns true if the function should be analyzed as a kernel candidate.
  bool isKernelLike(llvm::Function& F) const;
};

}  // namespace analyzer

#endif
