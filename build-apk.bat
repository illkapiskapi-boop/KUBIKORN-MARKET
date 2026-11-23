@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM Launch a persistent CMD window when started by double-click.
if /i not "%~1"=="__KUBIKORN_APK_RUN__" (
    start "KUBIKORN_MARKET APK Builder" "%ComSpec%" /k ""%~f0" __KUBIKORN_APK_RUN__"
    exit /b
)
shift
cd /d "%~dp0"
title KUBIKORN_MARKET - Android APK Builder
color 0D

if not exist "build-output" mkdir "build-output"
set "BUILD_LOG=%~dp0build-output\apk-build.log"
>"%BUILD_LOG%" echo KUBIKORN_MARKET Android build log
>>"%BUILD_LOG%" echo Started: %DATE% %TIME%

cls
echo ============================================================
echo             KUBIKORN_MARKET - ANDROID APK
echo                  NATIVE KOTLIN BUILDER
echo ============================================================
echo.
echo This project uses Kotlin + Android WebView. No Flutter.
echo This window will stay open if any command fails.
echo.
echo Build log: %BUILD_LOG%
echo.

REM Prefer Temurin JDK 21, then JAVA_HOME, then Android Studio JBR.
set "SELECTED_JDK="
for /d %%D in ("%ProgramFiles%\Eclipse Adoptium\jdk-21*") do if not defined SELECTED_JDK if exist "%%~fD\bin\java.exe" set "SELECTED_JDK=%%~fD"
if not defined SELECTED_JDK if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "SELECTED_JDK=%JAVA_HOME%"
if not defined SELECTED_JDK if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" set "SELECTED_JDK=%ProgramFiles%\Android\Android Studio\jbr"
if not defined SELECTED_JDK if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\Programs\Android Studio\jbr\bin\java.exe" set "SELECTED_JDK=%LOCALAPPDATA%\Programs\Android Studio\jbr"

if not defined SELECTED_JDK (
    echo [ERROR] Java JDK was not found.
    echo Install JDK 21, or set JAVA_HOME to a JDK 17-23 folder.
    >>"%BUILD_LOG%" echo ERROR: Java JDK was not found.
    goto :failed
)
if not exist "%SELECTED_JDK%\bin\java.exe" (
    echo [ERROR] java.exe was not found in:
    echo %SELECTED_JDK%
    >>"%BUILD_LOG%" echo ERROR: java.exe missing from selected JDK.
    goto :failed
)
set "JAVA_HOME=%SELECTED_JDK%"
set "PATH=%JAVA_HOME%\bin;%PATH%"

REM Read java -version into a file. Avoid FOR /F parsing a dotted version
REM as a filename: that caused the previous "unexpected .." CMD error.
set "JAVA_VERSION="
set "JAVA_MAJOR="
set "JAVA_VERSION_FILE=%TEMP%\kubikorn-java-version.txt"
"%JAVA_HOME%\bin\java.exe" -version > "%JAVA_VERSION_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] The selected Java executable could not start.
    type "%JAVA_VERSION_FILE%"
    >>"%BUILD_LOG%" echo ERROR: Java executable failed.
    goto :failed
)
echo [1/4] Checking Java version...
type "%JAVA_VERSION_FILE%"
type "%JAVA_VERSION_FILE%" >>"%BUILD_LOG%"
for /f "usebackq tokens=3" %%V in ("%JAVA_VERSION_FILE%") do if not defined JAVA_VERSION set "JAVA_VERSION=%%~V"
if not defined JAVA_VERSION (
    echo [ERROR] Could not read the Java version string.
    >>"%BUILD_LOG%" echo ERROR: Could not parse Java version string.
    goto :failed
)

REM The first two characters are the major version for Java 17+.
REM Legacy Java 8 prints 1.8.x, so detect the dot and read the first char.
set "JAVA_MAJOR=%JAVA_VERSION:~0,2%"
if "%JAVA_VERSION:~1,1%"=="." set "JAVA_MAJOR=%JAVA_VERSION:~0,1%"

if %JAVA_MAJOR% LSS 17 (
    echo [ERROR] Java %JAVA_MAJOR% is too old. Install JDK 17-23; JDK 21 is recommended.
    >>"%BUILD_LOG%" echo ERROR: Java %JAVA_MAJOR% is too old.
    goto :failed
)
if %JAVA_MAJOR% GTR 23 (
    echo [ERROR] Java %JAVA_MAJOR% is too new for this Gradle build. Install JDK 21.
    >>"%BUILD_LOG%" echo ERROR: Java %JAVA_MAJOR% is too new.
    goto :failed
)
echo [OK] Selected JDK %JAVA_MAJOR%: %JAVA_HOME%

