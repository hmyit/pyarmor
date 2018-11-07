@ECHO OFF
REM
REM Sample script used to distribute obfuscated python scripts with cx_Freeze 5.
REM
REM Before run it, all TODO variables need to set correctly.
REM

SETLOCAL

REM TODO: zip used to update library.zip
SET ZIP=zip
SET PYTHON=C:\Python34\python.exe

REM TODO: Where to find pyarmor.py
SET PYARMOR_PATH=C:\Python34\Lib\site-packages\pyarmor

REM TODO: Absolute path in which all python scripts will be obfuscated
SET SOURCE=D:\projects\pyarmor\src\examples\cx_Freeze

REM TODO: Output path of cx_Freeze
REM       An executable binary file generated by cx_Freeze should be here
SET BUILD_PATH=build\exe.win32-3.4
SET OUTPUT=%SOURCE%\%BUILD_PATH%

REM TODO: Library name, used to archive python scripts in path %OUTPUT%
SET LIBRARYZIP=python34.zip

REM TODO: Entry script filename, must be relative to %SOURCE%
SET ENTRY_NAME=hello
SET ENTRY_SCRIPT=%ENTRY_NAME%.py
SET ENTRY_EXE=%ENTRY_NAME%.exe


REM TODO: output path for saving project config file, and obfuscated scripts
SET PROJECT=D:\projects\pyarmor\src\examples\build-for-freeze

REM TODO: Comment netx line if not to test obfuscated scripts
SET TEST_OBFUSCATED_SCRIPTS=1

REM Check Python
%PYTHON% --version
IF NOT ERRORLEVEL 0 (
  ECHO.
  ECHO Python doesn't work, check value of variable PYTHON
  ECHO.
  GOTO END
)

REM Check Zip
%ZIP% --version > NUL
IF NOT ERRORLEVEL 0 (
  ECHO.
  ECHO Zip doesn't work, check value of variable ZIP
  ECHO.
  GOTO END
)

REM Check Pyarmor
IF NOT EXIST "%PYARMOR_PATH%\pyarmor.py" (
  ECHO.
  ECHO No pyarmor found, check value of variable PYARMOR_PATH
  ECHO.
  GOTO END
)

REM Check Source
IF NOT EXIST "%SOURCE%" (
  ECHO.
  ECHO No %SOURCE% found, check value of variable SOURCE
  ECHO.
  GOTO END
)

REM Check entry script
IF NOT EXIST "%SOURCE%\%ENTRY_SCRIPT%" (
  ECHO.
  ECHO No %ENTRY_SCRIPT% found, check value of variable ENTRY_SCRIPT
  ECHO.
  GOTO END
)

REM Create a project
ECHO.
CD /D %PYARMOR_PATH%
%PYTHON% pyarmor.py init --type=app --src=%SOURCE% --entry=%ENTRY_SCRIPT% %PROJECT%
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

REM Change to project path, there is a convenient script pyarmor.bat
cd /D %PROJECT%

REM This is the key, change default runtime path, otherwise dynamic library _pytransform could not be found
CALL pyarmor.bat config --runtime-path="" --disable-restrict-mode=1 --manifest "global-include *.py, exclude hello.py setup.py pytransform.py, prune build, prune dist"

REM Obfuscate scripts without runtime files, only obfuscated scripts are generated
ECHO.
CALL pyarmor.bat build --no-runtime
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

REM Copy pytransform.py and obfuscated entry script to source
ECHO.
ECHO Copy pytransform.py to %SOURCE%
COPY %PYARMOR_PATH%\pytransform.py %SOURCE%

ECHO Backup original %ENTRY_SCRIPT%
COPY %SOURCE%\%ENTRY_SCRIPT% %ENTRY_SCRIPT%.bak

ECHO Copy obfuscated script %ENTRY_SCRIPT% to %SOURCE%
COPY dist\%ENTRY_SCRIPT% %SOURCE%
ECHO.

REM Run cx_Freeze setup script
SETLOCAL
  ECHO.
  CD /D %SOURCE%
  %PYTHON% setup.py build
  IF NOT ERRORLEVEL 0 GOTO END
  ECHO.
ENDLOCAL

ECHO Restore entry script
MOVE %ENTRY_SCRIPT%.bak %SOURCE%\%ENTRY_SCRIPT%

REM Generate runtime files only
ECHO.
CALL pyarmor.bat build --only-runtime --output %PROJECT%\runtime-files
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

ECHO Copy runtime files to %OUTPUT%
COPY %PROJECT%\runtime-files\* %OUTPUT%

ECHO.
ECHO Compile obfuscated script .py to .pyc
%PYTHON% -m compileall -b dist
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

REM Replace the original python scripts with obfuscated scripts in zip file
SETLOCAL
  ECHO.
  CD dist
  %ZIP% -r %OUTPUT%\%LIBRARYZIP% *.pyc
  IF NOT "%ERRORLEVEL%" == "0" GOTO END
  ECHO.
ENDLOCAL

REM Test obfuscated scripts
IF "%TEST_OBFUSCATED_SCRIPTS%" == "1" (
  ECHO Prepare to run %ENTRY_EXE% with obfuscated scripts
  PAUSE

  CD /D %OUTPUT%
  %ENTRY_EXE%
)

ECHO.
ECHO All the python scripts have been obfuscated in the output path %OUTPUT% successfully.
ECHO.

:END

ENDLOCAL
PAUSE