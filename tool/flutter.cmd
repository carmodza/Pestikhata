@echo off
setlocal
for %%I in ("%~dp0..") do set "PESTIKHATA_ROOT=%%~fsI"
set "PATH=%PESTIKHATA_ROOT%\.tooling\flutter\bin\mingit\cmd;%PESTIKHATA_ROOT%\.tooling\flutter\bin;%PATH%"
set "PUB_CACHE=%PESTIKHATA_ROOT%\.tooling\pub-cache"
call "%PESTIKHATA_ROOT%\.tooling\flutter\bin\flutter.bat" %*
exit /b %errorlevel%
