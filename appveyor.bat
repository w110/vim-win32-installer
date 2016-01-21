@echo off
:: Batch file for building/testing Vim on AppVeyor

cd %APPVEYOR_BUILD_FOLDER%

if /i "%appveyor_repo_tag%"=="false" (
  echo Skip this build.
  exit 0
)

:: ----------------------------------------------------------------------
:: Download URLs and versions
:: Lua
set LUA_VER=53
set LUA32_URL=http://downloads.sourceforge.net/luabinaries/lua-5.3.2_Win32_dllw4_lib.zip
set LUA64_URL=http://downloads.sourceforge.net/luabinaries/lua-5.3.2_Win64_dllw4_lib.zip
:: Perl
set PERL_VER=522
set PERL32_URL=http://downloads.activestate.com/ActivePerl/releases/5.22.0.2200/ActivePerl-5.22.0.2200-MSWin32-x86-64int-299195.zip
set PERL64_URL=http://downloads.activestate.com/ActivePerl/releases/5.22.0.2200/ActivePerl-5.22.0.2200-MSWin32-x64-299195.zip
:: Python2
set PYTHON_VER=27
:: Python3
set PYTHON3_VER=34
:: Racket
set RACKET_VER=3m_9z0ds0
set RACKET32_URL=https://mirror.racket-lang.org/releases/6.3/installers/racket-minimal-6.3-i386-win32.exe
set RACKET64_URL=https://mirror.racket-lang.org/releases/6.3/installers/racket-minimal-6.3-x86_64-win32.exe
set MZSCHEME_VER=%RACKET_VER%
:: Ruby
set RUBY_VER=22
set RUBY_VER_LONG=2.2.0
set RUBY_BRANCH=ruby_2_2
:: Tcl
set TCL_VER_LONG=8.6
set TCL_VER=%TCL_VER_LONG:.=%
set TCL32_URL=http://downloads.activestate.com/ActiveTcl/releases/8.6.4.1/ActiveTcl8.6.4.1.299124-win32-ix86-threaded.exe
set TCL64_URL=http://downloads.activestate.com/ActiveTcl/releases/8.6.4.1/ActiveTcl8.6.4.1.299124-win32-x86_64-threaded.exe
:: Gettext
set GETTEXT32_URL=https://github.com/mlocati/gettext-iconv-windows/releases/download/v0.19.6-v1.14/gettext0.19.6-iconv1.14-shared-32.exe
set GETTEXT64_URL=https://github.com/mlocati/gettext-iconv-windows/releases/download/v0.19.6-v1.14/gettext0.19.6-iconv1.14-shared-64.exe
:: NSIS
set NSIS_URL=http://downloads.sourceforge.net/nsis/nsis-2.50.zip
:: UPX
set UPX_URL=http://upx.sourceforge.net/download/upx391w.zip
:: ----------------------------------------------------------------------

if /I "%1"=="" (
  set target=build
) else (
  set target=%1
)
goto %target%_%ARCH%
echo Unknown build target.
exit 1


:install_x86
:: ----------------------------------------------------------------------
@echo on
:: Work around for Python 2.7.11
reg copy HKLM\SOFTWARE\Python\PythonCore\2.7 HKLM\SOFTWARE\Python\PythonCore\2.7-32 /s /reg:32

:: Get Vim source code
git submodule update --init

:: Lua
curl -f -L %LUA32_URL% -o lua.zip || exit 1
7z x lua.zip -oC:\Lua > nul
:: Perl
curl -f -L %PERL32_URL% -o perl.zip || exit 1
7z x perl.zip -oC:\ > nul
for /d %%i in (C:\ActivePerl*) do move %%i C:\Perl%PERL_VER%
:: Tcl
curl -f -L %TCL32_URL% -o tcl.exe || exit 1
start /wait tcl.exe --directory C:\Tcl
:: Ruby
:: RubyInstaller is built by MinGW, so we cannot use header files from it.
:: Download the source files and generate config.h for MSVC.
git clone https://github.com/ruby/ruby.git -b %RUBY_BRANCH% --depth 1 -q ../ruby
pushd ..\ruby
call win32\configure.bat
echo on
nmake .config.h.time
xcopy /s .ext\include C:\Ruby%RUBY_VER%\include\ruby-%RUBY_VER_LONG%
popd
:: Racket
curl -f -L %RACKET32_URL% -o racket.exe || exit 1
start /wait racket.exe /S

