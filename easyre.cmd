@echo off
pushd "%~dp0"
docker compose run --rm easyre easyre %*
set rc=%ERRORLEVEL%
popd
exit /b %rc%
