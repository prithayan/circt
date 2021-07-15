//===- WiringTransform.cpp - Print the instance graph --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//===----------------------------------------------------------------------===//
//
// Wires a Module's Source Target to one or more Sink Modules/Components.
//
// Sinks are wired to their closest source through their lowest common ancestor (LCA). Verbosely, this modifies the circuit in the following ways:
//
//    1. Adds a pin to each sink module
//    2. Punches ports up from source signals to the LCA
//    3. Punches ports down from LCAs to each sink module
//    4. Wires sources up to LCA, sinks down from LCA, and across each LCA 
//
//===----------------------------------------------------------------------===//

#include "PassDetails.h"
#include "circt/Dialect/FIRRTL/FIRRTLOps.h"
#include "circt/Dialect/FIRRTL/FIRRTLTypes.h"
#include "circt/Dialect/FIRRTL/FIRRTLVisitors.h"
#include "circt/Dialect/FIRRTL/Passes.h"
#include "circt/Dialect/FIRRTL/InstanceGraph.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "wiring-transform"

using namespace circt;
using namespace firrtl;

//===----------------------------------------------------------------------===//
// Static class names
//===----------------------------------------------------------------------===//

static constexpr const char *sourceAnnoClass =
    "firrtl.passes.wiring.SourceAnnotation";
static constexpr const char *sinkAnnoClass =
    "firrtl.passes.wiring.SinkAnnotation";
static constexpr const char *portNameStr = "portName";

//===----------------------------------------------------------------------===//
// Pass Infrastructure
//===----------------------------------------------------------------------===//

namespace {
struct WiringTransformPass : public WiringTransformBase<WiringTransformPass> {
  WiringTransformPass() {}
  void runOnOperation() override {
    auto circuitOp = getOperation();
    instanceGraph = &getAnalysis<InstanceGraph>();
    circuitOp.walk([&](Operation *op) { gatherAnnotations(op); });
    markAllAnalysesPreserved();
  }
  void gatherAnnotations(Operation *op);
  void transform();

private:
  using SinkOperations = SmallVector<Operation *, 8>;
  using SinkModuleArgs = DenseMap<Operation *, SmallVector<size_t, 8>>;
  DenseMap<StringRef, SinkModuleArgs> sinkArgs;
  DenseMap<StringRef, size_t> srcArg;
  DenseMap<StringRef, SinkOperations> sinkOpsMap;
  DenseMap<StringRef, Operation *> srcOpsMap;
  InstanceGraph *instanceGraph = nullptr;
};

void WiringTransformPass::transform() {
  for (auto srcIt : srcOpsMap) {
    auto portName = srcIt.getFirst();
    auto srcOp = srcIt.getSecond();
    if (!sinkOpsMap.count(portName)) {
      mlir::emitError(srcOp->getLoc(), "cannot find corresponding sink for the portname:'" + portName + "'");
      continue;
    }
    auto sinkList = sinkOpsMap.lookup(portName);

    LLVM_DEBUG(llvm::dbgs() << "\n src: "<< *srcOp);
    for (auto sink : sinkList) {
      llvm::dbgs() << " sink :"<< *sink;
      //instanceGraph->getLCA(instanceGraph->lookup(srcOp, sink);
    }

  }
}

void WiringTransformPass::gatherAnnotations(Operation *op) {

  if (auto module = dyn_cast<FModuleOp>(op)) {
    AnnotationSet::removePortAnnotations(
        module, [&](unsigned argNum, Annotation anno) {
          if (anno.isClass(sinkAnnoClass)) {
            LLVM_DEBUG(llvm::dbgs() << "\n Port Anno : " << anno.getDict());
            StringRef n = anno.getMember<StringAttr>(portNameStr).getValue();
            sinkOpsMap[n].push_back(op);
            sinkArgs[n][module].push_back(argNum);
            return true;
          } else if (anno.isClass(sourceAnnoClass)) {
            LLVM_DEBUG(llvm::dbgs() << "\n Port Anno : " << anno.getDict());
            StringRef n = anno.getMember<StringAttr>(portNameStr).getValue();
            srcArg[n] = argNum;
            auto it = srcOpsMap.insert({n, op});
            if (!it.second)
              mlir::emitError(op->getLoc(),
                              "ambiguous source for port:'" + n + "'");
            return true;
          }
          return false;
        });
  } else {
    AnnotationSet annos(op);

    if (annos.empty())
      return;

    // Go through all annotations on this op and extract the interesting ones.
    // Note that the way tap annotations are scattered to their targets, we
    // should never see multiple values or memories annotated with the exact
    // same annotation (hence the asserts).
    annos.removeAnnotations([&](Annotation anno) {
      if (anno.isClass(sinkAnnoClass)) {
        LLVM_DEBUG(llvm::dbgs() << "\n Op Anno : " << anno.getDict());
        StringRef n = anno.getMember<StringAttr>(portNameStr).getValue();
        sinkOpsMap[n].push_back(op);
        return true;
      } else if (anno.isClass(sourceAnnoClass)) {
        LLVM_DEBUG(llvm::dbgs() << "\n Op Anno : " << anno.getDict());
        StringRef n = anno.getMember<StringAttr>(portNameStr).getValue();
        auto it = srcOpsMap.insert({n, op});
        if (!it.second)
          mlir::emitError(op->getLoc(),
                          "ambiguous source for port:'" + n + "'");
        return true;
      }
      return false;
    });
    annos.applyToOperation(op);
  }
}

} // end anonymous namespace

std::unique_ptr<mlir::Pass> circt::firrtl::createWiringTransformPass() {
  return std::make_unique<WiringTransformPass>();
}
