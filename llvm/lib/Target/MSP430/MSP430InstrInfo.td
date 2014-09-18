//===-- MSP430InstrInfo.td - MSP430 Instruction defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the MSP430 instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "MSP430Opcodes.td"
include "MSP430InstrFormats.td"

//===----------------------------------------------------------------------===//
// Type Constraints.
//===----------------------------------------------------------------------===//
class SDTCisI8<int OpNum> : SDTCisVT<OpNum, i8>;
class SDTCisI16<int OpNum> : SDTCisVT<OpNum, i16>;

//===---------------------------------------------------------------------===//
// Type Profiles.
//===---------------------------------------------------------------------===//
def SDT_MSP430Call         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_MSP430CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>]>;
def SDT_MSP430CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;
def SDT_MSP430Wrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                  SDTCisPtrTy<0>]>;
def SDT_MSP430Cmp          : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def SDT_MSP430BrCC         : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                                  SDTCisVT<1, i8>]>;
def SDT_MSP430SelectCC     : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>, 
                                                  SDTCisVT<3, i8>]>;
def SDT_MSP430Shift        : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>,
                                                  SDTCisI8<2>]>;

//===---------------------------------------------------------------------===//
// MSP430 Specific Node Definitions.
//===---------------------------------------------------------------------===//
def MSP430retflag  : SDNode<"MSP430ISD::RET_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;
def MSP430retiflag : SDNode<"MSP430ISD::RETI_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def MSP430rra     : SDNode<"MSP430ISD::RRA", SDTIntUnaryOp, []>;
def MSP430rla     : SDNode<"MSP430ISD::RLA", SDTIntUnaryOp, []>;
def MSP430rrc     : SDNode<"MSP430ISD::RRC", SDTIntUnaryOp, []>;

def MSP430call    : SDNode<"MSP430ISD::CALL", SDT_MSP430Call,
                     [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;
def MSP430callseq_start :
                 SDNode<"ISD::CALLSEQ_START", SDT_MSP430CallSeqStart,
                        [SDNPHasChain, SDNPOutGlue]>;
def MSP430callseq_end :
                 SDNode<"ISD::CALLSEQ_END",   SDT_MSP430CallSeqEnd,
                        [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def MSP430Wrapper : SDNode<"MSP430ISD::Wrapper", SDT_MSP430Wrapper>;
def MSP430cmp     : SDNode<"MSP430ISD::CMP", SDT_MSP430Cmp, [SDNPOutGlue]>;
def MSP430brcc    : SDNode<"MSP430ISD::BR_CC", SDT_MSP430BrCC,
                            [SDNPHasChain, SDNPInGlue]>;
def MSP430selectcc: SDNode<"MSP430ISD::SELECT_CC", SDT_MSP430SelectCC,
                            [SDNPInGlue]>;
def MSP430shl     : SDNode<"MSP430ISD::SHL", SDT_MSP430Shift, []>;
def MSP430sra     : SDNode<"MSP430ISD::SRA", SDT_MSP430Shift, []>;
def MSP430srl     : SDNode<"MSP430ISD::SRL", SDT_MSP430Shift, []>;

//===---------------------------------------------------------------------===//
// MSP430 Operand Definitions.
//===---------------------------------------------------------------------===//

// Address operands
def memsrc : Operand<iPTR>,
             ComplexPattern<iPTR, 2, "SelectRegInd", [], [SDNPWantParent]> {
  let PrintMethod = "printSrcMemOperand";
  let EncoderMethod = "getMemOpEncoding";
  let MIOperandInfo = (ops GR16, i16imm);
}

def memdst : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let EncoderMethod = "getMemOpEncoding";
  let MIOperandInfo = (ops GR16, i16imm);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelImmOperand";
  let EncoderMethod = "getPCRelImmOpEncoding";
  let OperandType = "OPERAND_PCREL";
}

// Operand for printing out a condition code.
def cc : Operand<i8> {
  let PrintMethod = "printCCOperand";
  let EncoderMethod = "getCCEncoding";
}

def regindirect : Operand<iPTR> {
  let PrintMethod = "printRegIndirect";
  let MIOperandInfo = (ops GR16);
}

// Match for @rN and @rN+
def regind : Operand<iPTR>, 
             ComplexPattern<iPTR, 2, "SelectRegInd", [], [SDNPWantParent]> 
{
  let PrintMethod = "printRegInd";
  let EncoderMethod = "getRegInd";
  let MIOperandInfo = (ops GR16:$reg, i16imm:$amode);
}

//===---------------------------------------------------------------------===//
// MSP430 Has two registers capable of sourcing some small constants
// efficiently.
//===---------------------------------------------------------------------===//

def r2r3imm8 : Operand<i8>, PatLeaf<(imm),
  [{
    return (N->getSExtValue() == 0 || N->getSExtValue() == 1 ||
            N->getSExtValue() == 2 || N->getSExtValue() == 4 ||
            N->getSExtValue() == 8 || N->getSExtValue() == -1);
  }]>
  {
  let EncoderMethod = "getR2R3ImmEncoding";
  let OperandType = "OPERAND_IMMEDIATE";
  let MIOperandInfo = (ops i8imm);

  //AsmOperandClass ParserMatchClass = ImmAsmOperand;
  }

def r2r3imm16 : Operand<i16>, PatLeaf<(imm),
  [{
    return (N->getSExtValue() == 0 || N->getSExtValue() == 1 ||
            N->getSExtValue() == 2 || N->getSExtValue() == 4 ||
            N->getSExtValue() == 8 || N->getSExtValue() == -1);
  }]>
 {
  let EncoderMethod = "getR2R3ImmEncoding";
  let OperandType = "OPERAND_IMMEDIATE";
  let MIOperandInfo = (ops i16imm);

  //AsmOperandClass ParserMatchClass = ImmAsmOperand;
  }

//===---------------------------------------------------------------------===//
// MSP430 Complex Pattern Definitions.
//===---------------------------------------------------------------------===//

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], []>;

//===---------------------------------------------------------------------===//
// Pattern Fragments
def zextloadi16i8 : PatFrag<(ops node:$ptr), (i16 (zextloadi8 node:$ptr))>;
def  extloadi16i8 : PatFrag<(ops node:$ptr), (i16 ( extloadi8 node:$ptr))>;
def and_su : PatFrag<(ops node:$lhs, node:$rhs), (and node:$lhs, node:$rhs), [{
  return N->hasOneUse();
}]>;
//===----------------------------------------------------------------------===//
// Instruction list..

// ADJCALLSTACKDOWN/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
// Pessimistically assume ADJCALLSTACKDOWN / ADJCALLSTACKUP will become
// sub / add which can clobber SR.
let Defs = [SP, SR], Uses = [SP] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt),
                              "#ADJCALLSTACKDOWN",
                              [(MSP430callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(MSP430callseq_end timm:$amt1, timm:$amt2)]>;
}

