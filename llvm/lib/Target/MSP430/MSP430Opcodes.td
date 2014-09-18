//===-- MSP430Opcodes.td - MSP430 Opcodes for tablegen -- -*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===---------------------------------------------------------------------===//

// Format 1 opcodes.

class OpForm1<bits<4> val> {
  bits<4> Value = val;
}

def OpMOV : OpForm1< 4>;
def OpADD : OpForm1< 5>;
def OpADC : OpForm1< 6>;
def OpSBC : OpForm1< 7>;
def OpSUB : OpForm1< 8>;
def OpCMP : OpForm1< 9>;
def OpDAD : OpForm1<10>;
def OpBIT : OpForm1<11>;
def OpBIC : OpForm1<12>;
def OpBIS : OpForm1<13>;
def OpXOR : OpForm1<14>;
def OpAND : OpForm1<15>;

// Format 2

class OpForm2<bits<9> val> {
  bits<9> Value = val;
}

def OpRRC : OpForm2<0b000100000>;
def OpSWP : OpForm2<0b000100001>;
def OpRRA : OpForm2<0b000100010>;
def OpSXT : OpForm2<0b000100011>;
def OpPSH : OpForm2<0b000100100>;
def OpCLL : OpForm2<0b000100101>;
def OpRTI : OpForm2<0b000100110>;

// Format 3 has only one three-bit value == 0b001.

class OpForm3<bits<3> val>;
def OpJXX :  OpForm3<0b001>;
