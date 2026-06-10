-- =====================================================
-- ADIM 2: İNDEKS YÖNETİMİ
-- Platform  : PostgreSQL 16
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- Sorgu 1: Mevcut indexler
SELECT
    tablename       AS tablo,
    indexname       AS index_adi,
    indexdef        AS tanim
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;

-- -------------------------------------------------------
-- ÖRNEK A: payment.amount kolonu — index yok vs var
-- -------------------------------------------------------

-- Sorgu 2a: Index YOK — ÖNCE süre
EXPLAIN ANALYZE
SELECT payment_id, customer_id, amount
FROM payment
WHERE amount > 8.00;

-- Sorgu 2b: amount kolonuna index ekle
CREATE INDEX idx_payment_amount
    ON payment (amount);

-- Sorgu 2c: Index VAR — SONRA süre
EXPLAIN ANALYZE
SELECT payment_id, customer_id, amount
FROM payment
WHERE amount > 8.00;

-- -------------------------------------------------------
-- ÖRNEK B: rental.rental_date kolonu — index yok vs var
-- -------------------------------------------------------

-- Sorgu 3a: Index YOK — ÖNCE süre
EXPLAIN ANALYZE
SELECT rental_id, customer_id, rental_date, return_date
FROM rental
WHERE rental_date BETWEEN '2005-07-01' AND '2005-07-31';

-- Sorgu 3b: rental_date'e index ekle
CREATE INDEX idx_rental_date
    ON rental (rental_date);

-- Sorgu 3c: Index VAR — SONRA süre
EXPLAIN ANALYZE
SELECT rental_id, customer_id, rental_date, return_date
FROM rental
WHERE rental_date BETWEEN '2005-07-01' AND '2005-07-31';

-- -------------------------------------------------------
-- ÖRNEK C: Bileşik index — iki kolonlu sorgular için
-- -------------------------------------------------------

-- Sorgu 4: customer_id + payment_date bileşik index
CREATE INDEX idx_payment_customer_date
    ON payment (customer_id, payment_date);

EXPLAIN ANALYZE
SELECT payment_id, amount, payment_date
FROM payment
WHERE customer_id = 1
  AND payment_date >= '2007-01-01';

-- -------------------------------------------------------
-- Kullanılmayan indexler — disk kaplar, yazma yavaşlatır
-- -------------------------------------------------------

-- Sorgu 5: Hiç kullanılmamış indexler (idx_scan = 0)
SELECT
    relname                                             AS tablo,
    indexrelname                                        AS index_adi,
    idx_scan                                            AS kullanim_sayisi,
    pg_size_pretty(pg_relation_size(indexrelid))        AS boyut
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- -------------------------------------------------------
-- Tablo ve index boyutları
-- -------------------------------------------------------

-- Sorgu 6: Boyut raporu
SELECT
    relname                                             AS nesne,
    pg_size_pretty(pg_total_relation_size(relid))       AS toplam_boyut,
    pg_size_pretty(pg_relation_size(relid))             AS tablo_boyutu,
    pg_size_pretty(pg_indexes_size(relid))              AS index_boyutu
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
