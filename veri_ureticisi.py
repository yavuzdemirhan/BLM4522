import pandas as pd
import numpy as np
import random
import os

CSV_ADI = "hasta_kayitlari.csv"

# 2. İNTERNETTEN GERÇEK VERİ SETİ İNDİRME (Proje 5 ETL İçin)
# Amaç ETL için gerçek ve kapsamlı bir veri üretmek

print("İnternetten gerçek sağlık veri seti indiriliyor (5110 kayıt)...")
try:
    url = "https://raw.githubusercontent.com/danielchristopher513/Brain_Stroke_Prediction_Using_Machine_Learning/main/healthcare-dataset-stroke-data.csv"
    df = pd.read_csv(url)
    
    # Kolonları Türkçeleştirelim
    df = df.rename(columns={
        'id': 'Hasta_ID',
        'gender': 'Cinsiyet',
        'age': 'Yas',
        'hypertension': 'Hipertansiyon',
        'heart_disease': 'Kalp_Hastaligi',
        'ever_married': 'Evli_Mi',
        'work_type': 'Calisma_Tipi',
        'Residence_type': 'Yasam_Alani',
        'avg_glucose_level': 'Glikoz_Seviyesi',
        'bmi': 'Vucut_Kitle_Endeksi',
        'smoking_status': 'Sigara_Kullanimi',
        'stroke': 'Inme_Goruldu'
    })
    
    # ETL (Veri Temizleme) sürecini anlamlı kılmak için veriye kontrollü kirlilik ekleyelim:
    np.random.seed(42)
    random.seed(42)
    
    # 1. Cinsiyet alanında format ve yazım hataları yaratalım
    indices = df.sample(frac=0.15, random_state=42).index
    df.loc[indices, 'Cinsiyet'] = df.loc[indices, 'Cinsiyet'].apply(
        lambda x: str(x).lower() + " " if random.random() > 0.5 else str(x).upper()
    )
    
    # 2. Yaş alanında bazı değerleri bozup eksik bırakalım (Mevcutta eksik yok, biz ekliyoruz)
    yas_indices = df.sample(frac=0.08, random_state=10).index
    df.loc[yas_indices, 'Yas'] = np.nan
    
    # 3. Kasıtlı olarak tamamen gereksiz ve eksik değerlerle dolu bir kolon ekleyelim
    sigortalar = [random.choice(["SSK", "BAĞKUR", np.nan]) if random.random() > 0.40 else np.nan for _ in range(len(df))]
    df['Sigorta_Gereksiz'] = sigortalar
    
    df.to_csv(CSV_ADI, index=False)
    print(f"[{CSV_ADI}] {len(df)} satırlı gerçek veri seti oluşturuldu ve ETL için biraz kirletildi.")

except Exception as e:
    print(f"Veri indirilirken bir hata oluştu: {e}")
