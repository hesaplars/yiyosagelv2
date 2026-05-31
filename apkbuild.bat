@echo off
:: YiyosaGel v2 Tek Tikla APK Derleyici
title YiyosaGel v2 - APK Derleyici
color 0b
setlocal

set "ROOT=%~dp0"
set "FLUTTER=C:\tmp\flutter-sdk\flutter\bin\flutter.bat"
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\build-tools\36.1.0;%PATH%"

echo ===================================================
echo         YiyosaGel v2 Tek Tikla APK Derleyici
echo ===================================================
echo.

if not exist "%FLUTTER%" (
  echo HATA: Flutter SDK bulunamadi: %FLUTTER%
  pause
  exit /b 1
)

echo 1/2: Bagimliliklar kontrol ediliyor...
call "%FLUTTER%" pub get
if errorlevel 1 (
  echo HATA: pub get basarisiz oldu.
  pause
  exit /b 1
)

echo.
echo 2/2: Android APK (Release) derleniyor...
echo Bu islem ilk seferde birkaç dakika surebilir, lutfen bekleyin...
echo.

call "%FLUTTER%" build apk --release
if errorlevel 1 (
  echo HATA: APK derleme basarisiz oldu.
  pause
  exit /b 1
)

echo.
echo ===================================================
echo         APK BASARIYLA DERLENDI!
echo ===================================================
echo.
echo Derlenen APK dosyasinin konumu:
echo %ROOT%build\app\outputs\flutter-apk\app-release.apk
echo.
pause
endlocal
