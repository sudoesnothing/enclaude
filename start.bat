@echo off
REM start.bat — launch an ephemeral enclaude session on Windows.
REM Container is removed on exit. Workspace data persists in Docker volumes.
REM
REM Double-click this file or run it from a terminal.

echo.
echo   [enclaude] Checking Docker...
echo.

docker info >nul 2>&1
if errorlevel 1 (
    echo   Error: Docker is not running.
    echo   Please start Docker Desktop and try again.
    echo.
    pause
    exit /b 1
)

echo   [enclaude] Building and starting container...
echo.

docker compose up -d --build

echo.
echo   ============================================
echo   Enclaude is ready.
echo.
echo   Run 'claude' to start Claude Code.
echo   Run 'exit' to end the session.
echo   ============================================
echo.

docker exec -it enclaude bash

echo.
echo   [enclaude] Session ended. Tearing down container...
echo   [enclaude] (Workspace data is preserved in Docker volumes.)
echo.

docker compose down --remove-orphans
pause
