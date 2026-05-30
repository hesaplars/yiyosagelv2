@echo off
:: YiyosaGel v2 GitHub Kurtarma Scripti
title YiyosaGel v2 - Otomatik Kurtarıcı
color 0C
echo ===================================================
echo       YiyosaGel v2 GitHub Geri Yukleme / Kurtarma
echo ===================================================
echo.
echo UYARI: Kaydedilmemis yerel degisiklikleriniz silinecek
echo ve tum dosyalar en son GitHub yedeginize donuscektir!
echo.
set /p SECIM=Devam etmek istiyor musunuz? (E/H): 

if /I "%SECIM%"=="E" (
    echo.
    echo 1/2: GitHub sunucusundan guncel durum aliniyor...
    git fetch origin
    
    echo 2/2: Dosyalar son yedekleme durumuna geri donduruluyor...
    git reset --hard origin/main
    
    echo.
    echo ===================================================
    echo       KURTARMA TAMAMLANDI! (Dosyalar Yuklendi)
    echo ===================================================
) else (
    echo.
    echo Islem iptal edildi.
)
echo.
pause
