//===-- MSP430InstrFormats.td - MSP430 Instruction Formats -*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Describe MSP430 instructions format here
//

// Format specifies the encoding used by the instruction.  This is part of the
// ad-hoc solution used to emit machine instruction encodings by our machine
// code emitter.
class Format<bits<2> val> {
  bits<2> Value = val;
}

def PseudoFrm   : Format<0>;
def DoubleOpFrm : Format<1>;
def SingleOpFrm : Format<2>;
def CondJumpFrm : Format<3>;

// Operation size Byte/Word
class OpSize<bit val> {
  bit Value = val;
}

def OpWord      : OpSize<0>;
def OpByte      : OpSize<1>;

class SourceMode<bits<2> val> {
  bits<2> Value = val;
}

def SrcReg      : SourceMode<0>;
def SrcMem      : SourceMode<1>;
def SrcIndReg   : SourceMode<2>;
def SrcPostInc  : SourceMode<3>;
def SrcImm      : SourceMode<3>;

class DestMode<bit val> {
  bit Value = val;
}

def DstReg      : DestMode<0>;
def DstMem      : DestMode<1>;


class SizeVal<bits<3> val> {
  bits<3> Value = val;
}

def SizeUnknown : SizeVal<0>; // Unknown / unset size
def SizeSpecial : SizeVal<1>; // Special instruction, e.g. pseudo
def Size2Bytes  : SizeVal<2>;
def Size4Bytes  : SizeVal<4>;
def Size6Bytes  : SizeVal<6>;

// Regs R2 and R3 used as Constant Generators.
class CGVal<bits<2> val> {
  bits<2> Value = val;
}

def R2Reg   : CGVal<0>;
def R2Abs   : CGVal<1>;
def R2Four  : CGVal<2>;
def R2Eight : CGVal<3>;

def R3Zero  : CGVal<0>;
def R3One   : CGVal<1>;
def R3Two   : CGVal<2>;
def R3MOne  : CGVal<3>;

// Generic MSP430 Format
class MSP430Inst<dag outs, dag ins, SizeVal sz, Format f,
                 string asmstr> : Instruction {
  // Max size instruction(16):operand1(16):operand2(16)
  field bits<48> Inst;
  field bits<48> SoftFail;

  let Namespace = "MSP430";

  dag OutOperandList = outs;
  dag InOperandList  = ins;

  Format Form = f;
  let Size = sz.Value;

  // Define how we want to layout our TargetSpecific information field... This
  // should be kept up-to-date with the fields in the MSP430InstrInfo.h file.
  let TSFlags{1-0} = Form.Value;
  let TSFlags{4-2} = sz.Value;

  let AsmString   = asmstr;
}

class F2<OpForm2 opc, OpSize bw, SizeVal instSize,
         dag outs, dag ins, string asmstr, list<dag> pattern>
  : MSP430Inst<outs, ins, instSize, SingleOpFrm, asmstr> {

  let Pattern = pattern;
  let Inst{15-7}  = opc.Value;
  let Inst{6}     = bw.Value;
}

// FIXME: Create different classes for different addressing modes.

// MSP430 Double Operand (Format I) Instructions
class IForm<bits<4> opcode, DestMode Ad, bit bw, SourceMode As, SizeVal sz,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : MSP430Inst<outs, ins, sz, DoubleOpFrm, asmstr> {
  let Pattern = pattern;
  
  let Inst{15-12} = opcode;
  let Inst{7}     = Ad.Value;
  let Inst{6}     = bw;
  let Inst{5-4}   = As.Value;
}

// 8 bit IForm instructions
class IForm8<bits<4> opcode, DestMode Ad, SourceMode As, SizeVal sz,
             dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm<opcode, Ad, 1, As, sz, outs, ins, asmstr, pattern>;

class I8rr<bits<4> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm8<opcode, DstReg, SrcReg, Size2Bytes, outs, ins, asmstr, pattern>;

class I8ri<bits<4> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm8<opcode, DstReg, SrcImm, Size4Bytes, outs, ins, asmstr, pattern>;

class I8rm<bits<4> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm8<opcode, DstReg, SrcMem, Size4Bytes, outs, ins, asmstr, pattern>;

class I8mr<bits<4> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm8<opcode, DstMem, SrcReg, Size4Bytes, outs, ins, asmstr, pattern>;

class I8mi<bits<4> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm8<opcode, DstMem, SrcImm, Size6Bytes, outs, ins, asmstr, pattern>;

class I8mm<bits<4> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm8<opcode, DstMem, SrcMem, Size6Bytes, outs, ins, asmstr, pattern>;

