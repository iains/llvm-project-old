//===-- llvm-mc.cpp - Machine Code Hacking Driver ---------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This utility is a simple driver that allows command line hacking on machine
// code.
//
//===----------------------------------------------------------------------===//
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringSwitch.h"

#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCObjectFileInfo.h"
#include "llvm/MC/MCParser/AsmLexer.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSectionMachO.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCTargetOptionsCommandFlags.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Compression.h"
#include "llvm/Support/FileUtilities.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/ToolOutputFile.h"

#include "llvm/Support/Debug.h"
#define DEBUG_TYPE "cl-options"

using namespace llvm;

static cl::opt<std::string>
InputFilename(cl::Positional, cl::desc("<input file>"), cl::init("-"));

static cl::opt<std::string>
OutputFilename("o", cl::desc("Output filename"),
               cl::value_desc("filename"));

static cl::opt<bool>
ShowEncoding("show-encoding", cl::desc("Show instruction encodings"), cl::Hidden);

static cl::opt<DebugCompressionType>
CompressDebugSections("compress-debug-sections", cl::ValueOptional,
  cl::init(DebugCompressionType::DCT_None),
  cl::desc("Choose DWARF debug sections compression:"),
  cl::values(
    clEnumValN(DebugCompressionType::DCT_None, "none",
      "No compression"),
    clEnumValN(DebugCompressionType::DCT_Zlib, "zlib",
      "Use zlib compression"),
    clEnumValN(DebugCompressionType::DCT_ZlibGnu, "zlib-gnu",
      "Use zlib-gnu compression (deprecated)")));

static cl::opt<bool>
ShowInst("show-inst", cl::desc("Show internal instruction representation"), cl::Hidden);

static cl::opt<bool>
ShowInstOperands("show-inst-operands",
                 cl::desc("Show instructions operands as parsed"), cl::Hidden);

static cl::opt<unsigned>
OutputAsmVariant("output-asm-variant",
                 cl::desc("Syntax variant to use for output printing"), cl::Hidden);

static cl::opt<bool>
PrintImmHex("print-imm-hex", cl::init(false),
            cl::desc("Prefer hex format for immediate values"), cl::Hidden);

static cl::list<std::string>
DefineSymbol("defsym", cl::desc("Defines a symbol to be an integer constant"), cl::Hidden);

enum OutputFileType {
  OFT_Null,
  OFT_AssemblyFile,
  OFT_ObjectFile
};

static cl::opt<OutputFileType>
FileType("filetype", cl::init(OFT_ObjectFile),
  cl::desc("Choose an output file type:"),
  cl::values(
       clEnumValN(OFT_AssemblyFile, "asm",
                  "Emit an assembly ('.s') file"),
       clEnumValN(OFT_Null, "null",
                  "Don't emit anything (for timing purposes)"),
       clEnumValN(OFT_ObjectFile, "obj",
                  "Emit a native object ('.o') file")));

static cl::opt<std::string>
TripleName("triple", cl::desc("Target triple to assemble for, "
                              "see -version for available targets"),
                              cl::Hidden);

static cl::opt<std::string>
MCPU("mcpu",
     cl::desc("Target a specific cpu type (-mcpu=help for details)"),
     cl::value_desc("cpu-name"), cl::Hidden,
     cl::init(""));

static cl::list<std::string>
MAttrs("mattr",
  cl::CommaSeparated,
  cl::desc("Target specific attributes (-mattr=help for details)"),
  cl::value_desc("a1,+a2,-a3,..."), cl::Hidden);

static cl::opt<llvm::CodeModel::Model>
CMModel("code-model",
        cl::desc("Choose code model"),
        cl::init(CodeModel::Default),
        cl::values(clEnumValN(CodeModel::Default, "default",
                              "Target default code model"),
                   clEnumValN(CodeModel::Small, "small",
                              "Small code model"),
                   clEnumValN(CodeModel::Kernel, "kernel",
                              "Kernel code model"),
                   clEnumValN(CodeModel::Medium, "medium",
                              "Medium code model"),
                   clEnumValN(CodeModel::Large, "large",
                              "Large code model")));

