@echo off
chcp 65001

REM GitHub CLI: Обновление репозитория измененными + удаленными + созданными файлами 

set "PROJECT_PATH=G:\=EXCEL BI - мои проекты\= PQ - база знаний ="
cd /d "%PROJECT_PATH%"

git add -A
git commit -m "Обновил все файлы" 
git push origin master

pause