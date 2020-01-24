-- Create extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Reset all import
DROP TABLE IF EXISTS imports_cbna.flore_v20190123;
DROP TABLE IF EXISTS ref_geo.tmp_region;