@echo off
chcp 65001 >nul

:: Проверка запуска от администратора
net session >nul 2>&1 || (
    echo Запустите этот скрипт от имени администратора!
	powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "SRC=%APPDATA%\Microsoft\Templates\Normal.dotm"
set "DST=G:\=EXCEL BI - мои проекты\= PQ - база знаний =\Normal_Dot"

:: Создаем папку назначения, если не существует
if not exist "%DST%" mkdir "%DST%"

:: Копируем файл с перезаписью
xcopy "%SRC%" "%DST%\" /Y /Q /C