// 16 bit IForm instructions
class IForm16<bits<4> opcode, DestMode Ad, SourceMode As, SizeVal sz,
              dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm<opcode, Ad, 0, As, sz, outs, ins, asmstr, pattern>;

class I16rr<bits<4> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm16<opcode, DstReg, SrcReg, Size2Bytes, outs, ins, asmstr, pattern>;

class I16ri<bits<4> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm16<opcode, DstReg, SrcImm, Size4Bytes, outs, ins, asmstr, pattern>;

class I16rm<bits<4> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm16<opcode, DstReg, SrcMem, Size4Bytes, outs, ins, asmstr, pattern>;

class I16mr<bits<4> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm16<opcode, DstMem, SrcReg, Size4Bytes, outs, ins, asmstr, pattern>;

class I16mi<bits<4> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm16<opcode, DstMem, SrcImm, Size6Bytes, outs, ins, asmstr, pattern>;

class I16mm<bits<4> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IForm16<opcode, DstMem, SrcMem, Size6Bytes, outs, ins, asmstr, pattern>;

// MSP430 Single Operand (Format II) Instructions
class IIForm<bits<9> opcode, bit bw, SourceMode As, SizeVal sz,
             dag outs, dag ins, string asmstr, list<dag> pattern>
  : MSP430Inst<outs, ins, sz, SingleOpFrm, asmstr> {
  let Pattern = pattern;
  
  //SourceMode as = src;

  let Inst{15-7} = opcode;
  let Inst{6}    = bw;
  let Inst{5-4}  = As.Value;
}

// 8 bit IIForm instructions
class IIForm8<bits<9> opcode, SourceMode As, SizeVal sz,
              dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm<opcode, 1, As, sz, outs, ins, asmstr, pattern>;

class II8r<bits<9> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm8<opcode, SrcReg, Size2Bytes, outs, ins, asmstr, pattern>;

class II8m<bits<9> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm8<opcode, SrcMem, Size4Bytes, outs, ins, asmstr, pattern>;

class II8i<bits<9> opcode,
           dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm8<opcode, SrcImm, Size4Bytes, outs, ins, asmstr, pattern>;

// 16 bit IIForm instructions
class IIForm16<bits<9> opcode, SourceMode As, SizeVal sz,
               dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm<opcode, 0, As, sz, outs, ins, asmstr, pattern>;

class II16r<bits<9> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm16<opcode, SrcReg, Size2Bytes, outs, ins, asmstr, pattern>;

class II16m<bits<9> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm16<opcode, SrcMem, Size4Bytes, outs, ins, asmstr, pattern>;

class II16i<bits<9> opcode,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : IIForm16<opcode, SrcImm, Size4Bytes, outs, ins, asmstr, pattern>;

// MSP430 Conditional Jumps Instructions
class CJForm<bits<3> opcode, bits<3> cond,
             dag outs, dag ins, string asmstr, list<dag> pattern>
  : MSP430Inst<outs, ins, Size2Bytes, CondJumpFrm, asmstr> {
  let Pattern = pattern;
  
  let Inst{15-13} = opcode;
  //let Inst{12-10} = cond;
}

// MSP430 Constant Generator instruction uses.
class CGForm<bits<4> opcode, DestMode Ad, bit bw, CGVal As, SizeVal sz,
            dag outs, dag ins, string asmstr, list<dag> pattern>
  : MSP430Inst<outs, ins, sz, DoubleOpFrm, asmstr> {
  let Pattern = pattern;
  
  let Inst{15-12} = opcode;
  let Inst{7}     = Ad.Value;
  let Inst{6}     = bw;
  let Inst{5-4}   = As.Value;
}

// 8 bit CGForm instructions
class CGForm8<bits<4> opcode, DestMode Ad, CGVal As, SizeVal sz,
             dag outs, dag ins, string asmstr, list<dag> pattern>
  : CGForm<opcode, Ad, 1, As, sz, outs, ins, asmstr, pattern>;

// 16 bit CGForm instructions
class CGForm16<bits<4> opcode, DestMode Ad, CGVal As, SizeVal sz,
             dag outs, dag ins, string asmstr, list<dag> pattern>
  : CGForm<opcode, Ad, 0, As, sz, outs, ins, asmstr, pattern>;


// Pseudo instructions
class Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
  : MSP430Inst<outs, ins, SizeSpecial, PseudoFrm, asmstr> {
  let isCodeGenOnly = 1;
  let Pattern = pattern;
  let Inst{15-0} = 0;
}
