-- =====================================================
-- ADIM 1: YEDEKLEME ALTYAPISI
-- Platform  : PostgreSQL 18
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- Sorgu 1: Veritabanı toplam boyutu — neyi yedekliyoruz?
SELECT pg_size_pretty(pg_database_size('dvdstore')) AS veritabani_boyutu;

-- Sorgu 2: En büyük tablolar
SELECT
    relname                                         AS tablo,
    pg_size_pretty(pg_total_relation_size(relid))   AS boyut
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

-- -------------------------------------------------------
-- Yedekleme geçmişi log tablosu
-- (SQL Server'daki msdb.dbo.backupset karşılığı)
-- -------------------------------------------------------

-- Sorgu 3: Bakım şeması ve log tablosu
CREATE SCHEMA IF NOT EXISTS bakim;

CREATE TABLE IF NOT EXISTS bakim.yedekleme_log (
    yedek_id        bigserial PRIMARY KEY,
    dosya_adi       text        NOT NULL,
    baslangic       timestamptz NOT NULL,
    bitis           timestamptz NOT NULL,
    sure_saniye     numeric,
    boyut_byte      bigint,
    durum           text        NOT NULL CHECK (durum IN ('BASARILI','BASARISIZ'))
);

-- Sorgu 4: Tablo boş mu kontrol et
SELECT * FROM bakim.yedekleme_log;
