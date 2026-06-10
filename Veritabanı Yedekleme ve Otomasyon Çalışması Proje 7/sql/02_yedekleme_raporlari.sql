-- =====================================================
-- ADIM 3: YEDEKLEME RAPORLARI
-- Platform  : PostgreSQL 18
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- Sorgu 1: Tüm yedekleme geçmişi
SELECT
    yedek_id,
    dosya_adi,
    baslangic,
    bitis,
    sure_saniye,
    pg_size_pretty(boyut_byte)  AS boyut,
    durum
FROM bakim.yedekleme_log
ORDER BY baslangic DESC;

-- Sorgu 2: Başarı oranı
SELECT
    durum,
    COUNT(*)                                                    AS adet,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)         AS yuzde
FROM bakim.yedekleme_log
GROUP BY durum;

-- Sorgu 3: Başarılı yedeklemelerin ortalama süresi ve boyutu
SELECT
    ROUND(AVG(sure_saniye), 2)                 AS ort_sure_sn,
    pg_size_pretty(AVG(boyut_byte)::bigint)    AS ort_boyut
FROM bakim.yedekleme_log
WHERE durum = 'BASARILI';

-- Sorgu 4: Son başarılı yedeklemeden bu yana geçen süre — UYARI eşiği
SELECT
    MAX(bitis)                  AS son_basarili_yedek,
    now() - MAX(bitis)          AS gecen_sure,
    CASE
        WHEN now() - MAX(bitis) > interval '24 hours'
            THEN 'UYARI: 24 saatten uzun süredir başarılı yedek yok'
        ELSE 'NORMAL'
    END                          AS durum
FROM bakim.yedekleme_log
WHERE durum = 'BASARILI';

-- Sorgu 5: Başarısız yedeklemeler
SELECT yedek_id, dosya_adi, baslangic, durum
FROM bakim.yedekleme_log
WHERE durum = 'BASARISIZ'
ORDER BY baslangic DESC;
