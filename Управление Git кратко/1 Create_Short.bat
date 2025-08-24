@echo off

REM GitHub CLI: Создание репозитория с заменой удаленного репозитория

chcp 65001                         
set "NAME=Method_2025_2026"               
cd /d "F:\+ Метдразработки 2025-2026"

REM Инициализирует новый локальный Git-репозиторий
git init

REM Переименовывает текущую ветку в main (основная ветка)
git branch -M main

REM Удаляет старый удалённый репозиторий origin (без вывода)
git remote remove origin >nul 2>&1

REM Очищает индекс Git от отслеживания файлов (без вывода)
git rm -r --cached . >nul 2>&1

REM Добавляет в индекс все файлы (новые и изменённые)
git add .                      

REM Создаёт коммит с сообщением "Первый коммит"
git commit -m "Первый коммит"

REM Создаёт приватный репозиторий на GitHub, пушит файлы
gh repo create %NAME% --private --source=. --push

REM Пауза для просмотра результата в консоли
pause        
