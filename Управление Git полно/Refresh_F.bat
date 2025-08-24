@echo off
chcp 65001

set "PROJECT_PATH=G:\=EXCEL BI - мои проекты\= PQ - база знаний ="
cd /d "%PROJECT_PATH%"

git add F.pq 
git commit -m "Обновил F.pq" 
git push origin main

if %errorlevel% equ 0 (
    echo ✅ Файл F.pq успешно обновлен!
) else (
    echo ❌ Ошибка при обновлении
)

pause