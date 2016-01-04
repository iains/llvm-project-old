WHAT
====

This is a collection of branches that contain work-in-progress on the various LLVM projects.

    http://llvm.org
    http://clang.llvm.org
    http://libcxx.llvm.org
    http://libcxxabi.llvm.org
    http://compiler-rt.llvm.org
    http://lldb.llvm.org

The objective is to be able to host toolchains for this project on Darwin9+ (OS X 10.5+), including on powerpc-apple-darwin9.

At present, I'm intending that earlier Darwin (i.e. X86/10.4 or PPC/10.x) would be valid **_targets_** but I'm not trying to **_host_** on them.

If you're interested in hosting on Darwin8 - look at David Fang's stuff (https://github.com/fangism).

Things will get pushed as they are ready (or approximately so).


PRE-REQUISITES
==============

    A  cmake (I've been using 3.4.1 on Darwin9+)
    B  Python 2.7 (I've been using 2.7.11 on Darwin9+)  You'll need to build/obtain Sphinx for documentation support.
    C  A capable C++11 compiler.
  - On Darwin12+ (OS X 10.8) you can use the latest XCode.
  - On Darwin9..11 I'm :
    starting with GCC-5.3 (https://github.com/iains/darwin-gcc-5) built with the system XCode tools, 
    then building modern tool support (https://github.com/iains/darwin-xtools)
    then rebuilding GCC-5.3 using those new tools.
