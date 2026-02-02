--nombre d'observations par départements, par règne pour une année (à choisir)
WITH kingdoms_counts AS (
        SELECT
            la.area_code,
            la.area_name,
            t.regne AS kingdom,
            COUNT(s.id_synthese) AS obs_nbr
        FROM gn_synthese.synthese AS s
            JOIN gn_synthese.cor_area_synthese AS cas
                ON s.id_synthese = cas.id_synthese
            JOIN ref_geo.l_areas AS la
                ON la.id_area = cas.id_area
            JOIN ref_geo.bib_areas_types AS bat
                ON bat.id_type = la.id_type
            JOIN taxonomie.taxref AS t
                ON t.cd_nom = s.cd_nom
        WHERE bat.type_code = 'DEP' and date_part('year',s.date_max ) = 2025
        GROUP BY la.area_code, la.area_name, t.regne
    )
    SELECT
        area_code AS code_dept,
        area_name AS dept,
        kingdom AS regne,
        obs_nbr AS obs_nbre
    FROM (
        SELECT
            area_code,
            area_name,
            kingdom,
            obs_nbr,
            0 AS sort_order
        FROM kingdoms_counts

        UNION

        SELECT
            kc.area_code,
            kc.area_name,
            'Total' AS kingdom,
            SUM(kc.obs_nbr) AS obs_nbr,
            1 AS sort_order
        FROM kingdoms_counts AS kc
        GROUP BY kc.area_code, kc.area_name
    ) AS counts_and_total
    ORDER BY area_code, sort_order, kingdom
