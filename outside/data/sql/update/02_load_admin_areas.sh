#!/bin/bash
# Use this script to load ALL administrative areas for SINP PACA.
# Usage: ./02_load_admin_areas.sh <db-name>
# Default <db-name> : geonature2db

readonly DB_USER="geonatadmin"
readonly DB_NAME="${1:-geonature2db}"
readonly DIR="$( cd "$( dirname "$0" )" && pwd )"
readonly RAW_DIR="$(realpath ${DIR}/../../raw/)"

if [[ -f "${RAW_DIR}/COM/communes_fr_2020-02.csv.tar.bz2" ]]; then
    if [[ ! -f "${RAW_DIR}/COM/communes_fr_2020-02.csv" ]]; then
        cd "${RAW_DIR}/COM/"
        tar jxvf "${RAW_DIR}/COM/communes_fr_2020-02.csv.tar.bz2"
    fi
fi

if [[ -f "${RAW_DIR}/DEP/departements_fr_2020-02.csv.tar.bz2" ]]; then
    if [[ ! -f "${RAW_DIR}/DEP/departements_fr_2020-02.csv" ]]; then
        cd "${RAW_DIR}/DEP/"
        tar jxvf "${RAW_DIR}/DEP/departements_fr_2020-02.csv.tar.bz2"
    fi
fi

psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" \
    -c "DROP TABLE IF EXISTS
            ref_geo.tmp_municipalities,
            ref_geo.tmp_departements
         ;"

psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" \
    -c "
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
        geojson character varying,
        CONSTRAINT tmp_municipalities_pkey PRIMARY KEY (gid)
    ) ;

    COPY ref_geo.tmp_municipalities FROM '${RAW_DIR}/COM/communes_fr_2020-02.csv' ;

    CREATE INDEX idx_tmp_municipalities_geom ON ref_geo.tmp_municipalities USING gist (geom) ;


    CREATE TABLE ref_geo.tmp_departements (
        gid integer NOT NULL,
        id character varying(24),
        nom_dep character varying(30),
        nom_dep_m character varying(30),
        insee_dep character varying(3),
        insee_reg character varying(2),
        chf_dep character varying(5),
        geom public.geometry(MultiPolygon,2154),
        geojson character varying,
        CONSTRAINT tmp_departements_pkey PRIMARY KEY (gid)
    ) ;

    COPY ref_geo.tmp_departements FROM '${RAW_DIR}/DEP/departements_fr_2020-02.csv' ;

    CREATE INDEX idx_tmp_departements_geom ON ref_geo.tmp_departements USING gist (geom) ;
    "

rm -f "${RAW_DIR}/COM/communes_fr_2020-02.csv"
rm -f "${RAW_DIR}/DEP/departements_fr_2020-02.csv"
