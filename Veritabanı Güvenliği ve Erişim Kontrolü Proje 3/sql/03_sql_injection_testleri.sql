-- =====================================================
-- ADIM 3: SQL INJECTION TESTLERİ
-- Platform  : PostgreSQL 18
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- -------------------------------------------------------
-- GÜVENSİZ fonksiyon — string birleştirme (concatenation)
-- -------------------------------------------------------

-- Sorgu 1: Güvensiz arama fonksiyonu oluştur
CREATE OR REPLACE FUNCTION musteri_ara_guvensiz(p_isim text)
RETURNS TABLE(customer_id int, first_name varchar, last_name varchar, email varchar)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT customer_id, first_name, last_name, email
         FROM customer
         WHERE first_name = ''' || p_isim || '''';
END;
$$;


-- Sorgu 2: Normal kullanım — tek müşteri dönmeli
SELECT * FROM musteri_ara_guvensiz('MARY');

-- Sorgu 3: SQL INJECTION saldırısı
--          p_isim = X' OR '1'='1   →  WHERE her zaman TRUE olur
--          Sonuç: TÜM müşteriler dökülür (599 satır)
SELECT * FROM musteri_ara_guvensiz('X'' OR ''1''=''1');

-- -------------------------------------------------------
-- GÜVENLİ fonksiyon — parametreli sorgu (prepared statement)
-- -------------------------------------------------------

-- Sorgu 4: Güvenli arama fonksiyonu oluştur
CREATE OR REPLACE FUNCTION musteri_ara_guvenli(p_isim text)
RETURNS TABLE(customer_id int, first_name varchar, last_name varchar, email varchar)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT c.customer_id, c.first_name, c.last_name, c.email
        FROM customer c
        WHERE c.first_name = p_isim;
END;
$$;

-- Sorgu 5: Normal kullanım — aynı sonuç
SELECT * FROM musteri_ara_guvenli('MARY');

-- Sorgu 6: Aynı saldırı denemesi — artık 0 satır döner
--          Çünkü 'X'' OR ''1''=''1' artık SQL kodu değil,
--          sadece bir METİN DEĞERİ olarak karşılaştırılıyor
SELECT * FROM musteri_ara_guvenli('X'' OR ''1''=''1');

-- -------------------------------------------------------
-- format() ile %L kullanarak güvenli dinamik SQL
-- -------------------------------------------------------

-- Sorgu 7: %L otomatik olarak quote_literal yapar, injection'ı engeller
CREATE OR REPLACE FUNCTION musteri_ara_format(p_isim text)
RETURNS TABLE(customer_id int, first_name varchar, last_name varchar, email varchar)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE
        format('SELECT customer_id, first_name, last_name, email
                 FROM customer WHERE first_name = %L', p_isim);
END;
$$;

SELECT * FROM musteri_ara_format('X'' OR ''1''=''1');

-- -------------------------------------------------------
-- pg_stat_statements ile şüpheli sorguları tespit etme
-- -------------------------------------------------------

-- Sorgu 8: Olağandışı OR / yorum içeren sorguları listele
SELECT
    LEFT(query, 100)    AS sorgu,
    calls               AS cagri_sayisi
FROM pg_stat_statements
WHERE query ILIKE '%OR%=%'
   OR query ILIKE '%--%'
ORDER BY calls DESC
LIMIT 10;