if /i "%appveyor_repo_tag%"=="true" (
  :: Install binary diff.exe and libintl.dll and iconv.dll
  :: curl -f -L -O ftp://ftp.vim.org/pub/vim/pc/gvim74.exe
  :: 7z e gvim74.exe $0\diff.exe -o.
  curl -f -L %GETTEXT32_URL% -o gettext.exe || exit 1
  start /wait gettext.exe /verysilent /dir=c:\gettext
  :: Install NSIS
  curl -f -L %NSIS_URL% -o nsis.zip || exit 1
  7z x nsis.zip -oC:\ > nul
  for /d %%i in (C:\nsis*) do move %%i C:\nsis
  :: Install UPX
  curl -f -L %UPX_URL% -o upx.zip || exit 1
  7z e upx.zip *\upx.exe -ovim\nsis > nul
)

:: Update PATH
path C:\Perl%PERL_VER%\perl\bin;%path%;C:\Lua;C:\Tcl\bin;C:\Ruby%RUBY_VER%\bin;%PROGRAMFILES(X86)%\Racket;%PROGRAMFILES(X86)%\Racket\lib

:: Install additional packages for Racket
raco pkg install --auto r5rs-lib
@echo off
goto :eof


:install_x64
:: ----------------------------------------------------------------------
@echo on
:: Work around for Python 2.7.11
reg copy HKLM\SOFTWARE\Python\PythonCore\2.7 HKLM\SOFTWARE\Python\PythonCore\2.7-32 /s /reg:64

:: Get Vim source code
git submodule update --init

:: Lua
curl -f -L %LUA64_URL% -o lua.zip || exit 1
7z x lua.zip -oC:\Lua > nul
:: Perl
curl -f -L %PERL64_URL% -o perl.zip || exit 1
7z x perl.zip -oC:\ > nul
for /d %%i in (C:\ActivePerl*) do move %%i C:\Perl%PERL_VER%
:: Tcl
curl -f -L %TCL64_URL% -o tcl.exe || exit 1
start /wait tcl.exe --directory C:\Tcl
:: Ruby
:: RubyInstaller is built by MinGW, so we cannot use header files from it.
:: Download the source files and generate config.h for MSVC.
git clone https://github.com/ruby/ruby.git -b %RUBY_BRANCH% --depth 1 -q ../ruby
pushd ..\ruby
call win32\configure.bat
echo on
nmake .config.h.time
xcopy /s .ext\include C:\Ruby%RUBY_VER%-x64\include\ruby-%RUBY_VER_LONG%
popd
:: Racket
curl -f -L %RACKET64_URL% -o racket.exe || exit 1
start /wait racket.exe /S

if /i "%appveyor_repo_tag%"=="true" (
  :: Install binary diff.exe and libintl.dll and iconv.dll
  :: curl -f -L -O ftp://ftp.vim.org/pub/vim/pc/gvim74.exe
  :: 7z e gvim74.exe $0\diff.exe -o.
  curl -f -L %GETTEXT64_URL% -o gettext.exe || exit 1
  start /wait gettext.exe /verysilent /dir=c:\gettext
  :: libwinpthread is needed on Win64 for localizing messages
  ::copy c:\gettext\libwinpthread-1.dll ..\runtime
  :: Install NSIS
  curl -f -L %NSIS_URL% -o nsis.zip || exit 1
  7z x nsis.zip -oC:\ > nul
  for /d %%i in (C:\nsis*) do move %%i C:\nsis
  :: Install UPX
  curl -f -L %UPX_URL% -o upx.zip || exit 1
  7z e upx.zip *\upx.exe -ovim\nsis > nul
)

