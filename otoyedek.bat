@echo off
:: YiyosaGel v2 Otomatik GitHub Yedekleme Scripti
title YiyosaGel v2 - Otomatik Yedekleyici
color 0A
echo ===================================================
echo     YiyosaGel v2 GitHub Otomatik Yedekleme Servisi
echo ===================================================
echo.
echo 1/3: Dosya degisiklikleri tespit ediliyor...
git add .

echo 2/3: Yerel yedek paketi olusturuluyor...
:: Generate a clean ISO-like timestamp for commit
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set commit_msg=Otomatik Yedek %datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%

git commit -m "%commit_msg%"

echo.
echo 3/3: Yedekler GitHub bulutuna yukleniyor...
git push origin main

echo.
echo ===================================================
echo      YEDEKLEME TAMAMLANDI! (GitHub'a Yuklendi)
echo ===================================================
echo.
pause
