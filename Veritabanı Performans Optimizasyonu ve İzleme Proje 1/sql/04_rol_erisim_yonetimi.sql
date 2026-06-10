-- =====================================================
-- ADIM 4: ROL VE ERİŞİM YÖNETİMİ
-- Platform  : PostgreSQL 16
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- Sorgu 1: Mevcut roller
SELECT
    rolname         AS rol_adi,
    rolsuper        AS superuser,
    rolcreatedb     AS db_olusturabilir,
    rolcanlogin     AS giris_yapabilir
FROM pg_roles
ORDER BY rolname;

-- -------------------------------------------------------
-- 3 farklı rol oluştur
--   raporcu    → sadece okuma (SELECT)
--   kasiyer    → okuma + yazma (SELECT, INSERT, UPDATE)
--   db_admin   → tam yetki
-- -------------------------------------------------------

-- Sorgu 2: Rolleri oluştur
DO $$ BEGIN
    CREATE ROLE raporcu LOGIN PASSWORD 'Raporcu2024!';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE ROLE kasiyer LOGIN PASSWORD 'Kasiyer2024!';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE ROLE db_admin LOGIN PASSWORD 'Admin2024!';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Sorgu 3: Yetkileri ver
-- raporcu — sadece okuma
GRANT CONNECT ON DATABASE dvdstore TO raporcu;
GRANT USAGE ON SCHEMA public TO raporcu;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO raporcu;

-- kasiyer — ödeme ve kiralama işlemleri
GRANT CONNECT ON DATABASE dvdstore TO kasiyer;
GRANT USAGE ON SCHEMA public TO kasiyer;
GRANT SELECT, INSERT, UPDATE ON payment TO kasiyer;
GRANT SELECT, INSERT, UPDATE ON rental  TO kasiyer;
GRANT SELECT ON customer TO kasiyer;
GRANT SELECT ON inventory TO kasiyer;
GRANT SELECT ON film TO kasiyer;

-- db_admin — her şey
GRANT CONNECT ON DATABASE dvdstore TO db_admin;
GRANT USAGE ON SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_admin;

-- Sorgu 4: Yetkileri doğrula
SELECT
    grantee         AS kullanici,
    table_name      AS tablo,
    privilege_type  AS yetki
FROM information_schema.role_table_grants
WHERE grantee IN ('raporcu', 'kasiyer', 'db_admin')
ORDER BY grantee, table_name, privilege_type;

-- -------------------------------------------------------
-- Row Level Security — satır bazında güvenlik
--   raporcu sadece aktif müşterileri görebilsin
--   (activebool = true)
-- -------------------------------------------------------

-- Sorgu 5: RLS aktif et ve politikalar tanımla
ALTER TABLE customer ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_politika ON customer;
CREATE POLICY admin_politika
    ON customer FOR ALL TO db_admin USING (true);

DROP POLICY IF EXISTS raporcu_politika ON customer;
CREATE POLICY raporcu_politika
    ON customer FOR SELECT TO raporcu
    USING (activebool = true);

ALTER TABLE customer FORCE ROW LEVEL SECURITY;

-- Politikaları görüntüle
SELECT
    polname         AS politika_adi,
    polcmd          AS komut,
    polroles        AS roller
FROM pg_policy
WHERE polrelid = 'customer'::regclass;

-- -------------------------------------------------------
-- Bağlantı limitleri
--   raporcu için 3, kasiyer için 10, db_admin sınırsız
-- -------------------------------------------------------

-- Sorgu 6: Bağlantı limitleri
ALTER ROLE raporcu    CONNECTION LIMIT 3;
ALTER ROLE kasiyer    CONNECTION LIMIT 10;
ALTER ROLE db_admin   CONNECTION LIMIT -1;

SELECT
    rolname         AS rol,
    rolconnlimit    AS baglanti_limiti
FROM pg_roles
WHERE rolname IN ('raporcu', 'kasiyer', 'db_admin');
