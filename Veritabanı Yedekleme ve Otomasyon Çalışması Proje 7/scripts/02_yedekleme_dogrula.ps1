# =====================================================
# YEDEKLEME DOGRULAMA SCRIPTI
# En son yedegi test veritabanina geri yukler
# ve satir sayilarini orijinal veritabani ile karsilastirir
# (PDF: "Test Yedekleme Senaryolari")
# =====================================================

$pgBin = "C:\Program Files\PostgreSQL\18\bin"
$env:PGPASSWORD = "101203"
$yedekKlasoru = "C:\Users\Yavuz\Desktop\agtabanli\proje7\yedekler"
$testDb = "dvdstore_test"

# En son yedek dosyasini bul
$sonYedek = Get-ChildItem -Path $yedekKlasoru -Filter "*.backup" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

if (-not $sonYedek) {
    Write-Host "Yedek dosyasi bulunamadi!" -ForegroundColor Red
    exit 1
}

Write-Host "Test edilecek yedek: $($sonYedek.Name)"

# Test veritabanini sifirdan olustur
& "$pgBin\psql.exe" -U postgres -c "DROP DATABASE IF EXISTS $testDb;"
& "$pgBin\psql.exe" -U postgres -c "CREATE DATABASE $testDb;"

# Yedegi geri yukle
& "$pgBin\pg_restore.exe" -U postgres -d $testDb $sonYedek.FullName

# Satir sayilarini karsilastir
$tablolar = @("customer", "film", "rental", "payment")

Write-Host ""
Write-Host "--- DOGRULAMA SONUCLARI ---"
foreach ($tablo in $tablolar) {
    $orijinal = (& "$pgBin\psql.exe" -U postgres -d dvdstore -t -A -c "SELECT COUNT(*) FROM $tablo;").Trim()
    $yedek    = (& "$pgBin\psql.exe" -U postgres -d $testDb   -t -A -c "SELECT COUNT(*) FROM $tablo;").Trim()

    if ($orijinal -eq $yedek) {
        Write-Host "$tablo : OK ($yedek satir)" -ForegroundColor Green
    } else {
        Write-Host "$tablo : UYUSMUYOR! orijinal=$orijinal yedek=$yedek" -ForegroundColor Red
    }
}
