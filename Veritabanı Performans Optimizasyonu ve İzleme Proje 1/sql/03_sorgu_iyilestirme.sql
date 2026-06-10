-- =====================================================
-- ADIM 3: SORGU İYİLEŞTİRME
-- Platform  : PostgreSQL 16
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- -------------------------------------------------------
-- KARŞILAŞTIRMA 1: SELECT * vs gerekli kolonlar
-- -------------------------------------------------------

-- KÖTÜ — tüm kolonlar, gereksiz ağ + bellek yükü
EXPLAIN ANALYZE
SELECT *
FROM payment;

-- İYİ — sadece ihtiyaç duyulan kolonlar
EXPLAIN ANALYZE
SELECT payment_id, customer_id, amount, payment_date
FROM payment;

-- -------------------------------------------------------
-- KARŞILAŞTIRMA 2: WHERE içinde fonksiyon kullanımı
--   EXTRACT(YEAR ...) → index çalışmaz
--   Tarih aralığı      → index çalışır
-- -------------------------------------------------------

-- KÖTÜ — index bypass edilir, Seq Scan
EXPLAIN ANALYZE
SELECT rental_id, rental_date, customer_id
FROM rental
WHERE EXTRACT(MONTH FROM rental_date) = 7;

-- İYİ — index devreye girer, Bitmap Index Scan
EXPLAIN ANALYZE
SELECT rental_id, rental_date, customer_id
FROM rental
WHERE rental_date >= '2005-07-01'
  AND rental_date <  '2005-08-01';

-- -------------------------------------------------------
-- KARŞILAŞTIRMA 3: Correlated subquery vs JOIN
--   Her müşteri için kaç kiralama yaptı?
--   Subquery: customer başına ayrı sorgu → ÇOK YAVAŞ
--   JOIN    : tek geçiş            → HIZLI
-- -------------------------------------------------------

-- KÖTÜ — 599 müşteri için 599 kez ayrı sorgu çalışır
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    (SELECT COUNT(*)
     FROM rental r
     WHERE r.customer_id = c.customer_id) AS kiralama_sayisi
FROM customer c;

-- İYİ — tek JOIN geçişi, çok daha hızlı
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS kiralama_sayisi
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- -------------------------------------------------------
-- KARŞILAŞTIRMA 4: LIKE başı joker
--   '%son%'  → index çalışmaz (ne ile başladığı bilinmiyor)
--   'son%'   → index çalışır
-- -------------------------------------------------------

-- KÖTÜ — tam tablo taraması, Seq Scan
EXPLAIN ANALYZE
SELECT customer_id, first_name, last_name
FROM customer
WHERE last_name LIKE '%SON%';

-- İYİ — index destekli, çok daha hızlı
EXPLAIN ANALYZE
SELECT customer_id, first_name, last_name
FROM customer
WHERE last_name LIKE 'SON%';

-- -------------------------------------------------------
-- KARŞILAŞTIRMA 5: Çok tablolu JOIN optimizasyonu
--   Film kategorisine göre toplam kiralama geliri
-- -------------------------------------------------------

-- KÖTÜ — gereksiz tüm kolonlar, alt sorgu ile filtreleme
EXPLAIN ANALYZE
SELECT *
FROM film f
WHERE f.film_id IN (
    SELECT film_id FROM film_category
    WHERE category_id = (
        SELECT category_id FROM category WHERE name = 'Action'
    )
);

-- İYİ — JOIN zinciri, gerekli kolonlar, net filtre
EXPLAIN ANALYZE
SELECT
    f.film_id,
    f.title,
    f.rental_rate,
    c.name AS kategori
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c       ON fc.category_id = c.category_id
WHERE c.name = 'Action';

-- -------------------------------------------------------
-- VACUUM ANALYZE — istatistik güncellemesi
--   Sorgu planlayıcısı güncel istatistiklerle
--   çok daha iyi plan üretir
-- -------------------------------------------------------

VACUUM ANALYZE payment;
VACUUM ANALYZE rental;
VACUUM ANALYZE film;
VACUUM ANALYZE customer;

-- Son analiz zamanları
SELECT
    relname         AS tablo,
    last_vacuum     AS son_vacuum,
    last_analyze    AS son_analiz,
    last_autoanalyze AS otomatik_analiz
FROM pg_stat_user_tables
ORDER BY last_analyze ASC NULLS FIRST;