let usesCustomInserter = 1 in {
  def Select8  : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$src2, i8imm:$cc),
                        "# Select8 PSEUDO",
                        [(set GR8:$dst,
                          (MSP430selectcc GR8:$src, GR8:$src2, imm:$cc))]>;
  def Select16 : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$src2, i8imm:$cc),
                        "# Select16 PSEUDO",
                        [(set GR16:$dst,
                          (MSP430selectcc GR16:$src, GR16:$src2, imm:$cc))]>;
  let Defs = [SR] in {
  def Shl8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Shl8 PSEUDO",
                        [(set GR8:$dst, (MSP430shl GR8:$src, GR8:$cnt))]>;
  def Shl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR8:$cnt),
                        "# Shl16 PSEUDO",
                        [(set GR16:$dst, (MSP430shl GR16:$src, GR8:$cnt))]>;
  def Sra8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Sra8 PSEUDO",
                        [(set GR8:$dst, (MSP430sra GR8:$src, GR8:$cnt))]>;
  def Sra16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR8:$cnt),
                        "# Sra16 PSEUDO",
                        [(set GR16:$dst, (MSP430sra GR16:$src, GR8:$cnt))]>;
  def Srl8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Srl8 PSEUDO",
                        [(set GR8:$dst, (MSP430srl GR8:$src, GR8:$cnt))]>;
  def Srl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR8:$cnt),
                        "# Srl16 PSEUDO",
                        [(set GR16:$dst, (MSP430srl GR16:$src, GR8:$cnt))]>;
  }
}

let hasSideEffects = 0 in
def NOP : Pseudo<(outs), (ins), "nop", []>;

//===----------------------------------------------------------------------===//
//  Control Flow Instructions...
//

let isReturn = 1, isTerminator = 1, isBarrier = 1 in {
  let Uses = [SP] in
  def RET  : IForm16<0x4, DstReg, SrcPostInc, Size2Bytes,
                     (outs), (ins), "ret",  [(MSP430retflag)]>
  {  // @SP+ => PC
     let Inst{11-8} = 0b0001; // SP
     let Inst{3-0} = 0;  // PC
  }

  def RETI : II16r<0b000100110, (outs), (ins), "reti", [(MSP430retiflag)]>;
}

let isBranch = 1, isTerminator = 1 in {

// Direct branch
let isBarrier = 1 in {
  // Short branch
  def JMP : CJForm<0b001, 0b111, (outs), (ins jmptarget:$dst),
                   "jmp\t$dst",
                   [(br bb:$dst)]>
    { bits<10> jmptarget;
      let Inst{12-10} = 0b111;
      let Inst{9-0} = jmptarget;
    }

  let isIndirectBranch = 1 in {
    // Long branches [mov EA => PC]
    def Bi  : I16ri<0x4, (outs), (ins i16imm:$brdst),
                    "br\t$brdst",
                    [(brind tblockaddress:$brdst)]>
      {  bits<16> brdst;
        let Inst{31-16} = brdst;
      }

    def Br  : I16rr<0x4, (outs), (ins GR16:$brdst),
                    "br\t$brdst",
                    [(brind GR16:$brdst)]>
      {  bits<4> brdst;
         let Inst{11-8} = brdst;
         let Inst{3-0} = 0; // dst => PC.
      }

    def Bm  : I16rm<0x4, (outs), (ins memsrc:$brdst),
                    "br\t$brdst",
                    [(brind (load addr:$brdst))]>
      {  bits<16> brdst;
        let Inst{31-16} = brdst;
      }
  }
}

// Conditional branches, see MSP430.h for a map of condition -> cc value.
let Uses = [SR] in
  def JCC : CJForm<0b001, 0,
                   (outs), (ins jmptarget:$dst, cc:$cc),
                   "j$cc\t$dst",
                   [(MSP430brcc bb:$dst, imm:$cc)]>
  { bits<3> cc; bits<10> jmptarget;
    let Inst{12-10} = cc;
    let Inst{9-0} = jmptarget;
  }
} // isBranch, isTerminator


//===---------------------------------------------------------------------===//
//  Call Instructions...
//
let isCall = 1 in {
  // All calls clobber the non-callee saved registers. SPW is marked as
  // a use to prevent stack-pointer assignments that appear immediately
  // before calls from potentially appearing dead. Uses for argument
  // registers are added manually.
  let Defs = [R12, R13, R14, R15, SR], Uses = [SP] in {
  def CALLi     : II16i<0b000100101,
                          (outs), (ins i16imm:$dst),
                          "call\t$dst", [(MSP430call imm:$dst)]>
      {  bits<16> dst;
        let Inst{31-16} = dst;
      }

  def CALLr     : II16r<0b000100101,
                          (outs), (ins GR16:$dst),
                          "call\t$dst", [(MSP430call GR16:$dst)]>
      {  bits<4> dst;
         let Inst{3-0} = dst;
      }

// :mem was appended to the dst...
  def CALLm     : II16m<0b000100101,
                          (outs), (ins memsrc:$dst),
                          "call\t${dst}", [(MSP430call (load addr:$dst))]>
      {  bits<16> dst;
        let Inst{31-16} = dst;
      }
  }
}

//===----------------------------------------------------------------------===//
//  Miscellaneous Instructions...
//

// FIXME: other address modes for pop/push.
let Defs = [SP], Uses = [SP], hasSideEffects=0 in {
let mayLoad = 1 in {
def POP8r   : IForm8<0x4, DstReg, SrcPostInc, Size2Bytes,
                     (outs GR8:$reg), (ins), "pop.b\t$reg", []>
  {  bits<4> reg;
     let Inst{11-8} = 0b0001; // SP
     let Inst{3-0} = reg;
  }

def POP16r   : IForm16<0x4, DstReg, SrcPostInc, Size2Bytes,
                       (outs GR16:$reg), (ins), "pop.w\t$reg", []>
  {  bits<4> reg;
     let Inst{11-8} = 0b0001; // SP
     let Inst{3-0} = reg;
  }
}

let mayStore = 1 in {
def PUSH8r  : II8r<0b000100100,
                   (outs), (ins GR8:$reg), "push.b\t$reg",[]>
    { bits<4> reg;
      let Inst{3-0} = reg;
    }

def PUSH16r  : II16r<0b000100100,
                     (outs), (ins GR16:$reg), "push.w\t$reg",[]>
    { bits<4> reg;
      let Inst{3-0} = reg;
    }
  }
}

//===----------------------------------------------------------------------===//
// Move Instructions

let hasSideEffects = 0 in {
def MOV8rr  : I8rr<0x4,
                   (outs GR8:$dst), (ins GR8:$src),
                   "mov.b\t{$src, $dst}",
                   []>
    { bits<4> src; bits<4> dst;
      let Inst{3-0} = dst;
      let Inst{11-8} = src;
    }

def MOV16rr : I16rr<0x4,
                    (outs GR16:$dst), (ins GR16:$src),
                    "mov.w\t{$src, $dst}",
                    []>
    { bits<4> src; bits<4> dst;
      let Inst{3-0} = dst;
      let Inst{11-8} = src;
    }
}

