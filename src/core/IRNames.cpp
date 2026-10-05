#include "analyzer/IRNames.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/Analysis/ScalarEvolution.h>
#include <llvm/Analysis/ScalarEvolutionExpressions.h>
#include <llvm/Analysis/ValueTracking.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/Instruction.h>
#include <llvm/IR/Instructions.h>

#include <string>
#include <vector>

namespace analyzer {

std::string valueName(const llvm::Value* V) {
  if (!V)
    return "<null>";
  if (V->hasName())
    return V->getName().str();
  if (const auto* A = llvm::dyn_cast<llvm::Argument>(V))
    return "arg" + std::to_string(A->getArgNo() + 1);
  return "<expr>";
}

std::string pointerBaseName(const llvm::Value* ptr) {
  return valueName(llvm::getUnderlyingObject(ptr));
}

std::string formatDebugLoc(const llvm::DebugLoc& DL) {
  // Line 0 means "no particular source line" (merged code).
  if (!DL || DL.getLine() == 0)
    return "";
  std::string out =
      DL->getFilename().str() + ":" + std::to_string(DL.getLine());
  if (DL.getCol())
    out += ":" + std::to_string(DL.getCol());
  return out;
}

std::string sourceLine(const llvm::Instruction* I) {
  if (!I)
    return "";
  const llvm::DebugLoc& DL = I->getDebugLoc();
  if (!DL || DL.getLine() == 0)
    return "";
  return DL->getFilename().str() + ":" + std::to_string(DL.getLine());
}

llvm::DebugLoc loopStartLoc(const llvm::Loop* L) {
  if (llvm::MDNode* LoopID = L->getLoopID())
    for (unsigned i = 1, e = LoopID->getNumOperands(); i < e; ++i)
      if (auto* Loc = llvm::dyn_cast<llvm::DILocation>(LoopID->getOperand(i)))
        return llvm::DebugLoc(Loc);
  // Remainder loops made by the unroller get a loop ID without locations.
  // Their backedge branch keeps the `for` statement's location, as in the
  // main copy.
  if (const llvm::BasicBlock* latch = L->getLoopLatch())
    if (const llvm::DebugLoc& DL = latch->getTerminator()->getDebugLoc())
      return DL;
  return L->getHeader()->getTerminator()->getDebugLoc();
}

std::string inlinedAtChain(const llvm::DebugLoc& DL) {
  std::string out;
  if (!DL)
    return out;
  for (const llvm::DILocation* at = DL->getInlinedAt(); at;
       at = at->getInlinedAt()) {
    out += (out.empty() ? "" : " <- ") + at->getFilename().str() + ":" +
           std::to_string(at->getLine());
    if (at->getColumn())
      out += ":" + std::to_string(at->getColumn());
  }
  return out;
}

namespace {

bool isConstant(const llvm::SCEV* S, int64_t* value) {
  if (const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(S)) {
    *value = C->getAPInt().getSExtValue();
    return true;
  }
  return false;
}

std::string render(const llvm::SCEV* S, bool parenthesizeSums);

std::string renderAdd(const llvm::SCEVAddExpr* A) {
  // SCEV keeps constants first ("-1 + n"); print them last ("n - 1").
  std::string out;
  int64_t constant = 0;
  bool hasConstant = false;
  for (const llvm::SCEV* Op : A->operands()) {
    int64_t c;
    if (isConstant(Op, &c)) {
      constant += c;
      hasConstant = true;
      continue;
    }
    // Render "-1 * x" as "- x".
    const auto* M = llvm::dyn_cast<llvm::SCEVMulExpr>(Op);
    if (M && M->getNumOperands() == 2 && isConstant(M->getOperand(0), &c) &&
        c == -1) {
      out += (out.empty() ? "-" : " - ") + render(M->getOperand(1), true);
      continue;
    }
    out += (out.empty() ? "" : " + ") + render(Op, false);
  }
  if (hasConstant && constant != 0) {
    if (out.empty())
      return std::to_string(constant);
    out += constant < 0 ? " - " + std::to_string(-constant)
                        : " + " + std::to_string(constant);
  }
  return out.empty() ? "0" : out;
}

std::string render(const llvm::SCEV* S, bool parenthesizeSums) {
  using namespace llvm;
  switch (S->getSCEVType()) {
    case scConstant:
      return std::to_string(cast<SCEVConstant>(S)->getAPInt().getSExtValue());
    case scTruncate: {
      // A narrow truncation is a remainder ("n mod 4" for an unroll
      // remainder's count); wide ones just undo a sign extension.
      const auto* T = cast<SCEVTruncateExpr>(S);
      unsigned bits = T->getType()->getScalarSizeInBits();
      std::string inner = render(T->getOperand(), true);
      if (bits && bits <= 16)
        return "(" + inner + " mod " + std::to_string(1u << bits) + ")";
      return inner;
    }
    case scZeroExtend:
    case scSignExtend:
    case scPtrToInt:
      return render(cast<SCEVCastExpr>(S)->getOperand(), parenthesizeSums);
    case scAddExpr: {
      std::string s = renderAdd(cast<SCEVAddExpr>(S));
      return parenthesizeSums ? "(" + s + ")" : s;
    }
    case scMulExpr: {
      const auto* M = cast<SCEVMulExpr>(S);
      std::string out;
      for (const SCEV* Op : M->operands())
        out += (out.empty() ? "" : " * ") + render(Op, true);
      return out;
    }
    case scUDivExpr: {
      const auto* D = cast<SCEVUDivExpr>(S);
      return "(" + render(D->getLHS(), true) + " / " +
             render(D->getRHS(), true) + ")";
    }
    case scSMaxExpr:
    case scUMaxExpr:
    case scSMinExpr:
    case scUMinExpr:
    case scSequentialUMinExpr: {
      const auto* N = cast<SCEVNAryExpr>(S);
      bool isMax =
          S->getSCEVType() == scSMaxExpr || S->getSCEVType() == scUMaxExpr;
      std::string out = isMax ? "max(" : "min(";
      bool first = true;
      for (const SCEV* Op : N->operands()) {
        out += (first ? "" : ", ") + render(Op, false);
        first = false;
      }
      return out + ")";
    }
    case scAddRecExpr: {
      const auto* AR = cast<SCEVAddRecExpr>(S);
      std::string out = "{" + render(AR->getStart(), false);
      for (unsigned i = 1; i < AR->getNumOperands(); ++i)
        out += ", +, " + render(AR->getOperand(i), false);
      return out + "}";
    }
    case scUnknown:
      return valueName(cast<SCEVUnknown>(S)->getValue());
    case scCouldNotCompute:
      return "<unknown>";
  }
  return "<unknown>";
}

}  // namespace

std::string prettySCEV(const llvm::SCEV* S) {
  return S ? render(S, false) : "<unknown>";
}

}  // namespace analyzer
