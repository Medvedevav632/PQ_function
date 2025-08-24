@echo off
chcp 65001
rem запускать надо из корневой папки проекта

set "PROJECT_PATH=G:\=EXCEL BI - мои проекты\= PQ - база знаний ="
cd /d "%PROJECT_PATH%"

rem git status                        rem показывает список файлов в репозитории от последнего коммита  
rem git diff --name-status HEAD^ HEAD rem показывает список файлов с изменениями в репозитории от последнего коммита

git add -A
git commit -m "Обновил все файлы" 
git push origin main

if %errorlevel% equ 0 echo ✅ Файлы успешно обновлены! else echo ❌ Ошибка при обновлении

pause