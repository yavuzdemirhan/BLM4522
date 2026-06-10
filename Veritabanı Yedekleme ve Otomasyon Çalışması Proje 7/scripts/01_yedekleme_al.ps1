# =====================================================
# OTOMATIK YEDEKLEME SCRIPTI
# Veritabani: dvdstore (PostgreSQL 18)
# Bu script SQL Server Agent Job'in PowerShell karsiligidir.
# =====================================================

$pgBin = "C:\Program Files\PostgreSQL\18\bin"
$env:PGPASSWORD = "101203"

$yedekKlasoru = "C:\Users\Yavuz\Desktop\agtabanli\proje7\yedekler"
$logKlasoru   = "C:\Users\Yavuz\Desktop\agtabanli\proje7\loglar"

if (-not (Test-Path $yedekKlasoru)) { New-Item -ItemType Directory -Path $yedekKlasoru | Out-Null }
if (-not (Test-Path $logKlasoru))   { New-Item -ItemType Directory -Path $logKlasoru   | Out-Null }

$tarih     = Get-Date -Format "yyyyMMdd_HHmmss"
$dosyaAdi  = "dvdstore_$tarih.backup"
$dosyaYolu = Join-Path $yedekKlasoru $dosyaAdi

Write-Host "Yedekleme basliyor: $dosyaAdi"
$baslangic = Get-Date

# Custom format - sikistirilmis, pg_restore ile geri yuklenebilir
& "$pgBin\pg_dump.exe" -U postgres -d dvdstore -F c -f $dosyaYolu
$basariliMi = ($LASTEXITCODE -eq 0)

$bitis = Get-Date
$sure  = [math]::Round(($bitis - $baslangic).TotalSeconds, 2)
$boyut = if (Test-Path $dosyaYolu) { (Get-Item $dosyaYolu).Length } else { 0 }
$durum = if ($basariliMi) { "BASARILI" } else { "BASARISIZ" }

# Sonucu veritabanindaki log tablosuna yaz
$bas = $baslangic.ToString("yyyy-MM-dd HH:mm:ss")
$bit = $bitis.ToString("yyyy-MM-dd HH:mm:ss")

$insertSql = "INSERT INTO bakim.yedekleme_log (dosya_adi, baslangic, bitis, sure_saniye, boyut_byte, durum) " +
             "VALUES ('$dosyaAdi', '$bas', '$bit', $sure, $boyut, '$durum');"

& "$pgBin\psql.exe" -U postgres -d dvdstore -c $insertSql

# Basarisizsa uyari log dosyasina yaz (yonetici bildirimi)
if (-not $basariliMi) {
    $uyariMesaji = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - YEDEKLEME BASARISIZ: $dosyaAdi"
    Add-Content -Path (Join-Path $logKlasoru "uyarilar.log") -Value $uyariMesaji
    Write-Host $uyariMesaji -ForegroundColor Red
} else {
    Write-Host "Yedekleme tamamlandi: $dosyaYolu ($boyut bayt, $sure sn)" -ForegroundColor Green
}
