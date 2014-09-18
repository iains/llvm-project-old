//===-- MSP430MCFixups.h - MSP430-specific fixup entries ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_MSP430_MCTARGETDESC_MSP430FIXUPKINDS_H
#define LLVM_LIB_TARGET_MSP430_MCTARGETDESC_MSP430FIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace MSP430 {
enum FixupKind {
  // These correspond directly to R_MSP430_* relocations.

  FK_MSP430_32 = FirstTargetFixupKind,
  FK_MSP430_10_PCREL,
//  FK_MSP430_16,
//  FK_MSP430_16_PCREL,
  FK_MSP430_16_BYTE,
//  FK_MSP430_16_PCREL_BYTE,
  FK_MSP430_2X_PCREL,
  FK_MSP430_RL_PCREL,
//  FK_MSP430_8,
  FK_MSP430_SYM_DIFF,

  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
} // end namespace MSP430
} // end namespace llvm

#endif
