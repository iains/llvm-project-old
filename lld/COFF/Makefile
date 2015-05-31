##===- lld/COFF/Makefile -----------------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LLD_LEVEL := ..
LIBRARYNAME := lldCOFF

TABLEGEN_INC_FILES_COMMON = 1

BUILT_SOURCES = Options.inc

include $(LLD_LEVEL)/../../Makefile.config

include $(LLD_LEVEL)/Makefile

$(ObjDir)/Options.inc.tmp : Options.td $(LLVM_TBLGEN) $(ObjDir)/.dir
	$(Echo) "Building LLD COFF Option tables with tblgen"
	$(Verb) $(LLVMTableGen) -gen-opt-parser-defs -o $(call SYSPATH, $@) $<