let isReMaterializable = 1, isAsCheapAsAMove = 1 in {

// Match the small immediates before the generic.
def MOV8rsimm : CGForm8<0x4, DstReg, R3Zero, Size2Bytes,
                      (outs GR8:$dst), (ins r2r3imm8:$src),
                   "mov.b\t{$src, $dst}",
                   [(set GR8:$dst, r2r3imm8:$src)]>
  { bits<6> src; bits<4> dst;
    let Inst{11-8} = src{3-0};
    let Inst{5-4}  = src{5-4};
    let Inst{3-0}  = dst;
  }

def MOV16rsimm : CGForm16<0x4, DstReg, R3Zero, Size2Bytes,
                      (outs GR16:$dst), (ins r2r3imm16:$src),
                   "mov.w\t{$src, $dst}",
                   [(set GR16:$dst, r2r3imm16:$src)]>
  { bits<6> src; bits<4> dst;
    let Inst{11-8} = src{3-0};
    let Inst{5-4}  = src{5-4};
    let Inst{3-0}  = dst;
  }

def MOV8ri  : I8ri<0x4,
                   (outs GR8:$dst), (ins i8imm:$src),
                   "mov.b\t{$src, $dst}",
                   [(set GR8:$dst, imm:$src)]>
    { bits<4> dst; bits<16> src;
      let Inst{3-0} = dst;  // src is 0 &(PC)
      let Inst{31-16} = src;
    }

def MOV16ri : I16ri<0x4,
                    (outs GR16:$dst), (ins i16imm:$src),
                    "mov.w\t{$src, $dst}",
                    [(set GR16:$dst, imm:$src)]>
    { bits<4> dst; bits<16> src;
      let Inst{3-0} = dst;  // src is 0 &(PC)
      let Inst{31-16} = src;
    }
}

let canFoldAsLoad = 1, isReMaterializable = 1 in {

def MOV8rri  : CGForm8<0x4, DstReg, R3Zero, Size2Bytes,
                   (outs GR8:$dst), (ins regind:$src),
                   "mov.b\t{$src, $dst}",
                   [(set GR8:$dst, (load regind:$src))]>
  { bits<4> dst; bits<6> src;
    let Inst{11-8} = src{3-0};
    let Inst{5-4}  = src{5-4};
    let Inst{3-0}  = dst;
  }

def MOV16rri : CGForm16<0x4, DstReg, R3Zero, Size2Bytes,
                    (outs GR16:$dst), (ins regind:$src),
                    "mov.w\t{$src, $dst}",
                    [(set GR16:$dst, (load regind:$src))]>
  { bits<4> dst; bits<6> src;
    let Inst{11-8} = src{3-0};
    let Inst{5-4}  = src{5-4};
    let Inst{3-0}  = dst;
  }

def MOV8rm  : I8rm<0x4,
                   (outs GR8:$dst), (ins memsrc:$src),
                   "mov.b\t{$src, $dst}",
                   [(set GR8:$dst, (load addr:$src))]>
  { bits<4> dst; bits<20> src;
    let Inst{3-0} = dst;
    let Inst{11-8} = src{19-16};
    let Inst{31-16} = src{15-0};
  }

def MOV16rm : I16rm<0x4,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "mov.w\t{$src, $dst}",
                    [(set GR16:$dst, (load addr:$src))]>
  { bits<4> dst; bits<20> src;
    let Inst{3-0} = dst;
    let Inst{11-8} = src{19-16};
    let Inst{31-16} = src{15-0};
  }
}

def MOVZX16rr8 : I8rr<0x4,
                      (outs GR16:$dst), (ins GR8:$src),
                      "mov.b\t{$src, $dst}",
                      [(set GR16:$dst, (zext GR8:$src))]>
    { bits<4> src; bits<4> dst;
      let Inst{3-0} = dst;
      let Inst{11-8} = src;
    }

def MOVZX16rim8 : CGForm8<0x4, DstReg, R3Zero, Size2Bytes,
                      (outs GR16:$dst), (ins regind:$src),
                      "mov.b\t{$src, $dst}",
                      [(set GR16:$dst, (zextloadi16i8 regind:$src))]>
  { bits<4> dst; bits<6> src;
    let Inst{11-8} = src{3-0};
    let Inst{5-4}  = src{5-4};
    let Inst{3-0}  = dst;
  }

def MOVX16rim8 : CGForm8<0x4, DstReg, R3Zero, Size2Bytes,
                      (outs GR16:$dst), (ins regind:$src),
                      "mov.b\t{$src, $dst}",
                      [(set GR16:$dst, (extloadi16i8 regind:$src))]>
  { bits<4> dst; bits<6> src;
    let Inst{11-8} = src{3-0};
    let Inst{5-4}  = src{5-4};
    let Inst{3-0}  = dst;
  }

def MOVZX16rm8 : I8rm<0x4,
                      (outs GR16:$dst), (ins memsrc:$src),
                      "mov.b\t{$src, $dst}",
                      [(set GR16:$dst, (zextloadi16i8 addr:$src))]>
  { bits<4> dst; bits<20> src;
    let Inst{3-0} = dst;
    let Inst{11-8} = src{19-16};
    let Inst{31-16} = src{15-0};
  }

def MOVX16rm8 : I8rm<0x4,
                      (outs GR16:$dst), (ins memsrc:$src),
                      "mov.b\t{$src, $dst}",
                      [(set GR16:$dst, (extloadi16i8 addr:$src))]>
  { bits<4> dst; bits<20> src;
    let Inst{3-0} = dst;
    let Inst{11-8} = src{19-16};
    let Inst{31-16} = src{15-0};
  }

let mayLoad = 1, hasExtraDefRegAllocReq = 1, Constraints = "$base = $base_wb" in {
def MOV8rm_POST  : IForm8<0x4, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, regindirect:$base_wb), (ins regindirect:$base),
                         "mov.b\t{$base, $dst}", []>
  { bits<4> dst; bits<4> base;
    let Inst{3-0} = dst;
    let Inst{11-8} = base;
  }

def MOV16rm_POST : IForm16<0x4, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, regindirect:$base_wb), (ins regindirect:$base),
                           "mov.w\t{$base, $dst}", []>
  { bits<4> dst; bits<4> base;
    let Inst{3-0} = dst;
    let Inst{11-8} = base;
  }
}

// Any instruction that defines a 8-bit result leaves the high half of the
// register. Truncate can be lowered to EXTRACT_SUBREG, and CopyFromReg may
// be copying from a truncate, but any other 8-bit operation will zero-extend
// up to 16 bits.
def def8 : PatLeaf<(i8 GR8:$src), [{
  return N->getOpcode() != ISD::TRUNCATE &&
         N->getOpcode() != TargetOpcode::EXTRACT_SUBREG &&
         N->getOpcode() != ISD::CopyFromReg;
}]>;