static cl::opt<std::string>
DebugCompilationDir("fdebug-compilation-dir",
                    cl::desc("Specifies the debug info's compilation dir"),
                    cl::Hidden);

static cl::opt<std::string>
MainFileName("main-file-name",
             cl::desc("Specifies the name we should consider the input file"),
             cl::Hidden);

static cl::opt<bool> SaveTempLabels("save-temp-labels",
                                    cl::desc("Don't discard temporary labels"));

static cl::opt<bool> NoExecStack("no-exec-stack",
                                 cl::desc("File doesn't need an exec stack"),
                                 cl::Hidden);

enum ActionType {
  AC_AsLex,
  AC_Assemble
};

static cl::opt<ActionType>
Action(cl::desc("Action to perform:"),
       cl::init(AC_Assemble),
       cl::values(clEnumValN(AC_AsLex, "as-lex",
                             "Lex tokens from a .s file"),
                  clEnumValN(AC_Assemble, "assemble",
                             "Assemble a .s file (default)")));

// cctools options.

static cl::opt<std::string>
MacOSVersionMin("mmacosx-version-min",
                cl::desc("Version of MacOS X to target."));

static cl::list<std::string>
IncludeDirs("I", cl::desc("Directory of include files"),
            cl::value_desc("directory"), cl::Prefix);

static cl::opt<std::string>
ArchName("arch", cl::desc("Target arch to assemble for, "
                          "see -version for available targets"));

static cl::opt<bool>
NoInitialTextSection("n", cl::desc("Don't assume assembly file starts "
                                   "in the text section"), cl::init(false));

static cl::opt<bool>
GenDwarfForAssembly("g", cl::desc("Generate dwarf debugging info for assembly "
                                  "source files"), cl::init(false));

enum RelocStyle {
  RS_Dynamic,
  RS_Static
};

static cl::opt<RelocStyle>
RelocMode(cl::desc("Relocation style :"),
          cl::init(RS_Dynamic),
          cl::values(clEnumValN(RS_Dynamic, "dynamic",
                             "enable dynamic linking features"
                             " [cctools assembler option] (default)"),
                     clEnumValN(RS_Static, "static",
                             "error on dynamic linking features"
                             " [cctools assembler option]")));

// This is supposed to signal that the input assembly doesn't need 'assembler
// pre-processing', which (probably) only really has meaning to the GNU
// assembler.
static cl::opt<bool>
NoApp("f", cl::desc("don't use the assembler pre-procesor"
                    " [cctools assembler option]"), cl::init(false), cl::ZeroOrMore);

static cl::opt<bool>
ForceAll("force_cpusubtype_ALL",
          cl::desc("allow instructions for any CPU variant"), cl::ZeroOrMore);

enum AssemblerStyle {
  AS_LLVM,
  AS_CCTOOLS
};

static cl::opt<AssemblerStyle>
AssemblerBackEnd(cl::desc(" Use the assembler provided by:"),
          cl::init(AS_LLVM),
          cl::values(clEnumValN(AS_LLVM, "q",
                             "LLVM (default)"),
                     clEnumValN(AS_CCTOOLS, "Q",
                             "cctools")));

// FIXME: this should do something...
static cl::opt<bool>
ArchMultiple("arch_multiple", cl::desc("identify the arch in messages"),
             cl::init(false));

static cl::opt<bool>
ShowVersV("v", cl::desc("show version info and carry on with assembly"), cl::ZeroOrMore );

// FIXME: this should do something...
static cl::opt<bool>
ShowInvocation("V", cl::desc("show the actual assembler invocation"), cl::ZeroOrMore);

