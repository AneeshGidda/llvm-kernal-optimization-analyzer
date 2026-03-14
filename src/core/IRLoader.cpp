#include "analyzer/IRLoader.h"

#include <llvm/IR/LLVMContext.h>
#include <llvm/IRReader/IRReader.h>
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/Support/raw_ostream.h>

namespace analyzer {

namespace {

llvm::LLVMContext& getGlobalContext() {
  static llvm::LLVMContext Ctx;
  return Ctx;
}

}  // namespace

std::unique_ptr<llvm::Module> IRLoader::loadFromFile(const std::string& path) {
  lastError_.clear();

  if (path.empty()) {
    lastError_ = "Input path is empty.";
    return nullptr;
  }

  if (!llvm::sys::fs::exists(path)) {
    lastError_ = "File not found: " + path;
    return nullptr;
  }

  llvm::SMDiagnostic err;
  llvm::LLVMContext& ctx = getGlobalContext();
  std::unique_ptr<llvm::Module> mod = llvm::parseIRFile(path, err, ctx);
  if (!mod) {
    std::string msg;
    llvm::raw_string_ostream os(msg);
    err.print("analyzer", os);
    lastError_ = msg;
    return nullptr;
  }
  return mod;
}

}  // namespace analyzer