// In the case of a 8-bit def that is known to implicitly zero-extend,
// we can use a SUBREG_TO_REG.
def : Pat<(i16 (zext def8:$src)),
          (SUBREG_TO_REG (i16 0), GR8:$src, subreg_8bit)>;

def MOV8mi  : I8mi<0x4,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   "mov.b\t{$src, $dst}",
                   [(store (i8 imm:$src), addr:$dst)]>
  { bits<16> src; bits<20> dst;
    let Inst{31-16} = src;
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = dst{15-0};
  }

def MOV16mi : I16mi<0x4,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "mov.w\t{$src, $dst}",
                    [(store (i16 imm:$src), addr:$dst)]>
  { bits<16> src; bits<20> dst;
    let Inst{31-16} = src;
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = dst{15-0};
  }

def MOV8mr  : I8mr<0x4,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "mov.b\t{$src, $dst}",
                   [(store GR8:$src, addr:$dst)]>
  { bits<4> src; bits<20> dst;
    let Inst{11-8} = src;
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = dst{15-0};
  }

def MOV16mr : I16mr<0x4,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "mov.w\t{$src, $dst}",
                    [(store GR16:$src, addr:$dst)]>
  { bits<4> src; bits<20> dst;
    let Inst{11-8} = src;
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = dst{15-0};
  }

def MOV8mm  : I8mm<0x4,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "mov.b\t{$src, $dst}",
                   [(store (i8 (load addr:$src)), addr:$dst)]>
  { bits<20> src; bits<20> dst;
    let Inst{11-8} = src{19-16};
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = src{15-0};
    let Inst{47-32} = dst{15-0};
  }

def MOV16mm : I16mm<0x4,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "mov.w\t{$src, $dst}",
                    [(store (i16 (load addr:$src)), addr:$dst)]>
  { bits<20> src; bits<20> dst;
    let Inst{11-8} = src{19-16};
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = src{15-0};
    let Inst{47-32} = dst{15-0};
  }

//===----------------------------------------------------------------------===//
// Arithmetic Instructions

multiclass CoreInsn<OpForm1 opc, string rAsm, SDNode opnode, bit c> {

  def 8rr  : I8rr<opc.Value,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   rAsm#".b\t{$src2, $dst}",
                   [(set GR8:$dst, (opnode GR8:$src, GR8:$src2)),
                    (implicit SR)]>
    { bits<4> dst; bits<4>src2;
      let Inst{3-0} = dst;
      let Inst{11-8} = src2;
      let isCommutable = c;
      let Constraints = "$src = $dst";
    }

  def 16rr : I16rr<opc.Value,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    rAsm#".w\t{$src2, $dst}",
                    [(set GR16:$dst, (opnode GR16:$src, GR16:$src2)),
                     (implicit SR)]>
    { bits<4> dst; bits<4>src2;
      let Inst{3-0} = dst;
      let Inst{11-8} = src2;
      let isCommutable = c;
      let Constraints = "$src = $dst";
    }

  def 8rm  : I8rm<opc.Value,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   rAsm#".b\t{$src2, $dst}",
                   [(set GR8:$dst, (opnode GR8:$src, (load addr:$src2))),
                    (implicit SR)]>
    { bits<4> dst;
      let Inst{3-0} = dst;
      let Constraints = "$src = $dst";
    }

  def 16rm : I16rm<opc.Value,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    rAsm#".w\t{$src2, $dst}",
                    [(set GR16:$dst, (opnode GR16:$src, (load addr:$src2))),
                     (implicit SR)]>
    { bits<4> dst;
      let Inst{3-0} = dst;
      let Constraints = "$src = $dst";
    }

  def 8rm_POST : IForm8<opc.Value, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, regindirect:$base_wb),
                         (ins GR8:$src, regindirect:$base),
                         rAsm#".b\t{$base, $dst}", []>
    { bits<4> dst; bits<4> base;
      let Inst{3-0} = dst;
      let Inst{11-8} = base;
      let Constraints = "$base = $base_wb, $src = $dst";
      let mayLoad = 1;
      let hasExtraDefRegAllocReq = 1;
    }

  def 16rm_POST : IForm16<opc.Value, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, regindirect:$base_wb),
                           (ins GR16:$src, regindirect:$base),
                          rAsm#".w\t{$base, $dst}", []>
    { bits<4> dst; bits<4> base;
      let Inst{3-0} = dst;
      let Inst{11-8} = base;
      let Constraints = "$base = $base_wb, $src = $dst";
      let mayLoad = 1;
      let hasExtraDefRegAllocReq = 1;
    }

   def 8rsimm : CGForm8<opc.Value, DstReg, R3Zero, Size2Bytes,
                      (outs GR8:$dst), (ins GR8:$src, r2r3imm8:$src2),
                   rAsm#".b\t{$src2, $dst}",
                   [(set GR8:$dst, (opnode GR8:$src, r2r3imm8:$src2)),
                    (implicit SR)]>
    { bits<6> src2; bits<4> dst;
      let Inst{11-8} = src2{3-0};
      let Inst{5-4}  = src2{5-4};
      let Inst{3-0}  = dst;
      let Constraints = "$src = $dst";
   }

  def 16rsimm : CGForm16<opc.Value, DstReg, R3Zero, Size2Bytes,
                      (outs GR16:$dst), (ins GR16:$src,r2r3imm16:$src2),
                   rAsm#".w\t{$src2, $dst}",
                   [(set GR16:$dst, (opnode GR16:$src, r2r3imm16:$src2)),
                    (implicit SR)]>
    { bits<6> src2; bits<4> dst;
      let Inst{11-8} = src2{3-0};
      let Inst{5-4}  = src2{5-4};
      let Inst{3-0}  = dst;
      let Constraints = "$src = $dst";
    }

  def 8ri  : I8ri<opc.Value,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   rAsm#".b\t{$src2, $dst}",
                   [(set GR8:$dst, (opnode GR8:$src, imm:$src2)),
                    (implicit SR)]>
    { bits<4> dst; bits<16> src2;
      let Inst{3-0} = dst;
      let Inst{31-16} = src2;
      let Constraints = "$src = $dst";
    }

  def 16ri : I16ri<opc.Value,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    rAsm#".w\t{$src2, $dst}",
                    [(set GR16:$dst, (opnode GR16:$src, imm:$src2)),
                     (implicit SR)]>
    { bits<4> dst; bits<16> src2;
      let Inst{3-0} = dst;
      let Inst{31-16} = src2;
      let Constraints = "$src = $dst";
    }

  def 8mr  : I8mr<opc.Value,
                   (outs), (ins memdst:$dst, GR8:$src),
                   rAsm#".b\t{$src, $dst}",
                   [(store (opnode (load addr:$dst), GR8:$src), addr:$dst),
                    (implicit SR)]>
    { bits<4> src; bits<20> dst;
      let Inst{11-8} = src;
      let Inst{3-0} = dst{19-16};
      let Inst{31-16} = dst{15-0};
    }

  def 16mr : I16mr<opc.Value,
                    (outs), (ins memdst:$dst, GR16:$src),
                    rAsm#".w\t{$src, $dst}",
                    [(store (opnode (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SR)]>
    { bits<4> src; bits<20> dst;
      let Inst{11-8} = src;
      let Inst{3-0} = dst{19-16};
      let Inst{31-16} = dst{15-0};
    }

  def 8mi  : I8mi<opc.Value,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   rAsm#".b\t{$src, $dst}",
                   [(store (opnode (load addr:$dst), (i8 imm:$src)), addr:$dst),
                    (implicit SR)]>
    { bits<16> src; bits<20> dst;
      let Inst{31-16} = src;
      let Inst{3-0} = dst{19-16};
      let Inst{31-16} = dst{15-0};
    }

  def 16mi : I16mi<opc.Value,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    rAsm#".w\t{$src, $dst}",
                    [(store (opnode (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SR)]>
    { bits<16> src; bits<20> dst;
      let Inst{31-16} = src;
      let Inst{3-0} = dst{19-16};
      let Inst{31-16} = dst{15-0};
    }

  def 8mm  : I8mm<opc.Value,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   rAsm#".b\t{$src, $dst}",
                   [(store (opnode (load addr:$dst), 
                                (i8 (load addr:$src))), addr:$dst),
                    (implicit SR)]>
    { bits<20> src; bits<20> dst;
      let Inst{11-8} = src{19-16};
      let Inst{3-0} = dst{19-16};
      let Inst{31-16} = src{15-0};
      let Inst{47-32} = dst{15-0};
      let isCommutable = c;
    }

  def 16mm : I16mm<opc.Value,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    rAsm#".w\t{$src, $dst}",
                    [(store (opnode (load addr:$dst), 
                                  (i16 (load addr:$src))), addr:$dst),
                     (implicit SR)]>
    { bits<20> src; bits<20> dst;
      let Inst{11-8} = src{19-16};
      let Inst{3-0} = dst{19-16};
      let Inst{31-16} = src{15-0};
      let Inst{47-32} = dst{15-0};
      let isCommutable = c;
    }
}

let Defs = [SR] in {

defm ADD : CoreInsn <OpADD, "add", add, 1>;
defm AND : CoreInsn <OpAND, "and", and, 1>;
defm OR  : CoreInsn <OpBIS, "bis", or, 1>;
defm XOR : CoreInsn <OpXOR, "xor", xor, 1>;
defm SUB : CoreInsn <OpSUB, "sub", sub, 0>;

let Uses = [SR] in {

defm ADC : CoreInsn <OpADC, "addc", adde, 1>;
defm SBC : CoreInsn <OpSBC, "subc", sube, 0>;

def CLRC : MSP430Inst<(outs), (ins), Size2Bytes, SingleOpFrm, "clrc">
  { // actually bic #1, r2
    let Inst{15-0} = 0xC312;
  }

def CLRZ : MSP430Inst<(outs), (ins), Size2Bytes, SingleOpFrm, "clrz">
  { // actually bic #2, r2
    let Inst{15-0} = 0xC322;
  }

def CLRN : MSP430Inst<(outs), (ins), Size2Bytes, SingleOpFrm, "clrn">
  { // actually bic #4, r2
    let Inst{15-0} = 0xC222;
  }

} // Uses = [SR]
} // Defs = [SR]


// bic does not modify condition codes
def BIC8rr :  I8rr<0xC,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "bic.b\t{$src2, $dst}",
                   [(set GR8:$dst, (and GR8:$src, (not GR8:$src2)))]>
  { bits<4> dst; bits<4>src2;
    let Inst{3-0} = dst;
    let Inst{11-8} = src2;
    let Constraints = "$src = $dst";
  }

def BIC16rr : I16rr<0xC,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not GR16:$src2)))]>
  { bits<4> dst; bits<4>src2;
    let Inst{3-0} = dst;
    let Inst{11-8} = src2;
    let Constraints = "$src = $dst";
  }