REM Locate Android SDK.
echo.
echo [2/4] Checking Android SDK...
if not defined ANDROID_HOME if defined ANDROID_SDK_ROOT set "ANDROID_HOME=%ANDROID_SDK_ROOT%"
if not defined ANDROID_HOME if defined LOCALAPPDATA set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
if not defined ANDROID_HOME (
    echo [ERROR] Android SDK path was not found.
    echo Set ANDROID_HOME or install the SDK through Android Studio - SDK Manager.
    >>"%BUILD_LOG%" echo ERROR: Android SDK path was not found.
    goto :failed
)
if not exist "%ANDROID_HOME%\platforms\android-35\android.jar" (
    echo [ERROR] Android SDK Platform 35 is missing:
    echo %ANDROID_HOME%\platforms\android-35
    echo Install Android 15 / API 35 in Android Studio - SDK Manager.
    >>"%BUILD_LOG%" echo ERROR: Android SDK Platform 35 is missing.
    goto :failed
)
if not exist "%ANDROID_HOME%\build-tools\35.0.0\aapt.exe" (
    echo [ERROR] Android SDK Build-Tools 35.0.0 are missing.
    echo Install Android SDK Build-Tools 35.0.0 in SDK Manager.
    >>"%BUILD_LOG%" echo ERROR: Android SDK Build-Tools 35.0.0 are missing.
    goto :failed
)
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
echo [OK] Android SDK: %ANDROID_HOME%

REM Download a local Gradle distribution if it is not already available.
echo.
echo [3/4] Checking Gradle 8.10.2...
set "TOOLS_DIR=%USERPROFILE%\.kubikorn-tools"
set "GRADLE_HOME=%TOOLS_DIR%\gradle-8.10.2"
if not exist "%GRADLE_HOME%\bin\gradle.bat" (
    echo [INFO] Downloading Gradle 8.10.2. First run can take several minutes...
    if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $base=Join-Path $env:USERPROFILE '.kubikorn-tools'; $zip=Join-Path $base 'gradle-8.10.2-bin.zip'; Invoke-WebRequest -Uri 'https://services.gradle.org/distributions/gradle-8.10.2-bin.zip' -OutFile $zip; Expand-Archive -LiteralPath $zip -DestinationPath $base -Force; Remove-Item -LiteralPath $zip -Force; if (!(Test-Path (Join-Path $base 'gradle-8.10.2\bin\gradle.bat'))) { throw 'Gradle executable was not extracted.' }"
    if errorlevel 1 (
        echo [ERROR] Gradle download or extraction failed.
        >>"%BUILD_LOG%" echo ERROR: Gradle download or extraction failed.
        goto :failed
    )
)

if not exist "%~dp0android\settings.gradle.kts" (
    echo [ERROR] Android project files are missing. Run this BAT from the extracted project root.
    >>"%BUILD_LOG%" echo ERROR: android\settings.gradle.kts not found.
    goto :failed
)

echo.
echo [4/4] Building the Android debug APK...
echo Gradle output is being written to the build log.
echo.
call "%GRADLE_HOME%\bin\gradle.bat" --no-daemon --console=plain --stacktrace -p "%~dp0android" :app:assembleDebug >> "%BUILD_LOG%" 2>&1
set "GRADLE_EXIT=%ERRORLEVEL%"
type "%BUILD_LOG%"
if not "%GRADLE_EXIT%"=="0" (
    echo [ERROR] Gradle build failed with exit code %GRADLE_EXIT%.
    goto :failed
)

if not exist "%~dp0android\app\build\outputs\apk\debug\app-debug.apk" (
    echo [ERROR] Gradle returned success but APK was not found.
    >>"%BUILD_LOG%" echo ERROR: APK output missing.
    goto :failed
)
copy /Y "%~dp0android\app\build\outputs\apk\debug\app-debug.apk" "%~dp0build-output\KUBIKORN_MARKET-debug.apk" >nul
if errorlevel 1 (
    echo [ERROR] Could not copy APK to build-output.
    >>"%BUILD_LOG%" echo ERROR: Could not copy APK.
    goto :failed
)

echo.
echo ============================================================
echo             ANDROID APK BUILD SUCCESSFUL
echo ============================================================
echo APK: %~dp0build-output\KUBIKORN_MARKET-debug.apk
echo.
echo This is a debug-signed APK for testing.
echo For public release, configure your own private release keystore.
goto :done

:failed
echo.
echo ============================================================
echo                    APK BUILD FAILED
echo ============================================================
echo The console will remain open. Read the error above.
echo Build log: %BUILD_LOG%

:done
echo.
pause
endlocal
