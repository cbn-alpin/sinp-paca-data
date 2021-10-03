#!/bin/bash
# Use this script to load ALL INPN M10 meshes and marine M5 meshes for
# south-east of France not existing in INPN file.
#
# Usage: ./02_load_meshes.sh <db-name>
# Default <db-name> : geonature2db

readonly DB_USER="geonatadmin"
readonly DB_NAME="${1:-geonature2db}"
readonly DIR="$( cd "$( dirname "$0" )" && pwd )"
readonly RAW_DIR="$(realpath ${DIR}/../../raw/)"

if [[ -f "${RAW_DIR}/M1/inpn_grids_1.csv.tar.bz2" ]]; then
    if [[ ! -f "${RAW_DIR}/M1/inpn_grids_1.csv" ]]; then
        cd "${RAW_DIR}/M1/"
        tar jxvf "${RAW_DIR}/M1/inpn_grids_1.csv.tar.bz2"
    fi
fi

if [[ -f "${RAW_DIR}/M5/inpn_grids_5.csv.tar.bz2" ]]; then
    if [[ ! -f "${RAW_DIR}/M5/inpn_grids_5.csv" ]]; then
        cd "${RAW_DIR}/M5/"
        tar jxvf "${RAW_DIR}/M5/inpn_grids_5.csv.tar.bz2"
    fi
fi

if [[ -f "${RAW_DIR}/M10/inpn_grids_10.csv.tar.bz2" ]]; then
    if [[ ! -f "${RAW_DIR}/M10/inpn_grids_10.csv" ]]; then
        cd "${RAW_DIR}/M10/"
        tar jxvf "${RAW_DIR}/M10/inpn_grids_10.csv.tar.bz2"
    fi
fi

if [[ -f "${RAW_DIR}/COM/communes_fr_2020-02.csv.tar.bz2" ]]; then
    if [[ ! -f "${RAW_DIR}/COM/communes_fr_2020-02.csv" ]]; then
        cd "${RAW_DIR}/COM/"
        tar jxvf "${RAW_DIR}/COM/communes_fr_2020-02.csv.tar.bz2"
    fi
fi

psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" \
    -c "DROP TABLE IF EXISTS
            ref_geo.tmp_m1,
            ref_geo.tmp_m5,
            ref_geo.tmp_m5_marine,
            ref_geo.tmp_m10,
            ref_geo.tmp_municipalities
         ;"

shp2pgsql -d -s 2154 "${RAW_DIR}/M5-SE/M5-SE.shp" "ref_geo.tmp_m5_marine" | \
    psql -h localhost -U "${DB_USER}" -d "${DB_NAME}"

psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" \
    -c "
    CREATE INDEX idx_tmp_m5_marine_geom ON ref_geo.tmp_m5_marine USING gist (geom);

    CREATE TABLE ref_geo.tmp_m10 (
        gid integer NOT NULL,
        cd_sig character varying(21),
        code character varying(10),
        geom public.geometry(MultiPolygon,2154),
        geojson character varying
    );

    ALTER TABLE ONLY ref_geo.tmp_m10 ADD CONSTRAINT tmp_m10_pkey PRIMARY KEY (gid);

    COPY ref_geo.tmp_m10 FROM '${RAW_DIR}/M10/inpn_grids_10.csv' ;

    CREATE INDEX idx_tmp_m10_geom ON ref_geo.tmp_m10 USING gist (geom);

    CREATE TABLE ref_geo.tmp_m5 (
        gid integer NOT NULL,
        cd_sig character varying(21),
        code character varying(10),
        geom public.geometry(MultiPolygon,2154),
        geojson character varying
    );

    ALTER TABLE ONLY ref_geo.tmp_m5 ADD CONSTRAINT tmp_m5_pkey PRIMARY KEY (gid);

    COPY ref_geo.tmp_m5 FROM '${RAW_DIR}/M5/inpn_grids_5.csv' ;

    CREATE INDEX idx_tmp_m5_geom ON ref_geo.tmp_m5 USING gist (geom);

    CREATE TABLE ref_geo.tmp_m1 (
        gid integer NOT NULL,
        cd_sig character varying(21),
        code character varying(10),
        geom public.geometry(MultiPolygon,2154),
        geojson character varying
    );

    ALTER TABLE ONLY ref_geo.tmp_m1 ADD CONSTRAINT tmp_m1_pkey PRIMARY KEY (gid);

    COPY ref_geo.tmp_m1 FROM '${RAW_DIR}/M1/inpn_grids_1.csv' ;

    CREATE INDEX idx_tmp_m1_geom ON ref_geo.tmp_m1 USING gist (geom);

    CREATE TABLE ref_geo.tmp_municipalities (
            gid integer NOT NULL,
            id character varying(24),
            nom_com character varying(50),
            nom_com_m character varying(50),
            insee_com character varying(5),
            statut character varying(24),
            insee_can character varying(2),
            insee_arr character varying(2),
            insee_dep character varying(3),
            insee_reg character varying(2),
            code_epci character varying(21),
            population bigint,
            type character varying(3),
            geom public.geometry(MultiPolygon,2154),
            geojson character varying
        ) ;

    ALTER TABLE ONLY ref_geo.tmp_municipalities ADD CONSTRAINT tmp_municipalities_pkey PRIMARY KEY (gid) ;

    COPY ref_geo.tmp_municipalities FROM '${RAW_DIR}/COM/communes_fr_2020-02.csv' ;

    CREATE INDEX idx_tmp_municipalities_geom ON ref_geo.tmp_municipalities USING gist (geom) ;
    "

rm -f "${RAW_DIR}/M1/inpn_grids_1.csv"
rm -f "${RAW_DIR}/M5/inpn_grids_5.csv"
rm -f "${RAW_DIR}/M10/inpn_grids_10.csv"
rm -f "${RAW_DIR}/COM/communes_fr_2020-02.csv"
