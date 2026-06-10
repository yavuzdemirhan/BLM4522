-- =====================================================
-- ADIM 2: VERİ ŞİFRELEME
-- Platform  : PostgreSQL 18
-- Veritabanı: dvdstore (Pagila)
-- =====================================================

-- Sorgu 1: pgcrypto eklentisini aktif et
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Sorgu 2: Şifrelemeden önce — hassas veri düz metin
SELECT customer_id, first_name, last_name, email
FROM customer
LIMIT 5;

-- Sorgu 3: Şifreli kolon ekle
ALTER TABLE customer ADD COLUMN IF NOT EXISTS email_encrypted bytea;

-- Sorgu 4: Mevcut e-postaları simetrik anahtarla şifrele
UPDATE customer
SET email_encrypted = pgp_sym_encrypt(email, 'gizli-anahtar-2024');

-- Sorgu 5: Şifreli veriyi olduğu gibi göster — okunamaz
SELECT customer_id, email_encrypted
FROM customer
LIMIT 5;

-- Sorgu 6: Doğru anahtarla deşifre et
SELECT
    customer_id,
    pgp_sym_decrypt(email_encrypted, 'gizli-anahtar-2024') AS email_cozulmus
FROM customer
LIMIT 5;

-- Sorgu 7: Yanlış anahtarla deşifre denemesi — hata verir
SELECT
    customer_id,
    pgp_sym_decrypt(email_encrypted, 'yanlis-anahtar') AS email_cozulmus
FROM customer
LIMIT 1;

-- -------------------------------------------------------
-- Parola hash'leme — asla düz metin saklanmaz
-- -------------------------------------------------------

-- Sorgu 8: bcrypt ile parola hash'le
SELECT crypt('Ayse2024!', gen_salt('bf')) AS hashlenmis_sifre;

-- Sorgu 9: Hash'i doğrula — kullanıcı giriş yaparken bu kontrol yapılır
SELECT
    (crypt('Ayse2024!', hashlenmis) = hashlenmis)  AS dogru_sifre,
    (crypt('YanlisSifre', hashlenmis) = hashlenmis) AS yanlis_sifre
FROM (SELECT crypt('Ayse2024!', gen_salt('bf')) AS hashlenmis) t;
