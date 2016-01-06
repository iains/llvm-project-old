//===-- MSP430InstPrinter.cpp - Convert MSP430 MCInst to assembly syntax --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an MSP430 MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#include "MSP430InstPrinter.h"
#include "MSP430.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"


// Include the auto-generated portion of the assembly writer.
#include "MSP430GenAsmWriter.inc"

void MSP430InstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                  StringRef Annot, const MCSubtargetInfo &STI) {
  printInstruction(MI, O);
  printAnnotation(O, Annot);
}

void MSP430InstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const {
//    const char *RegName = getRegisterName(Op.getReg());
  OS << getRegisterName(RegNo);
}

void MSP430InstPrinter::printRegIndirect(const MCInst *MI, unsigned OpNo,
                                         raw_ostream &O)
{
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    O << "@" << getRegisterName(Op.getReg()) << "+";
  } else {
Op.dump();
    llvm_unreachable("printRegIndirect: unknown op");
  }
}

void MSP430InstPrinter::printRegInd(const MCInst *MI, unsigned OpNo,
                                         raw_ostream &O)
{
  const MCOperand &Mr = MI->getOperand(OpNo);
  const MCOperand &Mi = MI->getOperand(OpNo+1);
  if (Mr.isReg() && Mi.isImm()) {
    unsigned v = Mi.getImm();
    if (v == 2 || v == 3) {
      O << "@" << getRegisterName(Mr.getReg()) << (v==3?"+":"");
    }
  } else {
Mi.dump();
Mr.dump();
    llvm_unreachable("printRegInd: unknown op");
  }
}

void MSP430InstPrinter::printPCRelImmOperand(const MCInst *MI, unsigned OpNo,
                                             raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm())
    O << Op.getImm();
  else {
    assert(Op.isExpr() && "unknown pcrel immediate operand");
    Op.getExpr()->print(O, &MAI);
  }
}

void MSP430InstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                     raw_ostream &O, const char *Modifier) {
  assert((Modifier == nullptr || Modifier[0] == 0) && "No modifiers supported");
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    O << getRegisterName(Op.getReg());
  } else if (Op.isImm()) {
    O << '#' << Op.getImm();
  } else {
    assert(Op.isExpr() && "unknown operand kind in printOperand");
    O << '#';
    Op.getExpr()->print(O, &MAI);
  }
}

void MSP430InstPrinter::printSrcMemOperand(const MCInst *MI, unsigned OpNo,
                                           raw_ostream &O,
                                           const char *Modifier) {
  const MCOperand &Base = MI->getOperand(OpNo);
  const MCOperand &Disp = MI->getOperand(OpNo+1);

  // Print displacement first

  // If the global address expression is a part of displacement field with a
  // register base, we should not emit any prefix symbol here, e.g.
  //   mov.w &foo, r1
  // vs
  //   mov.w glb(r1), r2
  // Otherwise (!) msp430-as will silently miscompile the output :(
  if (!Base.getReg())
    O << '&';

  if (Disp.isExpr())
    Disp.getExpr()->print(O, &MAI);
  else {
    assert(Disp.isImm() && "Expected immediate in displacement field");
    O << Disp.getImm();
  }

  // Print register base field
  if (Base.getReg())
    O << '(' << getRegisterName(Base.getReg()) << ')';
}

void MSP430InstPrinter::printCCOperand(const MCInst *MI, unsigned OpNo,
                                       raw_ostream &O) {
  unsigned CC = MI->getOperand(OpNo).getImm();

  switch (CC) {
  default:
   llvm_unreachable("Unsupported CC code");
  case MSP430CC::COND_EQ:
   O << "eq";
   break;
  case MSP430CC::COND_NE:
   O << "ne";
   break;
  case MSP430CC::COND_HS:
   O << "hs";
   break;
  case MSP430CC::COND_LO:
   O << "lo";
   break;
  case MSP430CC::COND_GE:
   O << "ge";
   break;
  case MSP430CC::COND_LT:
   O << 'l';
   break;
  case MSP430CC::COND_LZ:
   O << 'n';
   break;
  case MSP430CC::COND_A: // Unconditional.
   O << "mp";
   break;
  }
}
