@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\.."

set "ENGINE="
where docker >nul 2>nul
if not errorlevel 1 set "ENGINE=docker"
if "%ENGINE%"=="" (
  where podman >nul 2>nul
  if not errorlevel 1 set "ENGINE=podman"
)

if "%ENGINE%"=="" (
  echo No container runtime found. Install docker or podman.
  pause
  exit /b 1
)

set "LOG_DIR=logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "TS=%DATE%_%TIME%"
set "TS=%TS: =0%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:.=-%"
set "TS=%TS:,=-%"
set "LOGFILE=%LOG_DIR%\container-menu-%TS%.log"

echo Command log: %LOGFILE%
call :log "Session started (engine: %ENGINE%)"

:main
cls
echo ==== Container Menu ^(%ENGINE%^) ====
echo 1^) Build image
echo 2^) Run image
echo 3^) List Dockerfiles
echo 0^) Exit
set /p MENU=Choice: 

if "%MENU%"=="1" goto build
if "%MENU%"=="2" goto run
if "%MENU%"=="3" goto list
if "%MENU%"=="0" exit /b 0

echo Invalid choice.
pause
goto main

:list
call :log "%ENGINE% (list dockerfiles via dir /b /s images\Dockerfile.*)"
dir /b /s images\Dockerfile.*
pause
goto main

:build
set /a COUNT=0
call :log "dir /b /s images\Dockerfile.*"
for /f "delims=" %%F in ('dir /b /s images\Dockerfile.*') do (
  set /a COUNT+=1
  set "FILE[!COUNT!]=%%F"
  echo !COUNT!^) %%F
)

if "%COUNT%"=="0" (
  echo No Dockerfiles found under images\
  pause
  goto main
)

set /p PICK=Number: 
set "SELECTED=!FILE[%PICK%]!"
if not defined SELECTED (
  echo Invalid selection.
  pause
  goto main
)

for %%A in ("!SELECTED!") do (
  set "VARIANT=%%~xA"
  set "PARENT=%%~dpA"
)
set "VARIANT=!VARIANT:.=!"
for %%B in ("!PARENT:~0,-1!") do set "FAMILY=%%~nxB"
set /a RAND=%RANDOM% %% 9000 + 1000
set "SUGGEST=clone/!FAMILY!-!VARIANT!-!RAND!"

set /p TAG=Image tag [!SUGGEST!]: 
if "%TAG%"=="" set "TAG=!SUGGEST!"

echo Building !SELECTED! as !TAG!
call :log "%ENGINE% build -f \"!SELECTED!\" -t \"!TAG!\" \"!PARENT!\""
%ENGINE% build -f "!SELECTED!" -t "!TAG!" "!PARENT!"
if errorlevel 1 (
  echo Build failed.
) else (
  echo Build completed.
)
pause
goto main

:run
set /a I=0
call :log "%ENGINE% images --format \"{{.Repository}}:{{.Tag}}\""
for /f "delims=" %%F in ('%ENGINE% images --format "{{.Repository}}:{{.Tag}}"') do (
  set /a I+=1
  set "IMG[!I!]=%%F"
  echo !I!^) %%F
)

if "%I%"=="0" (
  echo No local images found. Build an image first.
  pause
  goto main
)

set /p CHOICE=Number (or type image directly): 
set "IMAGE=!IMG[%CHOICE%]!"
if not defined IMAGE set "IMAGE=%CHOICE%"
if "%IMAGE%"=="" (
  echo Invalid image.
  pause
  goto main
)

set /a RAND=%RANDOM% %% 9000 + 1000
set "DEFNAME=rpi-!RAND!"
set /p SERVER=Server name / hostname [!DEFNAME!]: 
if "%SERVER%"=="" set "SERVER=!DEFNAME!"

set /p PREFIX=Port prefix (10-99): 
echo(%PREFIX%| findstr /r "^[1-9][0-9]$" >nul
if errorlevel 1 (
  echo Invalid prefix. Use a number between 10 and 99.
  pause
  goto main
)
set /a PN=%PREFIX%
if %PN% LSS 10 (
  echo Invalid prefix. Use a number between 10 and 99.
  pause
  goto main
)
if %PN% GTR 99 (
  echo Invalid prefix. Use a number between 10 and 99.
  pause
  goto main
)

set /p MOUNT_RAW=Optional host path to mount at /var/media (leave empty to skip): 
set "MOUNT_NORM=!MOUNT_RAW:\=/!"
set "MOUNT_SPEC="
if not "!MOUNT_NORM!"=="" set "MOUNT_SPEC=!MOUNT_NORM!:/var/media"

set "P80=%PREFIX%80"
set "P8080=%PREFIX%88"
set "P22=%PREFIX%22"
set "P3306=%PREFIX%33"

call :log "%ENGINE% ps -a --format \"{{.Names}}\" ^| findstr /x /c:\"%SERVER%\""
%ENGINE% ps -a --format "{{.Names}}" | findstr /x /c:"%SERVER%" >nul
if not errorlevel 1 (
  echo Container name %SERVER% already exists. Choose another name.
  pause
  goto main
)

echo Starting container %SERVER% from %IMAGE%
echo Port mapping: %P80%-^>80, %P8080%-^>8080, %P22%-^>22, %P3306%-^>3306
if not "!MOUNT_SPEC!"=="" echo Mount: !MOUNT_SPEC!

if "!MOUNT_SPEC!"=="" (
  call :log "%ENGINE% run -d --name \"%SERVER%\" --hostname \"%SERVER%\" -p %P80%:80 -p %P8080%:8080 -p %P22%:22 -p %P3306%:3306 \"%IMAGE%\""
  %ENGINE% run -d --name "%SERVER%" --hostname "%SERVER%" -p %P80%:80 -p %P8080%:8080 -p %P22%:22 -p %P3306%:3306 "%IMAGE%" >nul
) else (
  call :log "%ENGINE% run -d --name \"%SERVER%\" --hostname \"%SERVER%\" -p %P80%:80 -p %P8080%:8080 -p %P22%:22 -p %P3306%:3306 -v \"!MOUNT_SPEC!\" \"%IMAGE%\""
  %ENGINE% run -d --name "%SERVER%" --hostname "%SERVER%" -p %P80%:80 -p %P8080%:8080 -p %P22%:22 -p %P3306%:3306 -v "!MOUNT_SPEC!" "%IMAGE%" >nul
)

if errorlevel 1 (
  echo Container start failed.
) else (
  echo Container started.
)
pause
goto main

:log
set "STAMP=%date% %time%"
>>"%LOGFILE%" echo [%STAMP%] %~1
exit /b 0
