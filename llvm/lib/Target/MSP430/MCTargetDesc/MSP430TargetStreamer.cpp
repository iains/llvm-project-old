//===-- MSP430TargetStreamer.cpp - MSP430 Target Streamer Methods ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides MSP430 specific target streamer methods if/when required.
//
//===----------------------------------------------------------------------===//

#include "MSP430TargetStreamer.h"
#include "InstPrinter/MSP430InstPrinter.h"
#include "llvm/Support/FormattedStream.h"

using namespace llvm;

// pin vtable to this file
MSP430TargetStreamer::MSP430TargetStreamer(MCStreamer &S) : MCTargetStreamer(S) {}

void MSP430TargetStreamer::anchor() {}

MSP430TargetAsmStreamer::MSP430TargetAsmStreamer(MCStreamer &S,
                                               formatted_raw_ostream &OS)
    : MSP430TargetStreamer(S), OS(OS) {}

MSP430TargetELFStreamer::MSP430TargetELFStreamer(MCStreamer &S)
    : MSP430TargetStreamer(S) {}

MCELFStreamer &MSP430TargetELFStreamer::getStreamer() {
  return static_cast<MCELFStreamer &>(Streamer);
}
