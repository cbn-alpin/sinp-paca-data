BEGIN;

DROP MATERIALIZED VIEW IF EXISTS atlas.vm_communes ;

CREATE MATERIALIZED VIEW atlas.vm_communes
TABLESPACE pg_default
AS
	SELECT DISTINCT
		c.insee,
	    c.commune_maj,
	    c.the_geom,
	    c.commune_geojson
	FROM atlas.l_communes c
		JOIN atlas.t_subdivided_territory t
			ON (st_intersects(t.geom, c.the_geom))
WITH DATA;

-- View indexes:
CREATE UNIQUE INDEX vm_communes_insee_idx ON atlas.vm_communes USING btree (insee);
CREATE INDEX vm_communes_commune_maj_idx ON atlas.vm_communes USING btree (commune_maj);
CREATE INDEX index_gist_vm_communes_the_geom ON atlas.vm_communes USING gist (the_geom);


GRANT SELECT ON TABLE atlas.vm_communes TO geonatatlas;

COMMIT;
