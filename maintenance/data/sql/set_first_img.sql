BEGIN;

WITH exists_first_medias AS (
    SELECT
        cd_ref
    FROM
        taxonomie.t_medias AS stm
    WHERE
        id_type = 1
),
first_media AS (
    SELECT MIN(id_media) AS first_id_media_founded, cd_ref
    FROM taxonomie.t_medias
    WHERE cd_ref NOT IN (
            SELECT
                cd_ref
            FROM
                exists_first_medias
        )
    GROUP BY cd_ref
)
UPDATE taxonomie.t_medias AS tm
    SET id_type = 1
    FROM first_media AS fm
    WHERE tm.id_media = fm.first_id_media_founded
        AND tm.cd_ref = fm.cd_ref ;

COMMIT;
