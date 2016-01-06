//===-- MSP430MCTargetDesc.h - MSP430 Target Descriptions -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides MSP430 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_MSP430_MCTARGETDESC_MSP430MCTARGETDESC_H
#define LLVM_LIB_TARGET_MSP430_MCTARGETDESC_MSP430MCTARGETDESC_H

#include "llvm/Support/DataTypes.h"

namespace llvm {

class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class StringRef;
class Target;
class Triple;
class raw_pwrite_stream;
class raw_ostream;

extern Target TheMSP430Target;

MCCodeEmitter *createMSP430MCCodeEmitter(const MCInstrInfo &MCII,
                                          const MCRegisterInfo &MRI,
                                          MCContext &Ctx);

MCAsmBackend *createMSP430MCAsmBackend(const Target &T,
                                       const MCRegisterInfo &MRI,
                                       const Triple &TT, StringRef CPU);

MCObjectWriter *createMSP430ObjectWriter(raw_pwrite_stream &OS, uint8_t OSABI);

} // End llvm namespace

// Defines symbolic names for MSP430 registers.
// This defines a mapping from register name to register number.
#define GET_REGINFO_ENUM
#include "MSP430GenRegisterInfo.inc"

// Defines symbolic names for the MSP430 instructions.
#define GET_INSTRINFO_ENUM
#include "MSP430GenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "MSP430GenSubtargetInfo.inc"

#endif
