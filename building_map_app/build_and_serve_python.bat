@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
REM 프로덕션 빌드 및 서버 실행 스크립트 - Python 버전 (Windows)
REM 사용법: build_and_serve_python.bat

echo ========================================
echo   EZStay Production Build (Python)
echo ========================================
echo.

REM 1. 의존성 업데이트
echo [1/4] Updating dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to update dependencies
    exit /b %ERRORLEVEL%
)
echo [OK] Dependencies updated
echo.

REM 2. 프로덕션 빌드
echo [2/4] Building production bundle...
call flutter build web --release --tree-shake-icons --dart2js-optimization=O4 --no-source-maps
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Production build failed
    exit /b %ERRORLEVEL%
)
echo [OK] Production build completed

REM .env 파일 복사 (API 설정 유지)
if exist ".env" (
    copy /Y ".env" "build\web\.env" >nul 2>&1
    echo [OK] Environment variables copied
) else (
    echo [WARNING] .env file not found - using default API settings
)
echo.

REM 3. 번들 크기 확인
echo [3/4] Checking bundle size...
if exist "build\web\main.dart.js" (
    for %%A in ("build\web\main.dart.js") do (
        set size=%%~zA
        set /a sizeMB=!size! / 1048576
        echo    main.dart.js: !sizeMB! MB
    )
) else (
    echo    main.dart.js not found
)
echo.

REM 4. 로컬 서버 실행 (포트 3000)
echo [4/4] Starting local server on port 3000...

REM build\web 디렉토리 확인
if not exist "build\web" (
    echo [ERROR] build\web directory not found
    echo Please check if the build completed successfully
    pause
    exit /b 1
)

REM 디렉토리 이동
cd build\web
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to change directory to build\web
    pause
    exit /b 1
)

echo [OK] Changed directory to: %CD%
echo.

REM Python 확인 및 서버 실행
where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Found Python, starting server...
    echo.
    echo ========================================
    echo   Server running at:
    echo   http://localhost:3000
    echo ========================================
    echo.
    echo Press Ctrl+C to stop the server
    echo.
    python -m http.server 3000
) else (
    where python3 >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Found Python3, starting server...
        echo.
        echo ========================================
        echo   Server running at:
        echo   http://localhost:3000
        echo ========================================
        echo.
        echo Press Ctrl+C to stop the server
        echo.
        python3 -m http.server 3000
    ) else (
        echo [ERROR] Python is not installed
        echo.
        echo Solutions:
        echo   1. Install Python from https://www.python.org/downloads/
        echo   2. Use Node.js version: build_and_serve.bat
        echo   3. Manually run: cd build\web ^&^& npx serve -p 3000
        pause
        exit /b 1
    )
)