cl::alias SaveLocals("L", cl::desc("Alias for -save-temp-labels"),
                     cl::aliasopt(SaveTempLabels), cl::ZeroOrMore);

// Stolen from Triple.cpp
static unsigned EatNumber(StringRef &Str) {
  assert(!Str.empty() && Str[0] >= '0' && Str[0] <= '9' && "Not a number");
  unsigned Result = 0;
  do {
    // Consume the leading digit.
    Result = Result*10 + (Str[0] - '0');
    // Eat the digit.
    Str = Str.substr(1);
  } while (!Str.empty() && Str[0] >= '0' && Str[0] <= '9');
  return Result;
}

static const Target *GetTarget(const char *ProgName) {
  // Figure out the target triple.
  if (TripleName.empty())
    TripleName = sys::getDefaultTargetTriple();

  Triple TheTriple(Triple::normalize(TripleName));

  if (TheTriple.isMacOSX() && !ArchName.empty()) {
    // Translate Darwin -arch names into the ones used by the LLVM back-end
    // splitting it into arch + MCPU.
    // Command line MCPU settings can be over-ridden by .machine directives.
    std::pair<const char *, const char *> Trans = 
      StringSwitch<std::pair<const char *, const char *>>(ArchName)
      .Case(   "i386", std::make_pair("x86", "i386"))
      .Case(   "i686", std::make_pair("x86", "i686"))
      .Case( "x86_64", std::make_pair("x86-64", ""))
      .Case("x86_64h", std::make_pair("x86-64", ""))
      .Case(  "ppc64", std::make_pair("ppc64", ""))
      .Case( "ppc601", std::make_pair("ppc32", "601"))
      .Case( "ppc602", std::make_pair("ppc32", "602"))
      .Case( "ppc603", std::make_pair("ppc32", "603"))
      .Case( "ppc750", std::make_pair("ppc32", "750"))
      .Case("ppc7400", std::make_pair("ppc32", "7400"))
      .Case("ppc7450", std::make_pair("ppc32", "7450"))
      .Case( "ppc970", std::make_pair("ppc32", "970"))
      .Case(    "ppc", std::make_pair("ppc32", ""))
      .Default(std::make_pair("", ""));

    if (strlen(Trans.second) != 0){
      if (!MCPU.empty() &&  MCPU.compare(Trans.second) != 0)
        errs() << ProgName << ": " << "arch " << ArchName
               << " doesn't agree with " << MCPU << "\n";
      MCPU = Trans.second;
    }
    if (strlen(Trans.first) != 0)
      ArchName = Trans.first;

  }
  // -force_cpusubtype_ALL prevents .machine from overriding the CPU sub-type.
  // It's only relevant for m32 PPC at present.
  if (TheTriple.isMacOSX() && ForceAll) {
    MCPU = "all";
  }
  std::string Error;
  const Target *TheTarget = TargetRegistry::lookupTarget(ArchName, TheTriple,
                                                         Error);
  if (!TheTarget) {
    errs() << ProgName << ": " << Error;
    return nullptr;
  }

  // Update the triple name and return the found target.
  TripleName = TheTriple.getTriple();
  
  if (TheTriple.isMacOSX()) {
    unsigned Major, Minor, Micro;
    if (!MacOSVersionMin.empty()) {
      Major = Minor = Micro = 0;
      unsigned *Components[3] = {&Major, &Minor, &Micro};
      StringRef Vers = MacOSVersionMin;
      for (unsigned i = 0; i != 3; ++i) {
        if (Vers.empty() && i == 2)
          break; // We'll allow a XX.YY without a micro and default that to 0.
        if (Vers.empty()
            || Vers[0] < '0' 
            || Vers[0] > '9') {
          errs() << ProgName 
                 << ": mmacosx-version-min needs a version number of form XX.YY.ZZ\n";
          Major=10;
          Minor=4; // Set a fall-back default.
          break;
        }
        // Consume the leading number.
        *Components[i] = EatNumber(Vers);
        // Consume the separator, if present.
        if (Vers.startswith("."))
          Vers = Vers.substr(1);
      }
DEBUG(dbgs() << ProgName << ": mmacosx-version-min overrode " << TripleName);
    } else {
      TheTriple.getMacOSXVersion(Major, Minor, Micro);
DEBUG(dbgs() << ProgName << ": converted " << TripleName);
    }
    std::string str;
    llvm::raw_string_ostream OS(str);
    OS << "-macosx" << Major << '.' << Minor;
    if (Micro != 0)
    OS << '.' << Micro;
    SmallString<64> NewName;
    NewName += TheTriple.getArchName();
    NewName += "-";
    NewName += TheTriple.getVendorName();
    NewName += OS.str();
DEBUG(dbgs() << " to " << NewName.str() << "\n");
    TripleName = NewName.str();
  }

  return TheTarget;
}

