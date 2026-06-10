-- =====================================================
-- ADIM 1: ERİŞİM YÖNETİMİ VE KİMLİK DOĞRULAMA
-- Platform  : PostgreSQL 18
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- Sorgu 1: Şifre saklama yöntemi
--          scram-sha-256 ise modern ve güvenli, md5 eskidir
SHOW password_encryption;

-- Sorgu 2: SSL bağlantı durumu
SHOW ssl;

SELECT
    a.datname           AS veritabani,
    a.usename           AS kullanici,
    s.ssl                AS ssl_aktif_mi,
    s.version            AS ssl_versiyonu
FROM pg_stat_activity a
JOIN pg_stat_ssl s ON a.pid = s.pid
WHERE a.datname = 'dvdstore';

-- Sorgu 3: pg_hba.conf — hangi kullanıcı nereden, nasıl bağlanabilir
SHOW hba_file;

SELECT
    type            AS baglanti_tipi,
    database        AS veritabani,
    user_name       AS kullanici,
    address         AS adres,
    auth_method     AS dogrulama_yontemi
FROM pg_hba_file_rules;

-- -------------------------------------------------------
-- Rol bazlı erişim — müşteri destek ekibi örneği
-- -------------------------------------------------------

-- Sorgu 4: Grup rolü oluştur (login yetkisi yok, sadece yetki paketi)
DO $$ BEGIN
    CREATE ROLE musteri_destek NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

GRANT SELECT ON customer, rental, payment TO musteri_destek;

-- Sorgu 5: Gerçek kullanıcı oluştur ve gruba ekle
DO $$ BEGIN
    CREATE ROLE ayse LOGIN PASSWORD 'Ayse2024!' IN ROLE musteri_destek;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Sorgu 6: Parolanın nasıl saklandığını gör — düz metin DEĞİL, hash
SELECT rolname, rolpassword
FROM pg_authid
WHERE rolname = 'ayse';

-- Sorgu 7: Yetkileri doğrula
SELECT
    grantee         AS kullanici,
    table_name      AS tablo,
    privilege_type  AS yetki
FROM information_schema.role_table_grants
WHERE grantee = 'musteri_destek';

-- -------------------------------------------------------
-- PUBLIC şema sertleştirme — varsayılan zayıflık
-- -------------------------------------------------------

-- Sorgu 8: Varsayılan olarak herkes public şemada tablo oluşturabilir mi?
SELECT has_schema_privilege('PUBLIC', 'public', 'CREATE') AS herkes_tablo_olusturabilir;

-- Sorgu 9: Bu yetkiyi kaldır — sadece yetkili roller tablo oluşturabilsin
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

SELECT has_schema_privilege('PUBLIC', 'public', 'CREATE') AS herkes_tablo_olusturabilir_sonra;
