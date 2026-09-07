@echo off & cd /d "%~dp0"
fsutil dirty query %systemdrive% >nul && goto:GA || echo Run as Administrator & pause && exit /b
:GA
echo.
echo [95m Disable Microsoft Edge Update + WebView2 auto-update [0m
setlocal EnableDelayedExpansion

echo [33m [1/6] Disabling Edge Update services... [0m
reg add "HKLM\System\CurrentControlSet\Services\edgeupdate" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\edgeupdatem" /v "Start" /t REG_DWORD /d "4" /f
sc stop edgeupdate
sc stop edgeupdatem

echo [33m [2/6] Disabling Edge Update scheduled tasks... [0m
:: Known default task names
schtasks /Change /Disable /TN "MicrosoftEdgeUpdateTaskMachineCore"
schtasks /Change /Disable /TN "MicrosoftEdgeUpdateTaskMachineUA"

:: Try to disable any other tasks with "MicrosoftEdgeUpdate" in the name
for /f "tokens=*" %%T in ('schtasks /Query /FO LIST /V 2^>nul ^| findstr /I "TaskName:" ^| findstr /I "MicrosoftEdgeUpdate"') do (
    set "TASKLINE=%%T"
    set "TASKNAME=!TASKLINE:TaskName:=!"
    set "TASKNAME=!TASKNAME: =!"
    if not "!TASKNAME!"=="" (
        schtasks /Change /Disable /TN "!TASKNAME!"
    )
)

echo [33m [3/6] Stopping Edge Update processes... [0m
taskkill /F /IM MicrosoftEdgeUpdate.exe
taskkill /F /IM MicrosoftEdgeUpdateCore.exe
taskkill /F /IM MicrosoftEdgeUpdateOnDemand.exe
taskkill /F /IM MicrosoftEdgeUpdateBroker.exe

echo [33m [4/6] Removing Edge Update folders... [0m
:: Note: Some files may be in use and cannot be deleted until reboot.
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeUpdate"
rd /s /q "C:\Program Files (x86)\Microsoft\Temp"
rd /s /q "%LOCALAPPDATA%\Microsoft\EdgeUpdate"
rd /s /q "C:\ProgramData\Microsoft\EdgeUpdate"

echo [33m [5/6] Creating dummy EdgeUpdate... [0m
:: Create a file named "EdgeUpdate" (no extension) inside that folder
type nul > "C:\Program Files (x86)\Microsoft\EdgeUpdate"

echo [33m [6/6] Adding registry policies to disable Edge/WebView2 updates... [0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v AutoUpdateCheckPeriodMinutes /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v UpdateDefault /t REG_DWORD /d 0 /f

:: Also set the per‑client policy for WebView2 Runtime specifically
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "Update{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" /t REG_DWORD /d 0 /f

echo [95m Done. A reboot is recommended for changes to fully take effect. [0m

echo.
pause
exit
