//===-- MSP430ELFObjectWriter.cpp - MSP430 ELF Writer ---------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/MSP430MCTargetDesc.h"
#include "MCTargetDesc/MSP430FixupKinds.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCValue.h"
//#include "llvm/Support/ELF.h"
//#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {
  class MSP430ObjectWriter : public MCELFObjectTargetWriter {
  public:
    MSP430ObjectWriter(uint8_t OSABI);

    virtual ~MSP430ObjectWriter();
  protected:
    unsigned GetRelocType(const MCValue &Target, const MCFixup &Fixup,
                          bool IsPCRel) const override;
  };
} // end anonymous namespace.

MSP430ObjectWriter::MSP430ObjectWriter(uint8_t OSABI)
  : MCELFObjectTargetWriter(/*IsELF64*/ false, OSABI, ELF::EM_MSP430,
                              /*HasRelocationAddend*/ true) {}

MSP430ObjectWriter::~MSP430ObjectWriter() {}

// Return the relocation type for an absolute value of MCFixupKind Kind.
static unsigned getAbsoluteReloc(unsigned Kind) {
  switch (Kind) {
  case FK_Data_1:                  return ELF::R_MSP430_8;
  case FK_Data_2:                  return ELF::R_MSP430_16;
  case FK_Data_4:                  return ELF::R_MSP430_32; // Not sure how this would be used.
  case MSP430::FK_MSP430_32:       return ELF::R_MSP430_32; // Ditto.
  case MSP430::FK_MSP430_16_BYTE:  return ELF::R_MSP430_16_BYTE;
  }
  dbgs() << format("unhandled absolute fixup kind : %u  (first msp430 = %u)\n", Kind, MSP430::FK_MSP430_32);
  return ELF::R_MSP430_16_BYTE;
  //llvm_unreachable("Unsupported absolute address");
}

// Return the relocation type for a PC-relative value of MCFixupKind Kind.
static unsigned getPCRelReloc(unsigned Kind) {
  switch (Kind) {
  case FK_Data_1:                  return ELF::R_MSP430_16_PCREL_BYTE;
  case FK_Data_2:                  return ELF::R_MSP430_16_PCREL;
  case MSP430::FK_MSP430_10_PCREL: return ELF::R_MSP430_10_PCREL;
  case MSP430::FK_MSP430_2X_PCREL: return ELF::R_MSP430_2X_PCREL;
  case MSP430::FK_MSP430_RL_PCREL: return ELF::R_MSP430_RL_PCREL;
  case MSP430::FK_MSP430_SYM_DIFF: return ELF::R_MSP430_SYM_DIFF;
  }
  dbgs() << format("unhandled PC-relative fixup kind : %u \n", Kind);
  return ELF::R_MSP430_16_PCREL;
  //llvm_unreachable("Unsupported PC-relative address");
}

unsigned MSP430ObjectWriter::GetRelocType(const MCValue &Target,
                                           const MCFixup &Fixup,
                                           bool IsPCRel) const {

  MCSymbolRefExpr::VariantKind Modifier = Target.getAccessVariant();
  unsigned Kind = Fixup.getKind();
  switch (Modifier) {
  case MCSymbolRefExpr::VK_None:
    if (IsPCRel)
      return getPCRelReloc(Kind);
    return getAbsoluteReloc(Kind);

  default:
    llvm_unreachable("Modifier not supported");
  }
}

MCObjectWriter *llvm::createMSP430ObjectWriter(raw_pwrite_stream &OS,
                                               uint8_t OSABI) {
  MCELFObjectTargetWriter *MOTW =
    new MSP430ObjectWriter(OSABI);
  return createELFObjectWriter(MOTW, OS, /*IsLittleEndian=*/true);
}
