##===- lld/ELF2/Makefile -----------------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LLD_LEVEL := ..
LIBRARYNAME := lldELF2

TABLEGEN_INC_FILES_COMMON = 1

BUILT_SOURCES = Options.inc

include $(LLD_LEVEL)/../../Makefile.config

include $(LLD_LEVEL)/Makefile

$(ObjDir)/Options.inc.tmp : Options.td $(LLVM_TBLGEN) $(ObjDir)/.dir
	$(Echo) "Building ELF2 COFF Option tables with tblgen"
	$(Verb) $(LLVMTableGen) -gen-opt-parser-defs -o $(call SYSPATH, $@) $<
