@echo off
setlocal
pushd "%~dp0"
if /i "%~1"=="open" goto open
docker compose run --rm easyre easyre %*
set rc=%ERRORLEVEL%
popd
exit /b %rc%

:open
set "job="
for /f "delims=" %%d in ('dir /b /ad /od "jobs\%~2*" 2^>nul') do set "job=%%d"
if not defined job (
  echo No job found matching "%~2". See: easyre jobs
  popd
  exit /b 1
)
if /i "%~3"=="folder" (
  start "" explorer "jobs\%job%"
  popd
  exit /b 0
)
set "file=jobs\%job%\report.md"
if exist "jobs\%job%\tutor.md" set "file=jobs\%job%\tutor.md"
if not exist "%file%" (
  start "" explorer "jobs\%job%"
) else (
  echo Opening %file%
  start "" "%file%"
)
popd
exit /b 0
