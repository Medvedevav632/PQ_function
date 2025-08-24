@echo off
chcp 65001
REM ===================================================
REM GitHub CLI: Создание репозитория с заменой remote
REM ===================================================

REM ===== Настройки проекта =====
set "PROJECT_PATH=G:\=EXCEL BI - мои проекты\= PQ - база знаний ="
set "PROJECT_DESCRIPTION=Библиотека функций Power Query"
set "USERNAME=Medvedevav632"
set "REPO_NAME=PQ_function"
set "REPO_VISIBILITY=public"

echo Создание репозитория: %REPO_NAME%
echo Описание: %PROJECT_DESCRIPTION%
echo.

REM ===== Переход в папку проекта =====
if not exist "%PROJECT_PATH%" (
    echo ОШИБКА: Папка проекта не найдена: %PROJECT_PATH%
    pause
    exit /b 1
)

cd /d "%PROJECT_PATH%"

REM ===== Инициализация локального репозитория =====
if not exist ".git" (
    git init                    
    git branch -M main          
    echo Git репозиторий создан
)

REM ===== Создание локальных правил исключения =====

REM Создаем папку .git/info если её нет
if not exist ".git\info" mkdir ".git\info"

REM Добавляем правила в .git/info/exclude (не попадает в репозиторий)
(
echo # Игнорируемые папки
echo Черновики/
echo "= Разное =/"
echo.
echo # Игнорируемые файлы 
echo F.code-workspace
echo *.tmp
echo *.log
echo *.bak
echo ~$*
echo Thumbs.db
echo .DS_Store
echo .gitignore
) > ".git\info\exclude"

echo Правила исключения настроены локально

REM ===== Проверка и настройка git =====
if exist ".git" (
rem удаляет ссылку на удалённый репозиторий origin из локального git-конфига. На сервере репозиторий остается.
    git remote remove origin >nul 2>&1  
rem удаляет из индекса все подготовленные к комиту файлы. На диске файлы остаются.
    git rm -r --cached . >nul 2>&1      
)

REM ===== Создание README.md =====
echo Создание README.md...
(
echo # %REPO_NAME%
echo.
echo %PROJECT_DESCRIPTION%
echo.
echo ## Описание
echo Эта библиотека содержит набор полезных функций для работы с Power Query.
echo.
echo ## Структура проекта
echo - Функции организованы по категориям
echo - Каждая функция содержит примеры использования
echo.
echo ## Установка
echo 1. Скачайте нужные функции
echo 2. Импортируйте в Power Query Editor
echo 3. Используйте в своих проектах
) > README.md

REM ===== Добавление файлов с учетом .gitignore =====
git add .

REM ===== Проверка что будет закоммичено =====
git diff --cached --name-only

REM ===== Коммит =====
git commit -m "feat: Первый коммит - инициализация репозитория
- Добавлен README.md с описанием проекта
- Настроен .gitignore для исключения служебных файлов"

REM ===== Проверка GitHub CLI =====
gh --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ОШИБКА: GitHub CLI не установлен или не доступен
    echo Установите GitHub CLI: https://cli.github.com/
    pause
    exit /b 1
)

REM ===== Создание репозитория на GitHub =====
gh repo create %REPO_NAME% --%REPO_VISIBILITY% --description "%PROJECT_DESCRIPTION%" --source=. --push

if %errorlevel% neq 0 (
    echo ОШИБКА при создании репозитория на GitHub
    pause
    exit /b 1
)

REM ===== Проверка результата =====
echo.
echo ===== РЕЗУЛЬТАТ =====
echo Репозиторий: https://github.com/%USERNAME%/%REPO_NAME%
echo.
echo Remote origins (текущие удаленные адреса):
git remote -v            
echo.
echo Последний коммит:
git log --oneline -1     
echo.
echo ✅ Репозиторий "%REPO_NAME%" успешно создан и загружен на GitHub!

pause