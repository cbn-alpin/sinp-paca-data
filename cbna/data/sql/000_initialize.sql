-- Droits d'éxecution nécessaire : SUPER UTILISATUER
-- Create extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Reset all import
DROP TABLE IF EXISTS ref_geo.tmp_region;