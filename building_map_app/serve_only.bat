@echo off
chcp 65001 >nul
REM 기존 프로덕션 빌드를 서버로 실행 (빌드 스킵)
REM 사용법: serve_only.bat

echo ========================================
echo   EZStay Server (Build Skip)
echo ========================================
echo.

REM 빌드 디렉토리 확인
if not exist "build\web" (
    echo [ERROR] build\web directory not found
    echo.
    echo Please run build_and_serve.bat first
    pause
    exit /b 1
)

echo [OK] Build directory found

REM serve.json 생성 (SPA 라우팅 설정) - 없는 경우에만
if not exist "build\web\serve.json" (
    (
    echo {
    echo   "public": ".",
    echo   "rewrites": [
    echo     { "source": "**", "destination": "/index.html" }
    echo   ]
    echo }
    ) > "build\web\serve.json"
    echo [OK] SPA routing config created
)
echo.
echo ========================================
echo   Server running at:
echo   http://localhost:3000
echo ========================================
echo.
echo Press Ctrl+C to stop the server
echo.

cd build\web

REM Node.js 서버 우선 (SPA 라우팅 지원)
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [Using Node.js server with SPA routing]
    echo.
    npx serve . -p 3000 --single
) else (
    where python >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo [Using Python server - WARNING: Direct URL access may not work]
        echo.
        python -m http.server 3000
    ) else (
        echo [ERROR] Python or Node.js is not installed
        pause
        exit /b 1
    )
)
