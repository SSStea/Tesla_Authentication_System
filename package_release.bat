@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "TESLA_PACKAGE_ROOT=%~dp0"
set "TESLA_PACKAGE_VERSION=%~1"
if not defined TESLA_PACKAGE_VERSION set "TESLA_PACKAGE_VERSION=1.0.0"

echo(%TESLA_PACKAGE_VERSION%| %SystemRoot%\System32\findstr.exe /R /X "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul
if errorlevel 1 (
    echo [ERROR] Version must use the form major.minor.patch, for example 1.0.0.
    exit /b 1
)

set "TESLA_SOLUTION=%TESLA_PACKAGE_ROOT%projects\gui\TeslaGui.sln"
set "TESLA_RELEASE_ROOT=%TESLA_PACKAGE_ROOT%out\windows\Release"
set "TESLA_DIST_ROOT=%TESLA_PACKAGE_ROOT%dist"
set "TESLA_STAGING_ROOT=%TESLA_DIST_ROOT%\staging"
set "TESLA_INSTALLER_ROOT=%TESLA_DIST_ROOT%\installers"
set "TESLA_INSTALLER_SCRIPT=%TESLA_PACKAGE_ROOT%packaging\AuthenticationSystemInstaller.iss"

call :findBuildTools
if errorlevel 1 exit /b 1

echo [1/4] Initializing the Visual Studio x64 build environment...
call "%TESLA_VS_ROOT%\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64 >nul
if errorlevel 1 (
    echo [ERROR] Failed to initialize the Visual Studio build environment.
    exit /b 1
)
set "TESLA_VC_RUNTIME_ROOT=%VCToolsRedistDir%x64\Microsoft.VC143.CRT"
if not exist "%TESLA_VC_RUNTIME_ROOT%\msvcp140.dll" (
    echo [ERROR] The Visual C++ x64 app-local runtime was not found.
    exit /b 1
)

echo [2/4] Building all GUI applications in Release x64...
"%TESLA_MSBUILD%" "%TESLA_SOLUTION%" /m /t:Rebuild /p:Configuration=Release /p:Platform=x64 /nologo /v:minimal
if errorlevel 1 (
    echo [ERROR] Release build failed.
    exit /b 1
)

call :prepareOutputDirectories
if errorlevel 1 exit /b 1

echo [3/4] Collecting runtime dependencies and compiling installers...
call :packageApplication "manager" "tesla_manager_gui.exe" "Authentication System Manager" "Authentication_System_Manager" "Manager" "{{51B9AE20-83D9-4D7C-BED7-E84CA6907A27}" "pc.ico" "--stage5-smoke-test"
if errorlevel 1 exit /b 1

call :packageApplication "pc_node" "tesla_pc_node_gui.exe" "Authentication System PC Node" "Authentication_System_PC_Node" "PC Node" "{{7D0470C7-D7E4-489F-84BB-3F5E5629BE6D}" "pc.ico" "--stage5-smoke-test"
if errorlevel 1 exit /b 1

call :packageApplication "uav_monitor" "tesla_uav_monitor_gui.exe" "Authentication System UAV Monitor" "Authentication_System_UAV_Monitor" "UAV Monitor" "{{1E50CB80-CF22-49F7-94A3-6D74B94F83F4}" "uav.ico" "--stage5-smoke-test"
if errorlevel 1 exit /b 1

call :packageApplication "attack_test" "tesla_attack_test_gui.exe" "Authentication System Attack Test" "Authentication_System_Attack_Test" "Attack Test" "{{8689BEA3-A7B8-4477-A916-A96CBA5869E7}" "pc_red.ico" "--smoke-test"
if errorlevel 1 exit /b 1

if /I "%TESLA_STAGING_ROOT%"=="%TESLA_PACKAGE_ROOT%dist\staging" (
    if exist "%TESLA_STAGING_ROOT%" rmdir /S /Q "%TESLA_STAGING_ROOT%"
)

echo [4/4] Packaging completed successfully.
echo.
echo Installers:
for %%F in ("%TESLA_INSTALLER_ROOT%\*.exe") do echo   %%~fF
echo.
exit /b 0

:findBuildTools
set "TESLA_VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%TESLA_VSWHERE%" (
    echo [ERROR] Visual Studio Installer vswhere.exe was not found.
    exit /b 1
)

set "TESLA_VS_ROOT="
for /F "usebackq tokens=*" %%I in (`"%TESLA_VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do set "TESLA_VS_ROOT=%%I"
if not defined TESLA_VS_ROOT (
    echo [ERROR] Visual Studio with MSBuild was not found.
    exit /b 1
)

set "TESLA_MSBUILD=%TESLA_VS_ROOT%\MSBuild\Current\Bin\MSBuild.exe"
if not exist "%TESLA_MSBUILD%" (
    echo [ERROR] MSBuild was not found at "%TESLA_MSBUILD%".
    exit /b 1
)

if not defined TESLA_QT_ROOT set "TESLA_QT_ROOT=C:\Qt\6.10.2\msvc2022_64"
set "TESLA_WINDEPLOYQT=%TESLA_QT_ROOT%\bin\windeployqt.exe"
if not exist "%TESLA_WINDEPLOYQT%" (
    echo [ERROR] windeployqt was not found. Set TESLA_QT_ROOT to the Qt MSVC x64 directory.
    exit /b 1
)

if not defined TESLA_OPENSSL_ROOT set "TESLA_OPENSSL_ROOT=C:\Program Files\OpenSSL-Win64"
if not exist "%TESLA_OPENSSL_ROOT%\bin\libcrypto-3-x64.dll" (
    echo [ERROR] OpenSSL x64 was not found. Set TESLA_OPENSSL_ROOT to the OpenSSL directory.
    exit /b 1
)

if not defined TESLA_ISCC set "TESLA_ISCC=%LocalAppData%\Programs\Inno Setup 6\ISCC.exe"
if not exist "%TESLA_ISCC%" set "TESLA_ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist "%TESLA_ISCC%" set "TESLA_ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if not exist "%TESLA_ISCC%" (
    echo [ERROR] Inno Setup 6 was not found. Install JRSoftware.InnoSetup with winget.
    exit /b 1
)

if not exist "%TESLA_INSTALLER_SCRIPT%" (
    echo [ERROR] Installer script was not found at "%TESLA_INSTALLER_SCRIPT%".
    exit /b 1
)

exit /b 0

:prepareOutputDirectories
if /I not "%TESLA_STAGING_ROOT%"=="%TESLA_PACKAGE_ROOT%dist\staging" (
    echo [ERROR] Refusing to clean an unexpected staging directory.
    exit /b 1
)
if /I not "%TESLA_INSTALLER_ROOT%"=="%TESLA_PACKAGE_ROOT%dist\installers" (
    echo [ERROR] Refusing to clean an unexpected installer directory.
    exit /b 1
)

if exist "%TESLA_STAGING_ROOT%" rmdir /S /Q "%TESLA_STAGING_ROOT%"
if exist "%TESLA_INSTALLER_ROOT%" rmdir /S /Q "%TESLA_INSTALLER_ROOT%"
mkdir "%TESLA_STAGING_ROOT%" >nul
mkdir "%TESLA_INSTALLER_ROOT%" >nul
exit /b 0

:packageApplication
set "TESLA_PACKAGE_KEY=%~1"
set "TESLA_PACKAGE_EXE=%~2"
set "TESLA_PACKAGE_NAME=%~3"
set "TESLA_PACKAGE_PREFIX=%~4"
set "TESLA_PACKAGE_FOLDER=%~5"
set "TESLA_PACKAGE_APP_ID=%~6"
set "TESLA_PACKAGE_ICON=%~7"
set "TESLA_PACKAGE_SMOKE_ARGUMENT=%~8"
set "TESLA_PACKAGE_STAGE=%TESLA_STAGING_ROOT%\%TESLA_PACKAGE_KEY%"
set "TESLA_PACKAGE_ICON_PATH=%TESLA_PACKAGE_ROOT%src\gui\resources\icons\%TESLA_PACKAGE_ICON%"
set "TESLA_PACKAGE_OUTPUT=%TESLA_PACKAGE_PREFIX%_Setup_%TESLA_PACKAGE_VERSION%_x64"

echo   - %TESLA_PACKAGE_NAME%
if not exist "%TESLA_RELEASE_ROOT%\%TESLA_PACKAGE_EXE%" (
    echo [ERROR] Release executable was not found: "%TESLA_RELEASE_ROOT%\%TESLA_PACKAGE_EXE%".
    exit /b 1
)
if not exist "%TESLA_PACKAGE_ICON_PATH%" (
    echo [ERROR] Installer icon was not found: "%TESLA_PACKAGE_ICON_PATH%".
    exit /b 1
)

mkdir "%TESLA_PACKAGE_STAGE%" >nul
copy /Y "%TESLA_RELEASE_ROOT%\%TESLA_PACKAGE_EXE%" "%TESLA_PACKAGE_STAGE%\%TESLA_PACKAGE_EXE%" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy %TESLA_PACKAGE_EXE% to the staging directory.
    exit /b 1
)

"%TESLA_WINDEPLOYQT%" --release --no-compiler-runtime --no-translations --openssl-root "%TESLA_OPENSSL_ROOT%" --dir "%TESLA_PACKAGE_STAGE%" "%TESLA_PACKAGE_STAGE%\%TESLA_PACKAGE_EXE%"
if errorlevel 1 (
    echo [ERROR] windeployqt failed for %TESLA_PACKAGE_EXE%.
    exit /b 1
)

copy /Y "%TESLA_VC_RUNTIME_ROOT%\*.dll" "%TESLA_PACKAGE_STAGE%\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy the Visual C++ app-local runtime.
    exit /b 1
)

for %%F in (Qt6Core.dll Qt6Gui.dll Qt6Network.dll Qt6Widgets.dll libcrypto-3-x64.dll libssl-3-x64.dll msvcp140.dll vcruntime140.dll vcruntime140_1.dll) do (
    if not exist "%TESLA_PACKAGE_STAGE%\%%F" (
        echo [ERROR] Required runtime file is missing: %%F.
        exit /b 1
    )
)
if not exist "%TESLA_PACKAGE_STAGE%\platforms\qwindows.dll" (
    echo [ERROR] Required Qt platform plugin is missing: platforms\qwindows.dll.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$prcSmoke = Start-Process -FilePath '%TESLA_PACKAGE_STAGE%\%TESLA_PACKAGE_EXE%' -ArgumentList '%TESLA_PACKAGE_SMOKE_ARGUMENT%' -PassThru -WindowStyle Hidden; if ($prcSmoke.WaitForExit(3000)) { exit $prcSmoke.ExitCode }; Stop-Process -Id $prcSmoke.Id -Force; exit 0"
set "TESLA_SMOKE_EXIT=!ERRORLEVEL!"
if not "!TESLA_SMOKE_EXIT!"=="0" (
    echo [ERROR] Packaged application smoke test failed with exit code !TESLA_SMOKE_EXIT!.
    exit /b 1
)

"%TESLA_ISCC%" /Qp "/O%TESLA_INSTALLER_ROOT%" "/F%TESLA_PACKAGE_OUTPUT%" "/DMyAppName=%TESLA_PACKAGE_NAME%" "/DMyAppVersion=%TESLA_PACKAGE_VERSION%" "/DMyAppId=%TESLA_PACKAGE_APP_ID%" "/DMyAppExe=%TESLA_PACKAGE_EXE%" "/DMyInstallFolder=%TESLA_PACKAGE_FOLDER%" "/DMySourceDir=%TESLA_PACKAGE_STAGE%" "/DMySetupIcon=%TESLA_PACKAGE_ICON_PATH%" "%TESLA_INSTALLER_SCRIPT%"
if errorlevel 1 (
    echo [ERROR] Inno Setup failed for %TESLA_PACKAGE_NAME%.
    exit /b 1
)

if not exist "%TESLA_INSTALLER_ROOT%\%TESLA_PACKAGE_OUTPUT%.exe" (
    echo [ERROR] Expected installer was not generated: %TESLA_PACKAGE_OUTPUT%.exe.
    exit /b 1
)

exit /b 0