:: Update PATH
path C:\Perl%PERL_VER%\perl\bin;%path%;C:\Lua;C:\Tcl\bin;C:\Ruby%RUBY_VER%-x64\bin;%PROGRAMFILES%\Racket;%PROGRAMFILES%\Racket\lib

:: Install additional packages for Racket
raco pkg install --auto r5rs-lib
@echo off
goto :eof


:build_x86
:: ----------------------------------------------------------------------
@echo on
cd vim\src
:: Remove progress bar from the build log
sed -e "s/\$(LINKARGS2)/\$(LINKARGS2) | sed -e 's#.*\\\\r.*##'/" Make_mvc.mak > Make_mvc2.mak
:: Build GUI version
nmake -f Make_mvc2.mak ^
	GUI=yes OLE=yes DIRECTX=yes ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	DYNAMIC_PERL=yes PERL=C:\Perl%PERL_VER%\perl ^
	DYNAMIC_PYTHON=yes PYTHON=C:\Python%PYTHON_VER% ^
	DYNAMIC_PYTHON3=yes PYTHON3=C:\Python%PYTHON3_VER% ^
	DYNAMIC_LUA=yes LUA=C:\Lua ^
	DYNAMIC_TCL=yes TCL=C:\Tcl ^
	DYNAMIC_RUBY=yes RUBY=C:\Ruby%RUBY_VER% RUBY_MSVCRT_NAME=msvcrt ^
	DYNAMIC_MZSCHEME=yes "MZSCHEME=%PROGRAMFILES(X86)%\Racket" ^
	WINVER=0x500 ^
	|| exit 1
@if /i "%appveyor_repo_tag%"=="false" goto check_executable
:: Build CUI version
nmake -f Make_mvc2.mak ^
	GUI=no OLE=no DIRECTX=no ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	DYNAMIC_PERL=yes PERL=C:\Perl%PERL_VER%\perl ^
	DYNAMIC_PYTHON=yes PYTHON=C:\Python%PYTHON_VER% ^
	DYNAMIC_PYTHON3=yes PYTHON3=C:\Python%PYTHON3_VER% ^
	DYNAMIC_LUA=yes LUA=C:\Lua ^
	DYNAMIC_TCL=yes TCL=C:\Tcl ^
	DYNAMIC_RUBY=yes RUBY=C:\Ruby%RUBY_VER% RUBY_MSVCRT_NAME=msvcrt ^
	DYNAMIC_MZSCHEME=yes "MZSCHEME=%PROGRAMFILES(X86)%\Racket" ^
	WINVER=0x500 ^
	|| exit 1
:: Build translations
pushd po
nmake -f Make_mvc.mak GETTEXT_PATH=C:\cygwin\bin VIMRUNTIME=..\..\runtime install-all || exit 1
popd
goto check_executable

@echo off
goto :eof


:build_x64
:: ----------------------------------------------------------------------
@echo on
cd vim\src
:: Remove progress bar from the build log
sed -e "s/\$(LINKARGS2)/\$(LINKARGS2) | sed -e 's#.*\\\\r.*##'/" Make_mvc.mak > Make_mvc2.mak
:: Build GUI version
nmake -f Make_mvc2.mak ^
	GUI=yes OLE=yes DIRECTX=yes ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	DYNAMIC_PERL=yes PERL=C:\Perl%PERL_VER%\perl ^
	DYNAMIC_PYTHON=yes PYTHON=C:\Python%PYTHON_VER%-x64 ^
	DYNAMIC_PYTHON3=yes PYTHON3=C:\Python%PYTHON3_VER%-x64 ^
	DYNAMIC_LUA=yes LUA=C:\Lua ^
	DYNAMIC_TCL=yes TCL=C:\Tcl ^
	DYNAMIC_RUBY=yes RUBY=C:\Ruby%RUBY_VER%-x64 RUBY_MSVCRT_NAME=msvcrt ^
	DYNAMIC_MZSCHEME=yes "MZSCHEME=%PROGRAMFILES%\Racket" ^
	WINVER=0x500 ^
	|| exit 1