def BIC8rm :  I8rm<0xC,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "bic.b\t{$src2, $dst}",
                    [(set GR8:$dst, (and GR8:$src, (not (i8 (load addr:$src2)))))]>
  { bits<4> dst; bits<20> src2;
    let Inst{3-0} = dst;
    let Inst{11-8} = src2{19-16};
    let Inst{31-16} = src2{15-0};
    let Constraints = "$src = $dst";
  }

def BIC16rm : I16rm<0xC,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not (i16 (load addr:$src2)))))]>
  { bits<4> dst; bits<20> src2;
    let Inst{3-0} = dst;
    let Inst{11-8} = src2{19-16};
    let Inst{31-16} = src2{15-0};
    let Constraints = "$src = $dst";
  }

def BIC8mr :  I8mr<0xC,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "bic.b\t{$src, $dst}",
                   [(store (and (load addr:$dst), (not GR8:$src)), addr:$dst)]>
  { bits<4> src; bits<20> dst;
    let Inst{11-8} = src;
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = dst{15-0};
  }

def BIC16mr : I16mr<0xC,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), (not GR16:$src)), addr:$dst)]>
  { bits<4> src; bits<20> dst;
    let Inst{11-8} = src;
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = dst{15-0};
  }

def BIC8mm :  I8mm<0xC,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "bic.b\t{$src, $dst}",
                   [(store (and (load addr:$dst),
                                (not (i8 (load addr:$src)))), addr:$dst)]>
  { bits<20> src; bits<20> dst;
    let Inst{11-8} = src{19-16};
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = src{15-0};
    let Inst{47-32} = dst{15-0};
  }

def BIC16mm : I16mm<0xC,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst),
                                 (not (i16 (load addr:$src)))), addr:$dst)]>
  { bits<20> src; bits<20> dst;
    let Inst{11-8} = src{19-16};
    let Inst{3-0} = dst{19-16};
    let Inst{31-16} = src{15-0};
    let Inst{47-32} = dst{15-0};
  }

