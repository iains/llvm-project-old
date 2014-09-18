//===-- MSP430MCAsmBackend.cpp - MSP430 assembler backend ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/MSP430MCTargetDesc.h"
#include "MCTargetDesc/MSP430FixupKinds.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixupKindInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCObjectWriter.h"

using namespace llvm;

namespace {
class MSP430MCAsmBackend : public MCAsmBackend {
  uint8_t OSABI;
public:
  MSP430MCAsmBackend(uint8_t osABI)
    : OSABI(osABI) {}

  unsigned getNumFixupKinds() const override {
      return MSP430::NumTargetFixupKinds;
  }

  const MCFixupKindInfo &getFixupKindInfo(MCFixupKind Kind) const override;

  void applyFixup(const MCFixup &Fixup, char *Data, unsigned DataSize,
                  uint64_t Value, bool IsPCRel) const override;

  bool mayNeedRelaxation(const MCInst &Inst) const override {
    return false;
  }

  bool fixupNeedsRelaxation(const MCFixup &Fixup, uint64_t Value,
                            const MCRelaxableFragment *Fragment,
                            const MCAsmLayout &Layout) const override {
    return false;
  }

  void relaxInstruction(const MCInst &Inst, MCInst &Res) const override {
    llvm_unreachable("MSP430 does do not have assembler relaxation");
  }

  bool writeNopData(uint64_t Count, MCObjectWriter *OW) const override;
 
  MCObjectWriter *createObjectWriter(raw_pwrite_stream &OS) const override {
    return createMSP430ObjectWriter(OS, OSABI);
  }
};
} // end anonymous namespace

const MCFixupKindInfo &
MSP430MCAsmBackend::getFixupKindInfo(MCFixupKind Kind) const {

  const static MCFixupKindInfo FuInfo[MSP430::NumTargetFixupKinds] = {
      // This table *must* be in the order that the FIXUPS are defined
      // in MSP430FixupKinds.h.
      //
      // Name                      Offset (bits) Size (bits)     Flags
      {"FK_MSP430_32", 0, 32, 0},
      {"FK_MSP430_10_PCREL", 0, 10, MCFixupKindInfo::FKF_IsPCRel},
      {"FK_MSP430_16_BYTE", 0, 8, 0},
      {"FK_MSP430_2X_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel},
      {"FK_MSP430_RL_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel},
      {"FK_MSP430_SYM_DIFF", 0, 16, MCFixupKindInfo::FKF_IsPCRel}
  };

  if (Kind < FirstTargetFixupKind)
    return MCAsmBackend::getFixupKindInfo(Kind);

  assert(unsigned(Kind - FirstTargetFixupKind) < getNumFixupKinds() &&
         "Invalid kind!");
  return FuInfo[Kind - FirstTargetFixupKind];
}

/// getFixupKindNumBytes - The number of bytes the fixup may change.
static unsigned getFixupKindNumBytes(unsigned Kind) {
  switch (Kind) {
  default:
    llvm_unreachable("Unknown fixup kind!");

  case FK_Data_1:
  case MSP430::FK_MSP430_16_BYTE:
    return 1;

  case FK_Data_2:
  case MSP430::FK_MSP430_SYM_DIFF:
  case MSP430::FK_MSP430_10_PCREL:
  case MSP430::FK_MSP430_2X_PCREL:
  case MSP430::FK_MSP430_RL_PCREL:
    return 2;

  case FK_Data_4:
  case MSP430::FK_MSP430_32:
    return 4;

  case FK_SecRel_2:
    return 2;
  case FK_SecRel_4:
    return 4;
  }
}

static unsigned adjustFixupValue(const MCFixup &Fixup, uint64_t Value,
                                 bool IsPCRel, MCContext *Ctx) {
  unsigned Kind = Fixup.getKind();
  switch (Kind) {
  default:
    llvm_unreachable("Unknown fixup kind!");
  case FK_Data_1:
  case FK_Data_2:
  case FK_Data_4:
  case MSP430::FK_MSP430_16_BYTE:
  case MSP430::FK_MSP430_SYM_DIFF:
  case MSP430::FK_MSP430_2X_PCREL:
  case MSP430::FK_MSP430_RL_PCREL:
    return Value;
  case FK_SecRel_2:
    return Value;
  case FK_SecRel_4:
    return Value;

  case MSP430::FK_MSP430_10_PCREL: {
    int64_t sval = (int64_t)(Value - 2); // We point to the next insn.

    sval >>= 1;
    if (Ctx && (Value >= 511 || sval < -512))
      Ctx->reportFatalError(Fixup.getLoc(), "out of range pc-relative fixup value");
    
    return (unsigned) (sval & 0x3f);
  }
  }
}

void MSP430MCAsmBackend::applyFixup(const MCFixup &Fixup, char *Data,
                                     unsigned DataSize, uint64_t Value,
                                     bool IsPCRel) const {

  unsigned NumBytes = getFixupKindNumBytes(Fixup.getKind());

  Value = adjustFixupValue(Fixup, Value, IsPCRel, nullptr);
  if (!Value)
    return; // Doesn't change encoding.

  unsigned Offset = Fixup.getOffset();
  assert(Offset + NumBytes <= DataSize && "Invalid fixup offset!");

  // For each byte of the fragment that the fixup touches, mask in the bits from
  // the fixup value. The Value has been "split up" into the appropriate
  // bitfields above.
  for (unsigned i = 0; i != NumBytes; ++i) {
    Data[Offset + i] |= uint8_t((Value >> (i * 8)) & 0xff);
  }
}

bool MSP430MCAsmBackend::writeNopData(uint64_t Count,
                                       MCObjectWriter *OW) const {
  if (Count & 1)
    return false;  // We can't write an odd number of bytes

  Count >>= 1;
  for (uint64_t I = 0; I != Count; ++I)
    OW->write16(0x4303);  // mov r3,r3
  return true;
}

MCAsmBackend *llvm::createMSP430MCAsmBackend(const Target &T,
                                             const MCRegisterInfo &MRI,
                                             const Triple &TT, StringRef CPU) {
  uint8_t OSABI = MCELFObjectTargetWriter::getOSABI(TT.getOS());
  // We decide that "none" means no OS .. whereas the current default on llvm
  // assumes that "none" means System V (hum).
  if (OSABI == ELF::ELFOSABI_NONE)
    OSABI = ELF::ELFOSABI_STANDALONE;
  return new MSP430MCAsmBackend(OSABI);
}
