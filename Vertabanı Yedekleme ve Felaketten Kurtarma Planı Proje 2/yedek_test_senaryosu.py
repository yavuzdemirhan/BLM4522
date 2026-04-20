import sqlite3
import shutil
import time
import os
from datetime import datetime

# veri yollari
KAYNAK = "../Proje 5 Veri Temizleme ve ETL Süreçleri Tasarımı/Hastane_Temiz_Veri.db"
YEDEK_DIZINI = "./yedek_deposu"

# klasor yoksa olustursun
if not os.path.exists(YEDEK_DIZINI):
    os.makedirs(YEDEK_DIZINI)

def tam_yedek_baslat():
    # tam yedekleme yapiyrz
    zaman_damgasi = datetime.now().strftime("%Y%m%d_%H%M%S")
    yedek_dosyasi = f"{YEDEK_DIZINI}/Hastane_Full_{zaman_damgasi}.db"
    
    try:
        shutil.copy2(KAYNAK, yedek_dosyasi)
        print(f"Yedekleme başarılı şekilde tamamlandı. Dosya: {yedek_dosyasi}")
    except Exception as e:
        print(f"Sistem yedeklenirken bir sorun oluştu: {e}")

def felaket_kurtarma_simulasyonu():
    # patlayan sistemi diriltmece
    yedekler = sorted([dosya for dosya in os.listdir(YEDEK_DIZINI) if dosya.endswith(".db")], reverse=True)
    
    if not yedekler:
        print("Sistemde yüklenebilecek herhangi bir yedek kaydı bulunamadı.")
        return

    en_yeni_yedek = os.path.join(YEDEK_DIZINI, yedekler[0])
    yeni_veritabani = "./Kurtarilan_HastaneDB.db"

    print(f"Sistem çökmesi simüle ediliyor... En güncel yedek üzerinden kurtarma başlatıldı: {en_yeni_yedek}")
    
    # ana sunucu gibi davransin dıye kopyaladik
    shutil.copy2(en_yeni_yedek, yeni_veritabani)
    print(f"Veriler sağlıklı bir şekilde kurtarıldı. Yeni hedef: {yeni_veritabani}")
    
    # baglanip tablolara bi bkalim geldi mi 
    try:
        baglanti = sqlite3.connect(yeni_veritabani)
        imlec = baglanti.cursor()
        imlec.execute("SELECT name FROM sqlite_master WHERE type='table';")
        print(f"Sistem bağlantı onayı başarılı. Veritabanındaki aktif tablolar: {imlec.fetchall()}")
        baglanti.close()
    except sqlite3.Error as e:
        print(f"Veritabanı kurtarılırken kritik hata tespit edildi: {e}")

if __name__ == "__main__":
    # deneme starti 
    tam_yedek_baslat()
    time.sleep(1)
    felaket_kurtarma_simulasyonu()
