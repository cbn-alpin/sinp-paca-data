-- Script to export observation counts by observers types (empty or null, anonymous, unknown, with 1 observer, 2 observers; 3; 4, 5 and 6 or more observers)
-- Usage (from local computer): cat ./observations_count_by_observers.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_observers.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    SELECT
        SUM(CASE WHEN (observers IS NULL OR observers = '') THEN 1 ELSE 0 END) AS empty_or_null,
        SUM(CASE WHEN (observers ILIKE '%ANONYME%') THEN 1 ELSE 0 END) AS anonymous,
        SUM(CASE WHEN (observers ILIKE '%INCONNU%'and not (observers ILIKE '%(INCONNU)%' )) THEN 1 ELSE 0 END) AS "unknown",
        -- les observateurs ANONYME et INCONNU sont aussi pris en compte dans les classes ci-dessous
        SUM(CASE WHEN (length(observers) - length(replace(observers, ',', '')) )::int = 0  THEN 1 ELSE 0 END) AS one_observer,
        SUM(CASE WHEN (length(observers) - length(replace(observers, ',', '')) )::int = 1  THEN 1 ELSE 0 END) AS two_observers,
        SUM(CASE WHEN (length(observers) - length(replace(observers, ',', '')) )::int = 2  THEN 1 ELSE 0 END) AS three_observers,
        SUM(CASE WHEN (length(observers) - length(replace(observers, ',', '')) )::int = 3  THEN 1 ELSE 0 END) AS four_observers,
        SUM(CASE WHEN (length(observers) - length(replace(observers, ',', '')) )::int = 4  THEN 1 ELSE 0 END) AS five_observers,
        SUM(CASE WHEN (length(observers) - length(replace(observers, ',', '')) )::int >= 5  THEN 1 ELSE 0 END) AS six_and_more_observers,
        COUNT(id_synthese) AS total
    FROM gn_synthese.synthese
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
