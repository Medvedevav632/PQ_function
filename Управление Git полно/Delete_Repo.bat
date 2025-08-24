@echo off
chcp 65001

REM ===== Настройки =====
set REPO_URL=https://github.com/Medvedevav632/PQ_function

REM ===== Проверка существующего репозитория =====
gh repo view %REPO_URL% >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Репозиторий "%REPO_URL%" не найден на GitHub!
    pause
    exit /b
)

REM ===== Подтверждение удаления =====
echo Вы точно хотите удалить репозиторий "%REPO_URL%" на GitHub?
echo Введите Y для удаления, N для отмены:
set /p CONFIRM=Ваш выбор: 

if /I "%CONFIRM%"=="Y" (
    gh repo delete %REPO_URL% --confirm
    echo Репозиторий "%REPO_NAME%" успешно удалён!
) else (
    echo Удаление отменено.
)

pause
