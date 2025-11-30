@echo off
REM Force window to stay open - add pause at start for debugging
echo Starting Neuro Toxin Auto-Installer...
echo.
timeout /t 2 >nul

setlocal EnableDelayedExpansion

REM Configuration
set "LAUNCHER_URL=https://hafenexplorer.github.io/launcher.jar"
set "CONFIG_URL=https://hafenexplorer.github.io/launcher.hl"
set "HAFEN_JAR_URL=https://hafenexplorer.github.io/hafen.jar"
set "BASE_URL=https://hafenexplorer.github.io"
set "INSTALL_DIR=%LOCALAPPDATA%\Neuro-Toxin"
set "CACHE_DIR=%INSTALL_DIR%\cache\https\hafenexplorer.github.io"

REM Display header
cls
echo.
echo ========================================
echo    NEURO TOXIN CLIENT AUTO-INSTALLER
echo ========================================
echo.

REM Check Java
echo [1/6] Checking Java...
Java -version 2>&1 | findstr /i "version"
if errorlevel 1 (
    echo.
    echo ERROR: Java not found
    echo Install from: https://adoptium.net/temurin/releases/
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo Java found!
echo.

REM Check Java version
echo [2/6] Checking Java version...
for /f "tokens=3" %%v in ('Java -version 2^>^&1 ^| findstr /i "version"') do (
    set JAVA_VERSION=%%v
    goto :got_version
)

:got_version
set JAVA_VERSION=%JAVA_VERSION:"=%
echo Java version: %JAVA_VERSION%

REM Simple version check - just check if it's 1.8
echo %JAVA_VERSION% | findstr /i "1.8" >nul
if not errorlevel 1 (
    echo.
    echo ERROR: Java 8 detected - too old!
    echo Required: Java 11 or newer
    echo Download from: https://adoptium.net/temurin/releases/
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo Version OK
echo.

REM Create directory
echo [3/7] Setting up directory...
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    echo Created: %INSTALL_DIR%
) else (
    echo Directory exists: %INSTALL_DIR%
)

cd /d "%INSTALL_DIR%"
echo.

REM Check and update launcher.jar
echo [4/7] Checking launcher.jar...
set "LAUNCHER_NEEDS_UPDATE=0"
set "LAUNCHER_PATH=%INSTALL_DIR%\launcher.jar"

if exist "!LAUNCHER_PATH!" (
    echo Existing launcher.jar found
    echo Checking if local launcher.jar matches repository version...
    
    REM Get local file size
    for %%A in ("!LAUNCHER_PATH!") do set LOCAL_LAUNCHER_SIZE=%%~zA
    echo Local file size: !LOCAL_LAUNCHER_SIZE! bytes
    
    REM Get remote file size using PowerShell
    echo Checking repository version...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $request = [System.Net.WebRequest]::Create('%LAUNCHER_URL%'); $request.Method = 'HEAD'; $request.Timeout = 10000; $response = $request.GetResponse(); $remoteSize = $response.ContentLength; $response.Close(); Write-Host $remoteSize; exit 0 } catch { Write-Host 'ERROR'; exit 1 }" > "%TEMP%\remote_launcher_size.txt"
    
    set /p REMOTE_LAUNCHER_SIZE=<"%TEMP%\remote_launcher_size.txt"
    del "%TEMP%\remote_launcher_size.txt" 2>nul
    
    if "!REMOTE_LAUNCHER_SIZE!"=="ERROR" (
        echo WARNING: Could not check repository version
        echo          (Network error or file not accessible)
        echo.
        echo Will attempt to download anyway to ensure latest version...
        set "LAUNCHER_NEEDS_UPDATE=1"
    ) else (
        echo Repository file size: !REMOTE_LAUNCHER_SIZE! bytes
        echo.
        
        if "!LOCAL_LAUNCHER_SIZE!"=="!REMOTE_LAUNCHER_SIZE!" (
            echo [OK] Local launcher.jar matches repository size
            echo       File appears to be up-to-date
            set "LAUNCHER_NEEDS_UPDATE=0"
        ) else (
            echo [UPDATE NEEDED] Local launcher.jar size differs from repository!
            echo                  Local:  !LOCAL_LAUNCHER_SIZE! bytes
            echo                  Remote: !REMOTE_LAUNCHER_SIZE! bytes
            echo.
            set "LAUNCHER_NEEDS_UPDATE=1"
        )
    )
) else (
    echo launcher.jar not found - will download
    set "LAUNCHER_NEEDS_UPDATE=1"
)