@if /i "%appveyor_repo_tag%"=="false" goto check_executable
:: Build CUI version
nmake -f Make_mvc2.mak ^
	GUI=no OLE=no DIRECTX=no ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	DYNAMIC_PERL=yes PERL=C:\Perl%PERL_VER%\perl ^
	DYNAMIC_PYTHON=yes PYTHON=C:\Python%PYTHON_VER%-x64 ^
	DYNAMIC_PYTHON3=yes PYTHON3=C:\Python%PYTHON3_VER%-x64 ^
	DYNAMIC_LUA=yes LUA=C:\Lua ^
	DYNAMIC_TCL=yes TCL=C:\Tcl ^
	DYNAMIC_RUBY=yes RUBY=C:\Ruby%RUBY_VER%-x64 RUBY_MSVCRT_NAME=msvcrt ^
	DYNAMIC_MZSCHEME=yes "MZSCHEME=%PROGRAMFILES%\Racket" ^
	WINVER=0x500 ^
	|| exit 1
:: Build translations
pushd po
nmake -f Make_mvc.mak GETTEXT_PATH=C:\cygwin\bin VIMRUNTIME=..\..\runtime install-all || exit 1
popd
goto check_executable


:check_executable
:: ----------------------------------------------------------------------
.\gvim -silent -register
.\gvim -u NONE -c "redir @a | ver | 0put a | wq!" ver.txt
type ver.txt
if /i "%appveyor_repo_tag%"=="true" (
  .\vim --version
)
@echo off
goto :eof


:package_x86
:package_x64
:: ----------------------------------------------------------------------
if /i "%appveyor_repo_tag%"=="false" goto :eof
@echo on
cd vim\src

:: Build both 64- and 32-bit versions of gvimext.dll for the installer
start /wait cmd /c "setenv /x64 && cd GvimExt && nmake clean all"
move GvimExt\gvimext.dll GvimExt\gvimext64.dll
start /wait cmd /c "setenv /x86 && cd GvimExt && nmake clean all"
:: Create zip packages
copy /Y ..\README.txt ..\runtime
copy /Y ..\vimtutor.bat ..\runtime
copy /Y *.exe ..\runtime\
copy /Y xxd\*.exe ..\runtime
copy /Y tee\*.exe ..\runtime
mkdir ..\runtime\GvimExt
copy /Y GvimExt\gvimext*.dll ..\runtime\GvimExt\
copy /Y GvimExt\README.txt   ..\runtime\GvimExt\
copy /Y GvimExt\*.inf        ..\runtime\GvimExt\
copy /Y GvimExt\*.reg        ..\runtime\GvimExt\
copy /Y ..\..\diff.exe ..\runtime\
copy /Y c:\gettext\libiconv*.dll ..\runtime\
copy /Y c:\gettext\libintl-8.dll ..\runtime\
:: libwinpthread is needed on Win64 for localizing messages
if exist c:\gettext\libwinpthread-1.dll copy /Y c:\gettext\libwinpthread-1.dll ..\runtime\
7z a ..\..\gvim_%ARCH%.zip ..\runtime\*

:: Create x86 installer (Skip x64 installer)
if /i "%ARCH%"=="x64" goto :eof
c:\cygwin\bin\bash -lc "cd `cygpath '%APPVEYOR_BUILD_FOLDER%'`/vim/runtime/doc && touch ../../src/auto/config.mk && make uganda.nsis.txt"
copy gvim.exe gvim_ole.exe
copy vim.exe vimw32.exe
copy xxd\xxd.exe xxdw32.exe
copy install.exe installw32.exe
copy uninstal.exe uninstalw32.exe
pushd ..\nsis && c:\nsis\makensis /DVIMRT=..\runtime gvim.nsi "/XOutFile ..\..\gvim_%ARCH%.exe" && popd

@echo off
goto :eof


:test_x86
:test_x64
:: ----------------------------------------------------------------------
@echo on
cd vim\src\testdir
nmake -f Make_dos.mak VIMPROG=..\gvim || exit 1
if /i "%appveyor_repo_tag%"=="true" (
  nmake -f Make_dos.mak clean
  nmake -f Make_dos.mak VIMPROG=..\vim || exit 1
)

@echo off
goto :eof