static std::unique_ptr<tool_output_file> GetOutputStream() {
  if (OutputFilename == "")
    OutputFilename = "-";

  std::error_code EC;
  auto Out = llvm::make_unique<tool_output_file>(OutputFilename, EC,
                                                 sys::fs::F_None);
  if (EC) {
    errs() << EC.message() << '\n';
    return nullptr;
  }

  return Out;
}

static std::string DwarfDebugFlags;
static void setDwarfDebugFlags(int argc, char **argv) {
  if (!getenv("RC_DEBUG_OPTIONS"))
    return;
  for (int i = 0; i < argc; i++) {
    DwarfDebugFlags += argv[i];
    if (i + 1 < argc)
      DwarfDebugFlags += " ";
  }
}

static std::string DwarfDebugProducer;
static void setDwarfDebugProducer() {
  if(!getenv("DEBUG_PRODUCER"))
    return;
  DwarfDebugProducer += getenv("DEBUG_PRODUCER");
}

static int AsLexInput(SourceMgr &SrcMgr, MCAsmInfo &MAI,
                      raw_ostream &OS) {

  AsmLexer Lexer(MAI);
  Lexer.setBuffer(SrcMgr.getMemoryBuffer(SrcMgr.getMainFileID())->getBuffer());

  bool Error = false;
  while (Lexer.Lex().isNot(AsmToken::Eof)) {
    AsmToken Tok = Lexer.getTok();

    switch (Tok.getKind()) {
    default:
      SrcMgr.PrintMessage(Lexer.getLoc(), SourceMgr::DK_Warning,
                          "unknown token");
      Error = true;
      break;
    case AsmToken::Error:
      Error = true; // error already printed.
      break;
    case AsmToken::Identifier:
      OS << "identifier: " << Lexer.getTok().getString();
      break;
    case AsmToken::Integer:
      OS << "int: " << Lexer.getTok().getString();
      break;
    case AsmToken::Real:
      OS << "real: " << Lexer.getTok().getString();
      break;
    case AsmToken::String:
      OS << "string: " << Lexer.getTok().getString();
      break;

    case AsmToken::Amp:            OS << "Amp"; break;
    case AsmToken::AmpAmp:         OS << "AmpAmp"; break;
    case AsmToken::At:             OS << "At"; break;
    case AsmToken::Caret:          OS << "Caret"; break;
    case AsmToken::Colon:          OS << "Colon"; break;
    case AsmToken::Comma:          OS << "Comma"; break;
    case AsmToken::Dollar:         OS << "Dollar"; break;
    case AsmToken::Dot:            OS << "Dot"; break;
    case AsmToken::EndOfStatement: OS << "EndOfStatement"; break;
    case AsmToken::Eof:            OS << "Eof"; break;
    case AsmToken::Equal:          OS << "Equal"; break;
    case AsmToken::EqualEqual:     OS << "EqualEqual"; break;
    case AsmToken::Exclaim:        OS << "Exclaim"; break;
    case AsmToken::ExclaimEqual:   OS << "ExclaimEqual"; break;
    case AsmToken::Greater:        OS << "Greater"; break;
    case AsmToken::GreaterEqual:   OS << "GreaterEqual"; break;
    case AsmToken::GreaterGreater: OS << "GreaterGreater"; break;
    case AsmToken::Hash:           OS << "Hash"; break;
    case AsmToken::LBrac:          OS << "LBrac"; break;
    case AsmToken::LCurly:         OS << "LCurly"; break;
    case AsmToken::LParen:         OS << "LParen"; break;
    case AsmToken::Less:           OS << "Less"; break;
    case AsmToken::LessEqual:      OS << "LessEqual"; break;
    case AsmToken::LessGreater:    OS << "LessGreater"; break;
    case AsmToken::LessLess:       OS << "LessLess"; break;
    case AsmToken::Minus:          OS << "Minus"; break;
    case AsmToken::Percent:        OS << "Percent"; break;
    case AsmToken::Pipe:           OS << "Pipe"; break;
    case AsmToken::PipePipe:       OS << "PipePipe"; break;
    case AsmToken::Plus:           OS << "Plus"; break;
    case AsmToken::RBrac:          OS << "RBrac"; break;
    case AsmToken::RCurly:         OS << "RCurly"; break;
    case AsmToken::RParen:         OS << "RParen"; break;
    case AsmToken::Slash:          OS << "Slash"; break;
    case AsmToken::Star:           OS << "Star"; break;
    case AsmToken::Tilde:          OS << "Tilde"; break;
    }

    // Print the token string.
    OS << " (\"";
    OS.write_escaped(Tok.getString());
    OS << "\")\n";
  }

  return Error;
}

