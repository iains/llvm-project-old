//===-- MSP430TargetStreamer.h - MSP430 Target Streamer --------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_MSP430_MSP430TARGETSTREAMER_H
#define LLVM_LIB_TARGET_MSP430_MSP430TARGETSTREAMER_H

#include "llvm/MC/MCELFStreamer.h"
#include "llvm/MC/MCStreamer.h"

namespace llvm {
class MSP430TargetStreamer : public MCTargetStreamer {
  virtual void anchor();

public:
  MSP430TargetStreamer(MCStreamer &S);
};

// This part is for ascii assembly output
class MSP430TargetAsmStreamer : public MSP430TargetStreamer {
  formatted_raw_ostream &OS;

public:
  MSP430TargetAsmStreamer(MCStreamer &S, formatted_raw_ostream &OS);
};

// This part is for ELF object output
class MSP430TargetELFStreamer : public MSP430TargetStreamer {
public:
  MSP430TargetELFStreamer(MCStreamer &S);
  MCELFStreamer &getStreamer();
};
} // end namespace llvm

#endif
