#ifndef ANALYZER_IR_NAMES_H
#define ANALYZER_IR_NAMES_H

#include <string>

namespace llvm {
class DebugLoc;
class Instruction;
class Loop;
class SCEV;
class Value;
}  // namespace llvm

namespace analyzer {

/// Source-ish name for a value: its IR name ("A", "n"), "argN" for an unnamed
/// argument, or "<expr>" otherwise. Fixtures are compiled with
/// -fno-discard-value-names so parameter names survive.
std::string valueName(const llvm::Value* V);

/// Name of the object a pointer points into ("B" for &B[k*n+j]).
std::string pointerBaseName(const llvm::Value* ptr);

/// "file.c:8:7", or "" when the IR has no debug info.
std::string formatDebugLoc(const llvm::DebugLoc& DL);

/// "file.c:9" for an instruction, or "" when it has no debug location.
std::string sourceLine(const llvm::Instruction* I);

/// Where a loop starts in the source: the first location in its loop ID
/// (what LLVM's own remarks use), else its latch or header branch. Copies of
/// a loop made by the vectorizer or unroller share it.
llvm::DebugLoc loopStartLoc(const llvm::Loop* L);

/// The chain of call sites a location was inlined through, innermost first:
/// "f.c:10:3 <- f.c:20:5". Empty when the location isn't inlined.
std::string inlinedAtChain(const llvm::DebugLoc& DL);

/// Readable rendering of a SCEV expression with casts stripped, e.g.
/// "n - 1" instead of "(-1 + (zext i32 %n to i64))<nsw>".
std::string prettySCEV(const llvm::SCEV* S);

}  // namespace analyzer

#endif