let Defs = [SR] in {
// FIXME: memory variant!
// Arithmetic shift right with lsb shifted into carry.
def SAR8r1  : II8r<0b000100010,
                   (outs GR8:$dst), (ins GR8:$src),
                   "rra.b\t$dst",
                   [(set GR8:$dst, (MSP430rra GR8:$src)),
                    (implicit SR)]>
  { bits<4> dst;
    let Inst{3-0} = dst;
    let Constraints = "$src = $dst";
  }

//def SAR8m1  : II8r<0b000100010,
//                   (outs memdst:$dst), (ins memsrc:$src),
//                   "rra.b\t$dst",
//                   [(store (MSP430rra (i8 (load addr:$src))), addr:$dst),
//                    (implicit SR)]>
//  { bits<20> dst;
//    let Inst{3-0} = dst{19-16};
//    let Inst{31-16} = dst{15-0};
//    let Constraints = "$src = $dst";
//  }

def SAR16r1 : II16r<0b000100010,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rra.w\t$dst",
                    [(set GR16:$dst, (MSP430rra GR16:$src)),
                     (implicit SR)]>
  { bits<4> dst;
    let Inst{3-0} = dst;
    let Constraints = "$src = $dst";
  }

// Rotate right through carry.
def RRC8r1c : II8r<0b000101000,
                   (outs GR8:$dst), (ins GR8:$src),
                   "rrc.b\t$dst",
                   []>
  { bits<4> dst;
    let Inst{3-0} = dst;
    let Constraints = "$src = $dst";
  }

def RRC16r1c : II16r<0b000100000,
                     (outs GR16:$dst), (ins GR16:$src),
                     "rrc.w\t$dst",
                     []>
  { bits<4> dst;
    let Inst{3-0} = dst;
    let Constraints = "$src = $dst";
  }

// Emulate a single bit shift right by add dst,dst
def SHL8r1  : I8rr<0x5,
                   (outs GR8:$dst), (ins GR8:$src),
                   "rla.b\t$dst",
                   [(set GR8:$dst, (MSP430rla GR8:$src)),
                    (implicit SR)]>
  { bits<4> dst; bits<4> src;
    let Inst{3-0} = dst;
    let Inst{11-8} = src;
    let Constraints = "$src = $dst";
  }

def SHL16r1 : I16rr<0x5,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rla.w\t$dst",
                    [(set GR16:$dst, (MSP430rla GR16:$src)),
                     (implicit SR)]>
  { bits<4> dst; bits<4> src;
    let Inst{3-0} = dst;
    let Inst{11-8} = src;
    let Constraints = "$src = $dst";
  }

def SAR8r1c  : Pseudo<(outs GR8:$dst), (ins GR8:$src),
                      "#SAR8r1c clrc rrc.b\t $dst",
                      [(set GR8:$dst, (MSP430rrc GR8:$src)),
                       (implicit SR)]>
  {
    let Constraints = "$src = $dst";
    let usesCustomInserter = 1;
  }

def SAR16r1c : Pseudo<(outs GR16:$dst), (ins GR16:$src),
                      "#SAR16r1c clrc rrc.w\t $dst",
                      [(set GR16:$dst, (MSP430rrc GR16:$src)),
                       (implicit SR)]>
  {
    let Constraints = "$src = $dst";
    let usesCustomInserter = 1;
  }

// FIXME sext in memory pseudo?
def SEXT16r : II16r<0b000100011,
                    (outs GR16:$dst), (ins GR16:$src),
                    "sxt\t$dst",
                    [(set GR16:$dst, (sext_inreg GR16:$src, i8)),
                     (implicit SR)]>
  { bits<4> dst;
    let Inst{3-0} = dst;
    let Constraints = "$src = $dst";
  }

} // Defs = [SR]

// FIXME zext in memory pseudo?
def ZEXT16r : I8rr<0x4,
                   (outs GR16:$dst), (ins GR16:$src),
                   "mov.b\t{$src, $dst}",
                   [(set GR16:$dst, (zext (trunc GR16:$src)))]>
  {  bits<4> src; bits<4> dst;
    let Inst{3-0} = dst;
    let Inst{11-8} = src;
//    let Constraints = "$src = $dst";
  }