REM Download launcher.jar if update is needed
if !LAUNCHER_NEEDS_UPDATE!==1 (
    echo.
    echo Downloading launcher.jar from repository...
    echo Please wait...
    echo.
    
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%LAUNCHER_URL%', '!LAUNCHER_PATH!'); Write-Host 'SUCCESS'; exit 0 } catch { Write-Host 'ERROR:' $_.Exception.Message; exit 1 }"
    
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download launcher.jar
        echo Check internet connection
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    ) else (
        echo.
        echo [SUCCESS] launcher.jar downloaded/updated successfully!
    )
)
echo.

REM Check and update hafen.jar in cache
echo [5/7] Checking hafen.jar cache...
set "HAFEN_JAR_FOUND=0"
set "HAFEN_JAR_PATH="
set "NEEDS_UPDATE=0"

REM Search for hafen.jar in cache directory (recursively)
if exist "%CACHE_DIR%" (
    echo Searching for hafen.jar in cache...
    for /r "%CACHE_DIR%" %%f in (hafen.jar) do (
        if exist "%%f" (
            set "HAFEN_JAR_PATH=%%f"
            set "HAFEN_JAR_FOUND=1"
            goto :found_hafen
        )
    )
)

:found_hafen
if %HAFEN_JAR_FOUND%==1 (
    echo Found hafen.jar: !HAFEN_JAR_PATH!
    echo.
    echo Checking if cached hafen.jar matches repository version...
    
    REM Get local file size
    for %%A in ("!HAFEN_JAR_PATH!") do set LOCAL_SIZE=%%~zA
    echo Local file size: !LOCAL_SIZE! bytes
    
    REM Get remote file size using PowerShell
    echo Checking repository version...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $request = [System.Net.WebRequest]::Create('%HAFEN_JAR_URL%'); $request.Method = 'HEAD'; $request.Timeout = 10000; $response = $request.GetResponse(); $remoteSize = $response.ContentLength; $response.Close(); Write-Host $remoteSize; exit 0 } catch { Write-Host 'ERROR'; exit 1 }" > "%TEMP%\remote_size.txt"
    
    set /p REMOTE_SIZE=<"%TEMP%\remote_size.txt"
    del "%TEMP%\remote_size.txt" 2>nul
    
    if "!REMOTE_SIZE!"=="ERROR" (
        echo WARNING: Could not check repository version
        echo          (Network error or file not accessible)
        echo.
        echo Will attempt to download anyway to ensure latest version...
        set "NEEDS_UPDATE=1"
    ) else (
        echo Repository file size: !REMOTE_SIZE! bytes
        echo.
        
        if "!LOCAL_SIZE!"=="!REMOTE_SIZE!" (
            echo [OK] Cached hafen.jar matches repository size
            echo       File appears to be up-to-date
            set "NEEDS_UPDATE=0"
        ) else (
            echo [UPDATE NEEDED] Cached hafen.jar size differs from repository!
            echo                  Local:  !LOCAL_SIZE! bytes
            echo                  Remote: !REMOTE_SIZE! bytes
            echo.
            set "NEEDS_UPDATE=1"
        )
    )
    
    REM Download and overwrite if update is needed
    if !NEEDS_UPDATE!==1 (
        echo.
        echo Downloading updated hafen.jar from repository...
        echo This may take a few minutes...
        echo.
        
        REM Get the directory of the cached file
        for %%F in ("!HAFEN_JAR_PATH!") do set "HAFEN_DIR=%%~dpF"
        
        REM Download to the same location, overwriting existing file
        powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%HAFEN_JAR_URL%', '!HAFEN_JAR_PATH!'); Write-Host 'SUCCESS'; exit 0 } catch { Write-Host 'ERROR:' $_.Exception.Message; exit 1 }"
        
        if errorlevel 1 (
            echo.
            echo ERROR: Failed to download updated hafen.jar
            echo        The old cached version will be used
            echo        Check internet connection and try again
        ) else (
            echo.
            echo [SUCCESS] hafen.jar updated successfully!
            echo          Old cached file has been replaced
        )
    )
    echo.
) else (
    echo.
    echo.
    echo.
)

REM Download AlarmSounds, MapIconsPresets, and midiFiles if they don't exist
echo [6/7] Checking resource directories...
echo.

