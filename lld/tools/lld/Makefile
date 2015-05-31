##===------- lld/Makefile --------------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===--------------------------------------------------------------------===##

LLD_LEVEL := ../..

TOOLNAME = lld

# No plugins, optimize startup time.
TOOL_NO_EXPORTS = 1

#include /Makefile.config
LEVEL := $(LLD_LEVEL)/../..
include $(LEVEL)/Makefile.config

LINK_COMPONENTS := $(TARGETS_TO_BUILD)
USEDLIBS = lldDriver.a \
lldCOFF.a \
LLVMSupport.a \
LLVMAArch64CodeGen.a \
LLVMAArch64AsmParser.a \
LLVMAArch64Disassembler.a \
LLVMAArch64Desc.a \
LLVMAArch64AsmPrinter.a \
LLVMAArch64Info.a \
LLVMAArch64Utils.a \
LLVMAMDGPUCodeGen.a \
LLVMAMDGPUAsmParser.a \
LLVMAMDGPUUtils.a \
LLVMAMDGPUDesc.a \
LLVMAMDGPUAsmPrinter.a \
LLVMAMDGPUInfo.a \
LLVMARMCodeGen.a \
LLVMARMAsmParser.a \
LLVMARMDisassembler.a \
LLVMARMDesc.a \
LLVMARMAsmPrinter.a \
LLVMARMInfo.a \
LLVMBPFCodeGen.a \
LLVMBPFDesc.a \
LLVMBPFAsmPrinter.a \
LLVMBPFInfo.a \
LLVMCppBackendCodeGen.a \
LLVMCppBackendInfo.a \
LLVMHexagonCodeGen.a \
LLVMHexagonDisassembler.a \
LLVMHexagonDesc.a \
LLVMHexagonInfo.a \
LLVMMipsCodeGen.a \
LLVMMipsAsmParser.a \
LLVMMipsDesc.a \
LLVMMipsAsmPrinter.a \
LLVMMipsDisassembler.a \
LLVMMipsInfo.a \
LLVMMSP430CodeGen.a \
LLVMMSP430Desc.a \
LLVMMSP430AsmPrinter.a \
LLVMMSP430Info.a \
LLVMNVPTXCodeGen.a \
LLVMNVPTXDesc.a \
LLVMNVPTXAsmPrinter.a \
LLVMNVPTXInfo.a \
LLVMPowerPCCodeGen.a \
LLVMPowerPCAsmParser.a \
LLVMPowerPCDesc.a \
LLVMPowerPCAsmPrinter.a \
LLVMPowerPCDisassembler.a \
LLVMPowerPCInfo.a \
LLVMSparcCodeGen.a \
LLVMSparcAsmParser.a \
LLVMSparcDesc.a \
LLVMSparcAsmPrinter.a \
LLVMSparcDisassembler.a \
LLVMSparcInfo.a \
LLVMSystemZCodeGen.a \
LLVMSystemZAsmParser.a \
LLVMSystemZDisassembler.a \
LLVMSystemZDesc.a \
LLVMSystemZAsmPrinter.a \
LLVMSystemZInfo.a \
LLVMX86AsmParser.a \
LLVMX86CodeGen.a \
LLVMX86Desc.a \
LLVMX86AsmPrinter.a \
LLVMX86Utils.a \
LLVMX86Disassembler.a \
LLVMX86Info.a \
LLVMXCoreCodeGen.a \
LLVMAsmPrinter.a \
LLVMSelectionDAG.a \
LLVMXCoreDesc.a \
LLVMXCoreAsmPrinter.a \
LLVMXCoreDisassembler.a \
LLVMXCoreInfo.a \
LLVMLTO.a \
LLVMCodeGen.a \
LLVMInstrumentation.a \
LLVMipo.a \
LLVMScalarOpts.a \
LLVMProfileData.a \
LLVMVectorize.a \
LLVMBitWriter.a \
LLVMInstCombine.a \
LLVMLinker.a \
LLVMObjCARCOpts.a \
LLVMTransformUtils.a \
LLVMLibDriver.a \
LLVMMCDisassembler.a \
LLVMTarget.a \
LLVMAnalysis.a \
lldConfig.a \
lldMachO.a \
lldELF2.a \
lldAArch64ELFTarget.a \
lldAMDGPUELFTarget.a \
lldARMELFTarget.a \
lldHexagonELFTarget.a \
lldMipsELFTarget.a \
lldX86ELFTarget.a \
lldExampleSubTarget.a \
lldX86_64ELFTarget.a \
lldELF.a \
lldReaderWriter.a \
lldYAML.a \
lldCore.a \
LLVMObject.a \
LLVMBitReader.a \
LLVMCore.a \
LLVMMCParser.a \
LLVMMC.a \
LLVMOption.a \
LLVMSupport.a

include $(LLD_LEVEL)/Makefile