// Integer comparisons
let Defs = [SR] in {

// Match the small immediate before the generic.
def CMP8rsimm : CGForm8<0x9, DstReg, R3Zero, Size2Bytes,
                      (outs), (ins GR8:$src, r2r3imm8:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(MSP430cmp GR8:$src, r2r3imm8:$src2), (implicit SR)]>
  { bits<6> src2; bits<4> src;
    let Inst{11-8} = src2{3-0};
    let Inst{5-4}  = src2{5-4};
    let Inst{3-0}  = src;
  }

def CMP16rsimm : CGForm16<0x9, DstReg, R3Zero, Size2Bytes,
                      (outs), (ins GR16:$src, r2r3imm16:$src2),
                   "cmp.w\t{$src2, $src}",
                   [(MSP430cmp GR16:$src, r2r3imm16:$src2), (implicit SR)]>
  { bits<6> src2; bits<4> src;
    let Inst{11-8} = src2{3-0};
    let Inst{5-4}  = src2{5-4};
    let Inst{3-0}  = src;
  }

def CMP8rr  : I8rr<0x9,
                   (outs), (ins GR8:$src, GR8:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(MSP430cmp GR8:$src, GR8:$src2), (implicit SR)]>
  { bits<4> src; bits<4>src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2;
  }

def CMP16rr : I16rr<0x9,
                    (outs), (ins GR16:$src, GR16:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(MSP430cmp GR16:$src, GR16:$src2), (implicit SR)]>
  { bits<4> src; bits<4>src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2;
  }

def CMP8ri  : I8ri<0x9,
                   (outs), (ins GR8:$src, i8imm:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(MSP430cmp GR8:$src, imm:$src2), (implicit SR)]>
  { bits<4> src; bits<16> src2;
    let Inst{3-0} = src;  // src is 0 &(PC)
    let Inst{31-16} = src2;
  }

def CMP16ri : I16ri<0x9,
                    (outs), (ins GR16:$src, i16imm:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(MSP430cmp GR16:$src, imm:$src2), (implicit SR)]>
  { bits<4> src; bits<16> src2;
    let Inst{3-0} = src;  // src is 0 &(PC)
    let Inst{31-16} = src2;
  }

// CHECKME! operand order
def CMP8mi  : I8mi<0x9,
                   (outs), (ins memsrc:$src, i8imm:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(MSP430cmp (load addr:$src),
                               (i8 imm:$src2)), (implicit SR)]>
  { bits<16> src2; bits<20> src;
    let Inst{31-16} = src2;
    let Inst{3-0} = src{19-16};
    let Inst{47-32} = src{15-0};
  }

// CHECKME! operand order
def CMP16mi : I16mi<0x9,
                    (outs), (ins memsrc:$src, i16imm:$src2),
                    "cmp.w\t{$src2, $src}",
                     [(MSP430cmp (load addr:$src),
                                 (i16 imm:$src2)), (implicit SR)]>
  { bits<16> src2; bits<20> src;
    let Inst{31-16} = src2;
    let Inst{3-0} = src{19-16};
    let Inst{47-32} = src{15-0};
  }

def CMP8rm  : I8rm<0x9,
                   (outs), (ins GR8:$src, memsrc:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(MSP430cmp GR8:$src, (load addr:$src2)), 
                    (implicit SR)]>
  { bits<4> src; bits<20> src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2{19-16};
    let Inst{31-16} = src2{15-0};
  }

def CMP16rm : I16rm<0x9,
                    (outs), (ins GR16:$src, memsrc:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(MSP430cmp GR16:$src, (load addr:$src2)),
                     (implicit SR)]>
  { bits<4> src; bits<20> src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2{19-16};
    let Inst{31-16} = src2{15-0};
  }

def CMP8mr  : I8mr<0x9,
                   (outs), (ins memsrc:$src, GR8:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(MSP430cmp (load addr:$src), GR8:$src2),
                    (implicit SR)]>
  { bits<4> src2; bits<20> src;
    let Inst{11-8} = src2;
    let Inst{3-0} = src{19-16};
    let Inst{31-16} = src{15-0};
  }

def CMP16mr : I16mr<0x9,
                    (outs), (ins memsrc:$src, GR16:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(MSP430cmp (load addr:$src), GR16:$src2), 
                     (implicit SR)]>
  { bits<4> src2; bits<20> src;
    let Inst{11-8} = src2;
    let Inst{3-0} = src{19-16};
    let Inst{31-16} = src{15-0};
  }

// BIT TESTS, just sets condition codes
// Note that the C condition is set differently than when using CMP.

def BIT8rr  : I8rr<0xb,
                   (outs), (ins GR8:$src, GR8:$src2),
                   "bit.b\t{$src2, $src}",
                   [(MSP430cmp (and_su GR8:$src, GR8:$src2), 0),
                    (implicit SR)]>
  {  bits<4> src; bits<4>src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2;
    let isCommutable = 1;
  }

def BIT16rr : I16rr<0xb,
                    (outs), (ins GR16:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(MSP430cmp (and_su GR16:$src, GR16:$src2), 0),
                     (implicit SR)]>
  {  bits<4> src; bits<4>src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2;
    let isCommutable = 1;
  }

def BIT8ri  : I8ri<0xb,
                   (outs), (ins GR8:$src, i8imm:$src2),
                   "bit.b\t{$src2, $src}",
                   [(MSP430cmp (and_su GR8:$src, imm:$src2), 0),
                    (implicit SR)]>
  { bits<4> dst; bits<16> src2;
    let Inst{3-0} = dst;
    let Inst{31-16} = src2;
  }

def BIT16ri : I16ri<0xb,
                    (outs), (ins GR16:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(MSP430cmp (and_su GR16:$src, imm:$src2), 0),
                     (implicit SR)]>
  { bits<4> src; bits<16> src2;
    let Inst{3-0} = src;
    let Inst{31-16} = src2;
  }

def BIT8rm  : I8rm<0xb,
                   (outs), (ins GR8:$src, memdst:$src2),
                   "bit.b\t{$src2, $src}",
                   [(MSP430cmp (and_su GR8:$src,  (load addr:$src2)), 0),
                    (implicit SR)]>
  {  bits<4> src;  bits<20> src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2{19-16};
    let Inst{31-16} = src2{15-0};

  }

def BIT16rm : I16rm<0xb,
                    (outs), (ins GR16:$src, memdst:$src2),
                    "bit.w\t{$src2, $src}",
                    [(MSP430cmp (and_su GR16:$src,  (load addr:$src2)), 0),
                     (implicit SR)]>
  {  bits<4> src; bits<20> src2;
    let Inst{3-0} = src;
    let Inst{11-8} = src2{19-16};
    let Inst{31-16} = src2{15-0};
  }

def BIT8mr  : I8mr<0xb,
                  (outs), (ins memsrc:$src, GR8:$src2),
                  "bit.b\t{$src2, $src}",
                  [(MSP430cmp (and_su (load addr:$src), GR8:$src2), 0),
                   (implicit SR)]>
  {  bits<4> src2; bits<20> src;
    let Inst{11-8} = src2;
    let Inst{3-0} = src{19-16};
    let Inst{31-16} = src{15-0};
  }

def BIT16mr : I16mr<0xb,
                    (outs), (ins memsrc:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(MSP430cmp (and_su (load addr:$src), GR16:$src2), 0),
                     (implicit SR)]>
  { bits<4> src2; bits<20> src;
    let Inst{11-8} = src2;
    let Inst{3-0} = src{19-16};
    let Inst{31-16} = src{15-0};
  }

// CHECKME operand ordering.
def BIT8mi  : I8mi<0xb,
                   (outs), (ins memsrc:$src, i8imm:$src2),
                   "bit.b\t{$src2, $src}",
                   [(MSP430cmp (and_su (load addr:$src), (i8 imm:$src2)), 0),
                    (implicit SR)]>
  { bits<16> src2; bits<20> src;
    let Inst{3-0} = src{19-16};
    let Inst{31-16} = src2;
    let Inst{47-32} = src{15-0};
  }

def BIT16mi : I16mi<0xb,
                    (outs), (ins memsrc:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(MSP430cmp (and_su (load addr:$src), (i16 imm:$src2)), 0),
                     (implicit SR)]>
  { bits<16> src2; bits<20> src;
    let Inst{3-0} = src{19-16};
    let Inst{31-16} = src2;
    let Inst{47-32} = src{15-0};
  }

def BIT8mm  : I8mm<0xb,
                   (outs), (ins memsrc:$src, memsrc:$src2),
                   "bit.b\t{$src2, $src}",
                   [(MSP430cmp (and_su (i8 (load addr:$src)),
                                       (load addr:$src2)), 0),
                      (implicit SR)]>;

def BIT16mm : I16mm<0xb,
                    (outs), (ins memsrc:$src, memsrc:$src2),
                    "bit.w\t{$src2, $src}",
                    [(MSP430cmp (and_su (i16 (load addr:$src)),
                                        (load addr:$src2)), 0),
                     (implicit SR)]>;
} // Defs = [SR]

//===---------------------------------------------------------------------===//

multiclass DestOnly<OpForm2 opc, OpSize bw, RegisterClass RC,
                        string rAsm, SDNode opnode, string XT> {

  // rN
  def _r : F2<opc, bw, Size2Bytes,
             (outs RC:$dst), (ins RC:$src),
             rAsm#XT#"\t$dst",
             [(set RC:$dst, (opnode RC:$src))]>
    { bits<4> dst;
      let Inst{5-4} = SrcReg.Value;
      let Inst{3-0} = dst;
      let Constraints = "$src = $dst";
    }

  // @rN
  def _x : F2<opc, bw, Size2Bytes,
             (outs), (ins regind:$dst),
             rAsm#XT#"\t$dst",
             [(store (i16 (opnode (load regind:$dst))), regind:$dst)]>
    { bits<6> dst;
      let Inst{5-0} = dst;
      let mayLoad = 1;
      let mayStore = 1;
    }

  // @rN+ (has to be matched in code).
  def _p : F2<opc, bw, Size2Bytes,
             (outs), (ins GR16:$dst),
             rAsm#XT#"\t$dst",
             [/* */]>
    {
      let Inst{5-4} = 0b11;
      let mayLoad = 1;
      let mayStore = 1;
    }

  // d(rN)
  def _d : F2<opc, bw, Size4Bytes,
             (outs), (ins memsrc:$dst),
             rAsm#XT#"\t$dst",
             [(store (i16 (opnode (load memsrc:$dst))), memsrc:$dst)]>
    { bits<22> dst;
      let Inst{5-0} = dst{21-16};
      let Inst{31-16} = dst{15-0};
      let mayLoad = 1;
      let mayStore = 1;
    }
}

