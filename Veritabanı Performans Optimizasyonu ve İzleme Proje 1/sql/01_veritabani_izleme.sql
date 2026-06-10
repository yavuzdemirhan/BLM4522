-- =====================================================
-- ADIM 1: VERİTABANI İZLEME
-- Platform  : PostgreSQL 16
-- Veritabanı: dvdstore (Pagila — DVD kiralama mağazası)
-- =====================================================

-- Sorgu 1: Tablo satır sayıları — veritabanını tanıyalım
SELECT
    relname         AS tablo,
    n_live_tup      AS satir_sayisi
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- Sorgu 2: pg_stat_statements eklentisini aktif et
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Sorgu 3: En yavaş sorgular
SELECT
    LEFT(query, 80)                                 AS sorgu,
    calls                                           AS cagri_sayisi,
    ROUND(mean_exec_time::numeric, 3)               AS ort_sure_ms,
    ROUND(total_exec_time::numeric, 3)              AS toplam_sure_ms
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Sorgu 4: Tablo tarama istatistikleri
--          seq_scan yüksekse o tabloya index gerekiyor
SELECT
    relname                 AS tablo_adi,
    seq_scan                AS tam_tablo_tarama,
    idx_scan                AS index_ile_erisim,
    n_live_tup              AS satir_sayisi
FROM pg_stat_user_tables
ORDER BY seq_scan DESC
LIMIT 10;

-- Sorgu 5: Aktif bağlantılar
SELECT
    pid                     AS islem_id,
    usename                 AS kullanici,
    application_name        AS uygulama,
    state                   AS durum,
    LEFT(query, 60)         AS sorgu,
    query_start             AS baslangic_zamani
FROM pg_stat_activity
WHERE state != 'idle'
  AND pid != pg_backend_pid();

-- Sorgu 6: Cache hit oranı
--          Hedef: %99 üstü — diskten okuma çok daha yavaş
SELECT
    datname                                                         AS veritabani,
    blks_hit                                                        AS onbellekten_okunan,
    blks_read                                                       AS diskten_okunan,
    ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2)   AS cache_hit_orani_yuzde
FROM pg_stat_database
WHERE datname = 'dvdstore';
