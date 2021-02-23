\echo '-------------------------------------------------------------------------------'
\echo 'Deleting previously loaded data in synthese'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_source_by_name()"'
CREATE OR REPLACE FUNCTION gn_synthese.get_id_source_by_name(sourceName character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_source from an name_source
    DECLARE idSource integer;

    BEGIN
        SELECT INTO idSource id_source
        FROM gn_synthese.t_sources AS ts
        WHERE ts.name_source = sourceName ;

        RETURN idSource ;
    END;
$function$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Delete previous data loaded in synthese from this sources'
DELETE FROM gn_synthese.synthese
WHERE id_source IN (
    SELECT gn_synthese.get_id_source_by_name(tmp.name_source)
    FROM gn_synthese.tmp_sources AS tmp
) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT ;
