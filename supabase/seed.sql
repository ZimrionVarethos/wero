-- Seed administrative regions (Regencies & Cities) for user profile default region selection
INSERT INTO public.regions (code, name, level, is_active)
VALUES
  ('3171', 'Kota Jakarta Pusat', 'CITY', true),
  ('3172', 'Kota Jakarta Utara', 'CITY', true),
  ('3173', 'Kota Jakarta Barat', 'CITY', true),
  ('3174', 'Kota Jakarta Selatan', 'CITY', true),
  ('3175', 'Kota Jakarta Timur', 'CITY', true),
  ('3273', 'Kota Bandung', 'CITY', true),
  ('3201', 'Kabupaten Bogor', 'REGENCY', true),
  ('3275', 'Kota Bekasi', 'CITY', true),
  ('3276', 'Kota Depok', 'CITY', true),
  ('3374', 'Kota Semarang', 'CITY', true),
  ('3471', 'Kota Yogyakarta', 'CITY', true),
  ('3404', 'Kabupaten Sleman', 'REGENCY', true),
  ('3578', 'Kota Surabaya', 'CITY', true),
  ('3573', 'Kota Malang', 'CITY', true),
  ('5171', 'Kota Denpasar', 'CITY', true),
  ('5103', 'Kabupaten Badung', 'REGENCY', true),
  ('1271', 'Kota Medan', 'CITY', true),
  ('1371', 'Kota Padang', 'CITY', true),
  ('1671', 'Kota Palembang', 'CITY', true),
  ('7371', 'Kota Makassar', 'CITY', true),
  ('6471', 'Kota Balikpapan', 'CITY', true),
  ('7171', 'Kota Manado', 'CITY', true)
ON CONFLICT (code) DO NOTHING;
