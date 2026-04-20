-- hastane sistemi yedekleme komutlari 

-- full backup (haftalik rutin alinacak db)
BACKUP DATABASE Hastane_Temiz_Veri
TO DISK = 'C:\Yedekler\Hastane_Temiz_Veri_Full.bak'
WITH FORMAT, 
     MEDIANAME = 'SaglikSistemi', 
     NAME = 'Hastane Veritabani Tam Yedeği';
GO

-- differential backup (gunluk degisen hasta kayitlarini aliyoruz)
BACKUP DATABASE Hastane_Temiz_Veri
TO DISK = 'C:\Yedekler\Hastane_Temiz_Veri_Diff.bak'
WITH DIFFERENTIAL,
     NAME = 'Hastane Veritabani Gunluk Fark Yedeği';
GO

-- transaction log (nokta atisi hasta kayitlarini kaybetmemek icin)
BACKUP LOG Hastane_Temiz_Veri
TO DISK = 'C:\Yedekler\Hastane_Temiz_Veri_Log.trn'
WITH NAME = 'Hastane Islem Gunlugu Yedeği';
GO


-- point-in-time restore senaryosu
-- ornegin 16:00'da sistem cokecek, biz 15:59'a dönecegiz

-- ilk logu alip guvenceye aliyoruz
BACKUP LOG Hastane_Temiz_Veri
TO DISK = 'C:\Yedekler\Hastane_Temiz_Veri_TailLog.trn'
WITH NORECOVERY;
GO

-- once ana yedeği yukledik (kullanima acmadan)
RESTORE DATABASE Hastane_Temiz_Veri
FROM DISK = 'C:\Yedekler\Hastane_Temiz_Veri_Full.bak'
WITH NORECOVERY;
GO

-- uzerine hizlica gunluk farrk paketini ekliyoz
RESTORE DATABASE Hastane_Temiz_Veri
FROM DISK = 'C:\Yedekler\Hastane_Temiz_Veri_Diff.bak'
WITH NORECOVERY;
GO

-- son olarak saniyeyi veriyoruz, 15:59'da durdur!
RESTORE LOG Hastane_Temiz_Veri
FROM DISK = 'C:\Yedekler\Hastane_Temiz_Veri_Log.trn'
WITH STOPAT = '2023-12-05 15:59:59', RECOVERY;
GO


-- yuksek erisebilirlik icin server aynalama komutlari
ALTER DATABASE Hastane_Temiz_Veri 
SET PARTNER = 'TCP://BackupServer.saglik.local:5022';
GO

ALTER DATABASE Hastane_Temiz_Veri 
SET PARTNER SAFETY FULL;
GO
