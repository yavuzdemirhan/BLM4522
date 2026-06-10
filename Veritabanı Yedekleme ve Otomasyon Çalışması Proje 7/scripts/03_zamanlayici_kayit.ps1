# =====================================================
# WINDOWS GOREV ZAMANLAYICI KAYDI
# SQL Server Agent Job'in Windows karsiligi.
# Her gece 02:00'de yedekleme scriptini otomatik calistirir.
# =====================================================

$gorevAdi   = "PostgreSQL_DVDStore_Yedekleme"
$scriptYolu = "C:\Users\Yavuz\Desktop\agtabanli\proje7\scripts\01_yedekleme_al.ps1"

$action   = New-ScheduledTaskAction -Execute "powershell.exe" `
              -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptYolu`""
$trigger  = New-ScheduledTaskTrigger -Daily -At "02:00"
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

Register-ScheduledTask -TaskName $gorevAdi `
    -Action $action -Trigger $trigger -Settings $settings `
    -Description "Her gece dvdstore veritabanini otomatik yedekler" `
    -Force

# Kayit kontrolu
Get-ScheduledTask -TaskName $gorevAdi | Select-Object TaskName, State

# Gorevi simdi manuel tetiklemek icin (test amacli):
# Start-ScheduledTask -TaskName $gorevAdi