REM Check and download AlarmSounds
set "ALARM_DIR=%INSTALL_DIR%\AlarmSounds"
if exist "!ALARM_DIR!" (
    echo [OK] AlarmSounds directory exists
) else (
    echo [DOWNLOAD] AlarmSounds directory not found - downloading...
    mkdir "!ALARM_DIR!" 2>nul
    mkdir "!ALARM_DIR!\settings" 2>nul
    
    echo Downloading AlarmSounds files...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $baseUrl = '%BASE_URL%/AlarmSounds/'; $installDir = '%INSTALL_DIR%'; $files = @('ND_Ambush.wav', 'ND_Badger.wav', 'ND_Barnacles.wav', 'ND_Bear.wav', 'ND_Bear2.wav', 'ND_Boar.wav', 'ND_Boar2.wav', 'ND_Cachalot.wav', 'ND_CaveAngler.wav', 'ND_Cleave.wav', 'ND_Eagle.wav', 'ND_EagleOwl.wav', 'ND_EnemySighted.wav', 'ND_EnemySpotted.wav', 'ND_EngagedTheEnemy.wav', 'ND_EngagingFoe.wav', 'ND_FlyingTheFriendlySkies.wav', 'ND_GreySeal.wav', 'ND_HelloFriend.wav', 'ND_HeyWatchout.wav', 'ND_HitAndRun.wav', 'ND_HorseEnergy.wav', 'ND_Lynx.wav', 'ND_Mammoth.wav', 'ND_MarioCoin.wav', 'ND_Moose.wav', 'ND_Nidbane.wav', 'ND_NotEnoughEnergy.wav', 'ND_Opk.wav', 'ND_Orca.wav', 'ND_PriorityTarget.wav', 'ND_PriorityTargetHere.wav', 'ND_Snake.wav', 'ND_Troll.wav', 'ND_Walrus.wav', 'ND_Wolf.wav', 'ND_Wolverine.wav', 'ND_YoHeadsUp.wav'); $client = New-Object System.Net.WebClient; $success = 0; foreach ($file in $files) { try { $url = $baseUrl + $file; $dest = Join-Path $installDir \"AlarmSounds\\$file\"; $client.DownloadFile($url, $dest); $success++ } catch { } }; Write-Host \"Downloaded $success files\"; exit 0"
    
    REM Download settings file
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $url = '%BASE_URL%/AlarmSounds/settings/defaultAlarms'; $dest = Join-Path '%INSTALL_DIR%' 'AlarmSounds\settings\defaultAlarms'; (New-Object System.Net.WebClient).DownloadFile($url, $dest); Write-Host 'Downloaded: settings/defaultAlarms' } catch { Write-Host 'Warning: Could not download defaultAlarms' }"
    
    echo [OK] AlarmSounds directory created
)
echo.

REM Check and download MapIconsPresets
set "MAPICONS_DIR=%INSTALL_DIR%\MapIconsPresets"
if exist "!MAPICONS_DIR!" (
    echo [OK] MapIconsPresets directory exists
) else (
    echo [DOWNLOAD] MapIconsPresets directory not found - downloading...
    mkdir "!MAPICONS_DIR!" 2>nul
    
    echo Downloading MapIconsPresets files...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $url = '%BASE_URL%/MapIconsPresets/defaultPresets'; $dest = Join-Path '%INSTALL_DIR%' 'MapIconsPresets\defaultPresets'; (New-Object System.Net.WebClient).DownloadFile($url, $dest); Write-Host 'Downloaded: defaultPresets'; exit 0 } catch { Write-Host 'Warning: Could not download defaultPresets'; exit 1 }"
    
    echo [OK] MapIconsPresets directory created
)
echo.

REM Check and download midiFiles
set "MIDI_DIR=%INSTALL_DIR%\midiFiles"
if exist "!MIDI_DIR!" (
    echo [OK] midiFiles directory exists
) else (
    echo [DOWNLOAD] midiFiles directory not found - downloading...
    mkdir "!MIDI_DIR!" 2>nul
    
    echo Downloading midiFiles...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $url = '%BASE_URL%/midiFiles/example.mid'; $dest = Join-Path '%INSTALL_DIR%' 'midiFiles\example.mid'; (New-Object System.Net.WebClient).DownloadFile($url, $dest); Write-Host 'Downloaded: example.mid'; exit 0 } catch { Write-Host 'Warning: Could not download example.mid'; exit 1 }"
    
    echo [OK] midiFiles directory created
)
echo.

REM Launch
echo [7/7] Starting Neuro Toxin...
echo.
echo Launching game...
echo Window will stay open for debugging
echo.
echo Working directory: %CD%
echo.
echo ========================================
echo.

Java -jar launcher.jar "%CONFIG_URL%"
set EXIT_CODE=%errorlevel%

echo.
echo ========================================
echo Game launched with code: %EXIT_CODE%
echo.
if %EXIT_CODE% NEQ 0 (
    echo Something went wrong!
    echo Check error messages above
    echo.
)
echo Installation directory: %INSTALL_DIR%
echo.
echo Press any key to close...
pause >nul
exit /b %EXIT_CODE%