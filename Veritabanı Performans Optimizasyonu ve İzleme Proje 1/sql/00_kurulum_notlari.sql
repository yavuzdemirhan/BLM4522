-- =====================================================
-- KURULUM NOTLARI — Pagila Veritabanı
-- =====================================================
--
-- 1. Pagila'yı indir:
--    https://github.com/devrimgunduz/pagila adresinden
--    pagila-schema.sql ve pagila-data.sql dosyalarını indir
--
-- 2. Veritabanı oluştur ve yükle:
--    psql -U postgres -c "CREATE DATABASE dvdstore;"
--    psql -U postgres -d dvdstore -f pagila-schema.sql
--    psql -U postgres -d dvdstore -f pagila-data.sql
--
-- 3. Bağlan:
--    psql -U postgres -d dvdstore
--
-- 4. Test et:
--    SELECT COUNT(*) FROM payment;   -- yaklaşık 14596
--    SELECT COUNT(*) FROM rental;    -- yaklaşık 16044
--
-- 5. Performans demosu için ek veri üret (aşağıdaki scripti çalıştır)
-- =====================================================

-- ek veri üretimi — payment tablosunu ~500k satıra çıkar
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (1 + floor(random() * 599))::int,
    (1 + floor(random() * 2))::int,
    (1 + floor(random() * 16044))::int,
    round((0.99 + random() * 9)::numeric, 2),
    '2007-01-01'::timestamp + (random() * interval '365 days')
FROM generate_series(1, 490000);

-- rental tablosunu ~500k satıra çıkar
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT
    '2005-05-24'::timestamp + (random() * interval '500 days'),
    (1 + floor(random() * 4581))::int,
    (1 + floor(random() * 599))::int,
    '2005-05-24'::timestamp + (random() * interval '520 days'),
    (1 + floor(random() * 2))::int
FROM generate_series(1, 490000);

-- istatistikleri güncelle
ANALYZE payment;
ANALYZE rental;

-- kontrol
SELECT
    relname        AS tablo,
    n_live_tup     AS satir_sayisi
FROM pg_stat_user_tables
WHERE relname IN ('payment', 'rental', 'film', 'customer', 'inventory')
ORDER BY n_live_tup DESC;