static int fillCommandLineSymbols(MCAsmParser &Parser){
  for(auto &I: DefineSymbol){
    auto Pair = StringRef(I).split('=');
    if(Pair.second.empty()){
      errs() << "error: defsym must be of the form: sym=value: " << I;
      return 1;
    }
    int64_t Value;
    if(Pair.second.getAsInteger(0, Value)){
      errs() << "error: Value is not an integer: " << Pair.second;
      return 1;
    }
    auto &Context = Parser.getContext();
    auto Symbol = Context.getOrCreateSymbol(Pair.first);
    Parser.getStreamer().EmitAssignment(Symbol,
                                        MCConstantExpr::create(Value, Context));
  }
  return 0;
}

static int AssembleInput(const char *ProgName, const Target *TheTarget,
                         SourceMgr &SrcMgr, MCContext &Ctx, MCStreamer &Str,
                         MCAsmInfo &MAI, MCSubtargetInfo &STI,
                         MCInstrInfo &MCII, MCTargetOptions &MCOptions) {
  std::unique_ptr<MCAsmParser> Parser(
      createMCAsmParser(SrcMgr, Ctx, Str, MAI));
  std::unique_ptr<MCTargetAsmParser> TAP(
      TheTarget->createMCAsmParser(STI, *Parser, MCII, MCOptions));

  if (!TAP) {
    errs() << ProgName
           << ": error: this target does not support assembly parsing.\n";
    return 1;
  }

  int SymbolResult = fillCommandLineSymbols(*Parser);
  if(SymbolResult)
    return SymbolResult;
  Parser->setShowParsedOperands(ShowInstOperands);
  Parser->setTargetParser(*TAP);

  int Res = Parser->Run(NoInitialTextSection);

  return Res;
}

