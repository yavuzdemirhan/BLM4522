import pandas as pd
import sqlite3
import os

CSV_DOSYASI = "../hasta_kayitlari.csv"
HEDEF_DB = "./Hastane_Temiz_Veri.db"
RAPOR_DOSYASI = "./Hastane_ETL_Raporu.txt"

def hastane_etl_run():
    rapor_satirlari = ["=== HASTANE VERİ TEMİZLEME VE ETL RAPORU ==="]
    
    # 1. EXTRACT (Veriyi Sistemden Cekme)
    try:
        df = pd.read_csv(CSV_DOSYASI)
        rapor_satirlari.append(f"Aşama 1: Ham hasta dosyası yüklendi. İşlem görecek kayıt: {len(df)}")
    except FileNotFoundError:
        print("hasta verisi bulunamadı!")
        return

    # 2. TRANSFORM (Hatalı/Bozuk Veri Temizleme)
    
    # Yas sutunundaki eksikleri tespit edip medyan (ortanca) ile sirtliyoruz
    eksik_yas_sayisi = df['Yas'].isnull().sum()
    df['Yas'] = df['Yas'].fillna(df['Yas'].median()) 
    
    # Aynı şekilde Vücut Kitle Endeksi'ndeki (BMI) eksikleri de dolduralım
    eksik_bmi_sayisi = df['Vucut_Kitle_Endeksi'].isnull().sum()
    df['Vucut_Kitle_Endeksi'] = df['Vucut_Kitle_Endeksi'].fillna(df['Vucut_Kitle_Endeksi'].median()) 

    # Gereksiz olan 'Sigorta_Gereksiz' sutununu ve modellemede işe yaramayan ID kolonunu silelim
    df.drop(['Sigorta_Gereksiz', 'Hasta_ID'], axis=1, inplace=True, errors='ignore')
    rapor_satirlari.append("Aşama 2 (Silme): Çöplük niteliğindeki Sigorta_Gereksiz kolonu ve referans olan Hasta_ID veriden tamamen silindi.")

    # Cinsiyet alanlarına kasti olarak eklediğimiz format bozukluklarını düzeltip, standardize edelim
    df['Cinsiyet'] = df['Cinsiyet'].str.strip().str.capitalize()
    
    # "Other" veya "Bilinmiyor" olanları en çok tekrar eden cinsiyet ile bile doldurabiliriz ama şimdilik dokunmuyoruz.
    
    rapor_satirlari.append(f"Aşama 2 (Düzeltme): Model eğitimini bozan {eksik_yas_sayisi} kayıp Yaş ve {eksik_bmi_sayisi} kayıp Vücut Kitle Endeksi başarıyla onarıldı.")
    rapor_satirlari.append(f"Aşama 2 (Standardizasyon): Dağınık girilen Cinsiyet ibareleri (büyük/küçük harf, gereksiz boşluk) tek formata dönüştürüldü.")
    rapor_satirlari.append(f"Son Durum: Veritabanına aktırılacak temiz kayıt adedi: {len(df)}")

    # 3. LOAD (Temiz Veriyi SQLite ile Saklama)
    
    if os.path.exists(HEDEF_DB):
        os.remove(HEDEF_DB) 

    hastane_baglanti = sqlite3.connect(HEDEF_DB)
    
    # dataframe'i temiz veriler isminde tablo yaparak veritabanina yaz
    df.to_sql('TemizlenenHastalar', hastane_baglanti, if_exists='replace', index=False)
    hastane_baglanti.close()

    rapor_satirlari.append(f"Aşama 3 (Yükleme): Tüm işlemler tamamlandı. Veriler yeni oluşturulan '{HEDEF_DB}' sunucusuna başarıyla taşındı.")

    # operasyon bitti yazdir
    with open(RAPOR_DOSYASI, "w", encoding="utf-8") as dosya:
        dosya.write("\n".join(rapor_satirlari))

if __name__ == "__main__":
    hastane_etl_run()
