@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM Always open a persistent CMD window when started by double-click.
if /i not "%~1"=="__KUBIKORN_IPA_RUN__" (
    start "KUBIKORN_MARKET iOS Builder" "%ComSpec%" /k ""%~f0" __KUBIKORN_IPA_RUN__"
    exit /b
)
shift
cd /d "%~dp0"
title KUBIKORN_MARKET - iOS IPA Builder
color 0D

if not exist "build-output\ios" mkdir "build-output\ios"
set "BUILD_LOG=%~dp0build-output\ios\ipa-build.log"
>"%BUILD_LOG%" echo KUBIKORN_MARKET iOS build log
>>"%BUILD_LOG%" echo Started: %DATE% %TIME%

cls
echo ============================================================
echo              KUBIKORN_MARKET - iOS IPA BUILDER
echo                 WINDOWS / GITHUB MAC RUNNER
echo ============================================================
echo.
echo Windows cannot run Xcode locally. This script starts Xcode on GitHub-hosted macOS.
echo The resulting IPA is unsigned and needs Apple signing before installation.
echo.
echo Log: %BUILD_LOG%
echo.

where gh >nul 2>nul
if errorlevel 1 (
    echo [ERROR] GitHub CLI was not found. Install https://cli.github.com/
    echo Then run: gh auth login
    >>"%BUILD_LOG%" echo ERROR: GitHub CLI was not found.
    goto :failed
)
gh auth status >nul 2>nul
if errorlevel 1 (
    echo [ERROR] GitHub CLI is not logged in. Run: gh auth login
    >>"%BUILD_LOG%" echo ERROR: GitHub CLI not logged in.
    goto :failed
)
echo [OK] GitHub CLI is installed and authorized.

set "REPO=illkapiskapi-boop/KUBIKORN-MARKET"
set /p REPO=GitHub repository [illkapiskapi-boop/KUBIKORN-MARKET]: 
if not defined REPO set "REPO=illkapiskapi-boop/KUBIKORN-MARKET"
set "BRANCH=main"
set /p BRANCH=Branch [main]: 
if not defined BRANCH set "BRANCH=main"

echo.
echo [1/3] Checking workflow ios-unsigned.yml on %REPO% (%BRANCH%)...
REM --yaml is required by current GitHub CLI when --ref is used.
gh workflow view ios-unsigned.yml --repo "%REPO%" --ref "%BRANCH%" --yaml >nul 2>"%TEMP%\kubikorn-gh-workflow-error.txt"
if errorlevel 1 (
    echo [ERROR] Workflow .github/workflows/ios-unsigned.yml was not found or is invalid.
    echo Make sure the project contents, including the hidden .github folder, are committed to %BRANCH%.
    type "%TEMP%\kubikorn-gh-workflow-error.txt"
    >>"%BUILD_LOG%" echo ERROR: Workflow check failed.
    goto :failed
)
echo [OK] iOS workflow found and readable.

echo.
echo [2/3] Starting remote Xcode build...
gh workflow run ios-unsigned.yml --repo "%REPO%" --ref "%BRANCH%"
if errorlevel 1 (
    echo [ERROR] Could not dispatch GitHub workflow.
    goto :failed
)

echo [INFO] Waiting for GitHub to register the run...
timeout /t 5 /nobreak >nul
set "RUN_ID="
for /f "usebackq delims=" %%I in (`gh run list --workflow ios-unsigned.yml --repo "%REPO%" --branch "%BRANCH%" --limit 1 --json databaseId --jq ".[0].databaseId"`) do set "RUN_ID=%%I"
if not defined RUN_ID (
    echo [ERROR] Could not retrieve the workflow run ID.
    goto :failed
)
echo [OK] Workflow run ID: %RUN_ID%

echo.
echo [3/3] Waiting for iOS build to finish...
gh run watch %RUN_ID% --repo "%REPO%" --exit-status
if errorlevel 1 (
    echo [ERROR] Remote Xcode build failed. Open Actions and inspect the job log.
    goto :failed
)

echo.
echo Downloading IPA artifact...
gh run download %RUN_ID% --repo "%REPO%" --name KUBIKORN-MARKET-iOS-Unsigned-IPA --dir "%~dp0build-output\ios"
if errorlevel 1 (
    echo [ERROR] Build completed but the IPA artifact could not be downloaded.
    goto :failed
)

echo.
echo ============================================================
echo                  iOS BUILD SUCCESSFUL
echo ============================================================
echo Unsigned IPA artifact downloaded to: %~dp0build-output\ios
echo It must be signed with your own Apple account before installation.
goto :done

:failed
echo.
echo ============================================================
echo                       BUILD FAILED
echo ============================================================
echo This window will remain open. Read the error above.

goto :done

:done
echo.
pause
endlocal
