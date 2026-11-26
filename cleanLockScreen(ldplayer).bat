@echo off

setlocal enableDelayedExpansion

echo Make sure adb and root are turned on


set "LDPath="
for %%K in (
	"HKEY_LOCAL_MACHINE\SOFTWARE\XuanZhi\LDPlayer14"
	"HKEY_CURRENT_USER\Software\XuanZhi\LDPlayer14"
	"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\XuanZhi\LDPlayer14"
	"HKEY_LOCAL_MACHINE\SOFTWARE\leidian\ldplayer14"
	"HKEY_CURRENT_USER\Software\leidian\ldplayer14"
	"HKEY_LOCAL_MACHINE\SOFTWARE\XuanZhi\LDPlayer9"
	"HKEY_CURRENT_USER\Software\XuanZhi\LDPlayer9"
	"HKEY_LOCAL_MACHINE\SOFTWARE\XuanZhi\LDPlayerVK"
	"HKEY_LOCAL_MACHINE\SOFTWARE\leidian\ldplayer9"
	"HKEY_LOCAL_MACHINE\SOFTWARE\leidian\LDPlayerVK"
) do (
	if not defined LDPath (
		for /f "tokens=1,2,*" %%i in ('REG QUERY "%%~K" /v "InstallDir" 2^>nul ^| find /i "InstallDir"') do (
			if exist "%%k\adb.exe" (
				set "LDPath=%%k"
			)
		)
	)
)

:NEXTSETP
if not defined LDPath (
	goto ERRORPATH
)

cd /d "!LDPath!"

adb.exe kill-server  > nul 2>&1
adb.exe start-server > nul 2>&1


set "emucount=0"
set "maxretry=9"

:LOOP
set "index=0"
set "deviceFound=false"


for /f "skip=1 tokens=1,2" %%a in ('adb.exe devices') do (
    if "%%b"=="device" (
        set /a "index+=1"
        set "deviceArray[!index!]=%%a"
        set "deviceFound=true"
    )
)


if "!deviceFound!"=="false" (
    for /l %%p in (5555,2,5585) do (
        netstat -an -p TCP | findstr /r /c:":%%p  *0\.0\.0\.0:0" > nul 2>&1 && (
            adb.exe connect 127.0.0.1:%%p > nul 2>&1
        )
    )
    set /a "emucount+=1"
    if !emucount! lss !maxretry! (
        echo waiting...
        timeout /t 2 > nul
        goto LOOP
    ) else (
        echo No devices found.
        endlocal
        pause
        exit
    )
)


for /l %%i in (1,1,!index!) do (
    echo Device %%i: !deviceArray[%%i]!
	adb.exe -s !deviceArray[%%i]! shell "su -c 'rm -f /data/system/gesture.key /data/system/password.key /data/system/gatekeeper.pattern.key /data/system/gatekeeper.password.key /data/system/locksettings.db /data/system/locksettings.db-wal /data/system/locksettings.db-shm /data/system/locksettings.db-journal'" > nul 2>&1
	adb.exe -s !deviceArray[%%i]! shell "su -c 'rm -rf /data/system_de/0/spblob/*'" > nul 2>&1
	adb.exe -s !deviceArray[%%i]! shell "su -c 'sync'" > nul 2>&1
)

echo Clear password completed, please restart the emulator.
endlocal
pause
exit



:ERRORPATH
echo LDPlayer Path error
pause
exit
