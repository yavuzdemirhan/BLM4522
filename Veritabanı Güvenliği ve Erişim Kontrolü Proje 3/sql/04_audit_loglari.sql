-- =====================================================
-- ADIM 4: AUDIT (DENETİM) LOGLARI
-- Platform  : PostgreSQL 18
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- Sorgu 1: Audit log tablosu oluştur
CREATE TABLE IF NOT EXISTS audit_log (
    log_id          bigserial PRIMARY KEY,
    tablo_adi       text        NOT NULL,
    islem           text        NOT NULL,
    eski_veri       jsonb,
    yeni_veri       jsonb,
    kullanici       text        NOT NULL DEFAULT current_user,
    islem_zamani    timestamptz NOT NULL DEFAULT now()
);

-- Sorgu 2: Trigger fonksiyonu — her INSERT/UPDATE/DELETE'i kaydeder
CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (tablo_adi, islem, eski_veri)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (tablo_adi, islem, eski_veri, yeni_veri)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSE
        INSERT INTO audit_log (tablo_adi, islem, yeni_veri)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW));
        RETURN NEW;
    END IF;
END;
$$;

-- Sorgu 3: customer tablosuna trigger bağla
DROP TRIGGER IF EXISTS trg_customer_audit ON customer;

CREATE TRIGGER trg_customer_audit
AFTER INSERT OR UPDATE OR DELETE ON customer
FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- Sorgu 4: Test — bir müşterinin e-postasını güncelle
UPDATE customer
SET email = 'test.degisiklik@example.com'
WHERE customer_id = 1;

-- Sorgu 5: Audit logunu görüntüle — kim, ne zaman, neyi değiştirdi
SELECT
    log_id,
    tablo_adi,
    islem,
    kullanici,
    islem_zamani,
    eski_veri ->> 'email' AS eski_email,
    yeni_veri ->> 'email' AS yeni_email
FROM audit_log
ORDER BY islem_zamani DESC
LIMIT 5;

-- -------------------------------------------------------
-- Sunucu seviyesi loglama ayarları
-- -------------------------------------------------------

-- Sorgu 6: Hangi komutlar loglanıyor?
--          'none' / 'ddl' / 'mod' / 'all'
SHOW log_statement;

-- Sorgu 7: Bağlantı loglaması açık mı?
SHOW log_connections;

-- Sorgu 8: Log dosyaları aktif mi?
SHOW logging_collector;
