-- Utils functions for indicators queries
-- Execute this file with GeoNature database owner.

DROP FUNCTION gn_synthese.get_precision_label;
CREATE OR REPLACE FUNCTION gn_synthese.get_precision_label(precision_value integer)
 RETURNS varchar
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    -- Function which return the precision label from a precision value in meter
    DECLARE precisionLabel varchar;

    BEGIN
        SELECT INTO precisionLabel
            CASE
                WHEN precision_value <= 25 THEN 'précis'
                WHEN precision_value > 25 AND precision_value <= 250  THEN 'lieu-dit'
                WHEN precision_value > 250 THEN 'commune'
                ELSE 'indéterminé'
            END ;

        RETURN precisionLabel ;
    END;
$function$ ;

DROP FUNCTION gn_imports.select_imports_stats;
CREATE OR REPLACE FUNCTION gn_imports.select_imports_stats()
	RETURNS TABLE ( administrator varchar, import_date date, obs_insert int, obs_update int, obs_delete int)
AS $func$
	DECLARE
		stats_query TEXT = '' ;
		synthese_table RECORD;
		table_synth_name TEXT;
		table_synth_schema TEXT;

	BEGIN
		FOR synthese_table IN
			SELECT table_name
			FROM information_schema.tables
			WHERE table_schema = 'gn_imports'
				AND table_name LIKE '%_synthese'
		LOOP
			table_synth_name = synthese_table.table_name;
			table_synth_schema = 'gn_imports';

			IF stats_query <> '' THEN
				stats_query := stats_query || E'\n\n UNION \n';
			END IF;

			stats_query = stats_query || format('
				SELECT
					split_part(''%s'', ''_'', 1) AS administrator,
					split_part(''%s'', ''_'', 2) AS import_date,
					MAX(obs_insert) AS obs_insert,
					MAX(obs_update) AS obs_update,
					MAX(obs_delete) AS obs_delete
				FROM ( SELECT
							COUNT(*) AS obs_insert,
							NULL::int AS obs_update,
							NULL::int AS obs_delete
						FROM %I.%I
						WHERE meta_last_action = ''I''
						UNION
						SELECT
							NULL::int AS obs_insert,
							COUNT(*) AS obs_update,
							NULL::int AS obs_delete
						FROM %I.%I
						WHERE meta_last_action = ''U''
						UNION
						SELECT
							NULL::int AS obs_insert,
							NULL::int AS obs_update,
							COUNT(*) AS obs_delete
						FROM %I.%I
						WHERE meta_last_action = ''D''
					) AS imports_data
				GROUP BY administrator, import_date', table_synth_name, table_synth_name, table_synth_schema, table_synth_name, table_synth_schema, table_synth_name, table_synth_schema, table_synth_name) ;
		END LOOP;

		stats_query = E'SELECT administrator::varchar, import_date::date, obs_insert::int, obs_update::int, obs_delete::int FROM (\n' || stats_query || E'\n) AS count_rows ORDER BY administrator, import_date ';
		--RAISE NOTICE '%', stats_query;
		RETURN QUERY EXECUTE stats_query;
	END;
$func$ LANGUAGE plpgsql ;