int main(int argc, char **argv) {
  const char *ProgName = argv[0];
  // Print a stack trace if we signal out.
  sys::PrintStackTraceOnErrorSignal(ProgName);
  PrettyStackTraceProgram X(argc, argv);
  llvm_shutdown_obj Y;  // Call llvm_shutdown() on exit.

  // Initialize targets and assembly printers/parsers.
  llvm::InitializeAllTargetInfos();
  llvm::InitializeAllTargetMCs();
  llvm::InitializeAllAsmParsers();

  // Register the target printer for --version.
  cl::AddExtraVersionPrinter(TargetRegistry::printRegisteredTargetsForVersion);

  cl::ParseCommandLineOptions(argc, argv, "llvm cctools-compatible assembler\n");
  MCTargetOptions MCOptions = InitMCTargetOptionsFromFlags();
  TripleName = Triple::normalize(TripleName);

  setDwarfDebugFlags(argc, argv);
  setDwarfDebugProducer();

  if (AssemblerBackEnd == AS_CCTOOLS) {
    errs() << ProgName << ": cctools mode unimplemented so far, sorry.\n";
    return 1;
  }

  const Target *TheTarget = GetTarget(ProgName);
  if (!TheTarget)
    return 1;

  // Now that GetTarget() has (potentially) replaced TripleName, it's safe to
  // construct the Triple object.
  Triple TheTriple(TripleName);

DEBUG(dbgs() << TheTarget->getName() << " triple named " \
             <<  TripleName << " is OSX " << TheTriple.isMacOSX() \
             << " OS : " << TheTriple.getOS() << "\n");

  ErrorOr<std::unique_ptr<MemoryBuffer>> BufferPtr =
      MemoryBuffer::getFileOrSTDIN(InputFilename);
  if (std::error_code EC = BufferPtr.getError()) {
    errs() << InputFilename << ": " << EC.message() << '\n';
    return 1;
  }
//  MemoryBuffer *Buffer = BufferPtr->get();

  SourceMgr SrcMgr;

  // Tell SrcMgr about this buffer, which is what the parser will pick up.
  SrcMgr.AddNewSourceBuffer(std::move(*BufferPtr), SMLoc());

  // Record the location of the include directories so that the lexer can find
  // it later.
  SrcMgr.setIncludeDirs(IncludeDirs);

  std::unique_ptr<MCRegisterInfo> MRI(TheTarget->createMCRegInfo(TripleName));
  assert(MRI && "Unable to create target register info!");

  std::unique_ptr<MCAsmInfo> MAI(TheTarget->createMCAsmInfo(*MRI, TripleName));
  assert(MAI && "Unable to create target asm info!");

  if (CompressDebugSections != DebugCompressionType::DCT_None) {
    if (!zlib::isAvailable()) {
      errs() << ProgName
             << ": build tools with zlib to enable -compress-debug-sections";
      return 1;
    }
    MAI->setCompressDebugSections(CompressDebugSections);
  }

  // FIXME: This is not pretty. MCContext has a ptr to MCObjectFileInfo and
  // MCObjectFileInfo needs a MCContext reference in order to initialize itself.
  MCObjectFileInfo MOFI;
  MCContext Ctx(MAI.get(), MRI.get(), &MOFI, &SrcMgr);
  Reloc::Model RM = RelocMode == RS_Static ? Reloc::Static : Reloc::PIC_;
  MOFI.InitMCObjectFileInfo(TheTriple, RM, CMModel, Ctx);

  if (SaveTempLabels)
    Ctx.setAllowTemporaryLabels(false);

  Ctx.setGenDwarfForAssembly(GenDwarfForAssembly);
  // Default to 4 for dwarf version.
  unsigned DwarfVersion = MCOptions.DwarfVersion ? MCOptions.DwarfVersion : 4;
  if (DwarfVersion < 2 || DwarfVersion > 4) {
    errs() << ProgName << ": Dwarf version " << DwarfVersion
           << " is not supported." << '\n';
    return 1;
  }

  if(ShowVersV || ShowInvocation) {
    errs() << ProgName << ": cctools-compatible LLVM-based assembler\n";
    cl::PrintVersionMessage();
    errs().flush();
  }

  Ctx.setDwarfVersion(DwarfVersion);
  if (!DwarfDebugFlags.empty())
    Ctx.setDwarfDebugFlags(StringRef(DwarfDebugFlags));
  if (!DwarfDebugProducer.empty())
    Ctx.setDwarfDebugProducer(StringRef(DwarfDebugProducer));
  if (!DebugCompilationDir.empty())
    Ctx.setCompilationDir(DebugCompilationDir);
  if (!MainFileName.empty())
    Ctx.setMainFileName(MainFileName);

  // Package up features to be passed to target/subtarget
  std::string FeaturesStr;
  if (MAttrs.size()) {
    SubtargetFeatures Features;
    for (unsigned i = 0; i != MAttrs.size(); ++i)
      Features.AddFeature(MAttrs[i]);
    FeaturesStr = Features.getString();
  }

  std::unique_ptr<tool_output_file> Out = GetOutputStream();
  if (!Out)
    return 1;

  std::unique_ptr<buffer_ostream> BOS;
  raw_pwrite_stream *OS = &Out->os();
  std::unique_ptr<MCStreamer> Str;

  std::unique_ptr<MCInstrInfo> MCII(TheTarget->createMCInstrInfo());
  std::unique_ptr<MCSubtargetInfo> STI(
      TheTarget->createMCSubtargetInfo(TripleName, MCPU, FeaturesStr));

  MCInstPrinter *IP = nullptr;
  if (FileType == OFT_AssemblyFile) {
    IP = TheTarget->createMCInstPrinter(Triple(TripleName), OutputAsmVariant,
                                        *MAI, *MCII, *MRI);

    // Set the display preference for hex vs. decimal immediates.
    IP->setPrintImmHex(PrintImmHex);

    // Set up the AsmStreamer.
    MCCodeEmitter *CE = nullptr;
    MCAsmBackend *MAB = nullptr;
    if (ShowEncoding) {
      CE = TheTarget->createMCCodeEmitter(*MCII, *MRI, Ctx);
      MAB = TheTarget->createMCAsmBackend(*MRI, TripleName, MCPU, MCOptions);
    }
    auto FOut = llvm::make_unique<formatted_raw_ostream>(*OS);
    Str.reset(TheTarget->createAsmStreamer(
        Ctx, std::move(FOut), /*asmverbose*/ true,
        /*useDwarfDirectory*/ true, IP, CE, MAB, ShowInst));

  } else if (FileType == OFT_Null) {
    Str.reset(TheTarget->createNullStreamer(Ctx));
  } else {
    assert(FileType == OFT_ObjectFile && "Invalid file type!");

    // Don't waste memory on names of temp labels.
    Ctx.setUseNamesOnTempLabels(false);

    if (!Out->os().supportsSeeking()) {
      BOS = make_unique<buffer_ostream>(Out->os());
      OS = BOS.get();
    }

    MCCodeEmitter *CE = TheTarget->createMCCodeEmitter(*MCII, *MRI, Ctx);
    MCAsmBackend *MAB = TheTarget->createMCAsmBackend(*MRI, TripleName, MCPU, MCOptions);
    Str.reset(TheTarget->createMCObjectStreamer(
        TheTriple, Ctx, *MAB, *OS, CE, *STI, MCOptions.MCRelaxAll,
        MCOptions.MCIncrementalLinkerCompatible,
        /*DWARFMustBeAtTheEnd*/ false));
    if (NoExecStack)
      Str->InitSections(true);
  }
  
  int Res = 1;
  switch (Action) {
  case AC_AsLex:
    Res = AsLexInput(SrcMgr, *MAI, Out->os());
    break;
  case AC_Assemble:
    Res = AssembleInput(ProgName, TheTarget, SrcMgr, Ctx, *Str, *MAI, *STI,
                        *MCII, MCOptions);
    break;
  }

  // Keep output if no errors.
  if (Res == 0) Out->keep();
  return Res;
}