defm SWAP : DestOnly <OpSWP, OpWord, GR16, "swpb", bswap, "">;
// FIXME swap in memory pseudo?
//def SWPB16r : II16r<0b000100001,
//                    (outs GR16:$dst), (ins GR16:$src),
//                    "swpb\t$dst",
//                    [(set GR16:$dst, (bswap GR16:$src))]>
//  {  bits<4> dst;
//    let Inst{3-0} = dst;
//    let Constraints = "$src = $dst";
//  }

//def SWPB16m : II16r<0b000100001,
//                    (outs GR16:$dst), (ins GR16:$src),
//                    "swpb\t$dst",
//                    [(set GR16:$dst, (bswap GR16:$src))]>
//  {  bits<4> dst;
//    let Inst{3-0} = dst;
//    let Constraints = "$src = $dst";
//  }

//defm SEXT : DestOnly <OpSXT, OpWord, GR16, "sxt", sext, "">;
//===----------------------------------------------------------------------===//
// Non-Instruction Patterns

// extload
//def : Pat<(extloadi16i8 addr:$src), (MOVZX16rm8 addr:$src)>;

// anyext
def : Pat<(i16 (anyext GR8:$src)),
          (SUBREG_TO_REG (i16 0), GR8:$src, subreg_8bit)>;

// truncs
def : Pat<(i8 (trunc GR16:$src)),
          (EXTRACT_SUBREG GR16:$src, subreg_8bit)>;

// GlobalAddress, ExternalSymbol
def : Pat<(i16 (MSP430Wrapper tglobaladdr:$dst)), (MOV16ri tglobaladdr:$dst)>;
def : Pat<(i16 (MSP430Wrapper texternalsym:$dst)), (MOV16ri texternalsym:$dst)>;
def : Pat<(i16 (MSP430Wrapper tblockaddress:$dst)), (MOV16ri tblockaddress:$dst)>;

def : Pat<(add GR16:$src, (MSP430Wrapper tglobaladdr :$src2)),
          (ADD16ri GR16:$src, tglobaladdr:$src2)>;
def : Pat<(add GR16:$src, (MSP430Wrapper texternalsym:$src2)),
          (ADD16ri GR16:$src, texternalsym:$src2)>;
def : Pat<(add GR16:$src, (MSP430Wrapper tblockaddress:$src2)),
          (ADD16ri GR16:$src, tblockaddress:$src2)>;

def : Pat<(store (i16 (MSP430Wrapper tglobaladdr:$src)), addr:$dst),
          (MOV16mi addr:$dst, tglobaladdr:$src)>;
def : Pat<(store (i16 (MSP430Wrapper texternalsym:$src)), addr:$dst),
          (MOV16mi addr:$dst, texternalsym:$src)>;
def : Pat<(store (i16 (MSP430Wrapper tblockaddress:$src)), addr:$dst),
          (MOV16mi addr:$dst, tblockaddress:$src)>;

// calls
def : Pat<(MSP430call (i16 tglobaladdr:$dst)),
          (CALLi tglobaladdr:$dst)>;
def : Pat<(MSP430call (i16 texternalsym:$dst)),
          (CALLi texternalsym:$dst)>;

// add and sub always produce carry
def : Pat<(addc GR16:$src, GR16:$src2),
          (ADD16rr GR16:$src, GR16:$src2)>;
def : Pat<(addc GR16:$src, (load addr:$src2)),
          (ADD16rm GR16:$src, addr:$src2)>;
def : Pat<(addc GR16:$src, imm:$src2),
          (ADD16ri GR16:$src, imm:$src2)>;
def : Pat<(store (addc (load addr:$dst), GR16:$src), addr:$dst),
          (ADD16mr addr:$dst, GR16:$src)>;
def : Pat<(store (addc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (ADD16mm addr:$dst, addr:$src)>;

def : Pat<(addc GR8:$src, GR8:$src2),
          (ADD8rr GR8:$src, GR8:$src2)>;
def : Pat<(addc GR8:$src, (load addr:$src2)),
          (ADD8rm GR8:$src, addr:$src2)>;
def : Pat<(addc GR8:$src, imm:$src2),
          (ADD8ri GR8:$src, imm:$src2)>;
def : Pat<(store (addc (load addr:$dst), GR8:$src), addr:$dst),
          (ADD8mr addr:$dst, GR8:$src)>;
def : Pat<(store (addc (load addr:$dst), (i8 (load addr:$src))), addr:$dst),
          (ADD8mm addr:$dst, addr:$src)>;

def : Pat<(subc GR16:$src, GR16:$src2),
          (SUB16rr GR16:$src, GR16:$src2)>;
def : Pat<(subc GR16:$src, (load addr:$src2)),
          (SUB16rm GR16:$src, addr:$src2)>;
def : Pat<(subc GR16:$src, imm:$src2),
          (SUB16ri GR16:$src, imm:$src2)>;
def : Pat<(store (subc (load addr:$dst), GR16:$src), addr:$dst),
          (SUB16mr addr:$dst, GR16:$src)>;
def : Pat<(store (subc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (SUB16mm addr:$dst, addr:$src)>;

def : Pat<(subc GR8:$src, GR8:$src2),
          (SUB8rr GR8:$src, GR8:$src2)>;
def : Pat<(subc GR8:$src, (load addr:$src2)),
          (SUB8rm GR8:$src, addr:$src2)>;
def : Pat<(subc GR8:$src, imm:$src2),
          (SUB8ri GR8:$src, imm:$src2)>;
def : Pat<(store (subc (load addr:$dst), GR8:$src), addr:$dst),
          (SUB8mr addr:$dst, GR8:$src)>;
def : Pat<(store (subc (load addr:$dst), (i8 (load addr:$src))), addr:$dst),
          (SUB8mm addr:$dst, addr:$src)>;

// peephole patterns
def : Pat<(and GR16:$src, 255), (ZEXT16r GR16:$src)>;
def : Pat<(MSP430cmp (trunc (and_su GR16:$src, GR16:$src2)), 0),
          (BIT8rr (EXTRACT_SUBREG GR16:$src, subreg_8bit),
                  (EXTRACT_SUBREG GR16:$src2, subreg_8bit))>;
