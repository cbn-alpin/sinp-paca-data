--------------
-- IMPORTANT--
--------------
-- A exécuter avec l'utilisateur propriétaire de la BDD (owner_atlas dans main/configuration/settings.ini).
-- Ce script vous permet de recréer la vue atlas.vm_observations en l'adaptant à vos besoins.
-- Pour cela toutes les vues qui en dépendent doivent être supprimées puis recréées.
-- Si votre utilisateur PostgreSQL en lecture seule sur ces vues n'est pas "geonatatlas" (celui utilisé par l'application web de l'atlas, user_pg dans main/configuration/settings.ini),
-- vous devez modifier les GRANT à la fin de ce script avec le nom de votre utilisateur avant de l'exécuter.

BEGIN;

--------------------------------------------------------------
-- SUPPRESSION DES VUES DEPENDANT DE LA VUE VM_OBSERVATIONS --
--------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_taxons_plus_observes;
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_search_taxon;
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_taxons;
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_mois;
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_altitudes;
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_observations_mailles;
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_observations;
DROP MATERIALIZED VIEW IF EXISTS atlas.t_subdivided_territory;

---------------------------------------------
-- MODIFIER VOUS-MEME LE SCRIPT CI-DESSOUS --
-- DE CREATION DE LA VUE VM_OBSERVATIONS ----
---------------------------------------------

-- Materialized View: atlas.t_subdivided_territory
CREATE MATERIALIZED VIEW atlas.t_subdivided_territory
TABLESPACE pg_default
AS
	WITH d AS (
		SELECT st_union(l.geom) AS st_union
		FROM ref_geo.l_areas AS l
			JOIN ref_geo.bib_areas_types AS b USING (id_type)
		WHERE replace(b.type_code::text, ' '::text, '_'::text) = 'SINP'::text
		GROUP BY b.type_name
	)
	SELECT
		random() AS gid,
		1 AS territory_layer_id,
		st_subdivide(st_transform(d.st_union, 3857), 255) AS geom
	FROM d
WITH DATA;

-- View indexes:
CREATE INDEX index_gist_t_subdivided_territory_geom ON atlas.t_subdivided_territory USING gist (geom);
CREATE UNIQUE INDEX t_subdivided_territory_gid_idx ON atlas.t_subdivided_territory USING btree (gid);

-- Materialized View: atlas.vm_observations
-- TIMING: ~18mn for territory PACA french PACA region, ~1,000 municipalities and ~9,300,000 of rows
-- in synthese table on OVH Block Storage disk.
-- TIMING: ~7mn for territory PACA french PACA region, ~1,000 municipalities and ~9,300,000 of rows
-- in synthese table on SSD Nvme disk.
CREATE MATERIALIZED VIEW atlas.vm_observations AS
	SELECT s.id_synthese AS id_observation,
		s.insee,
		s.dateobs,
		s.observateurs,
		s.altitude_retenue,
		s.the_geom_point::geometry(Point,3857) AS the_geom_point,
		s.effectif_total,
		tx.cd_ref,
		st_asgeojson(st_transform(st_setsrid(s.the_geom_point, 3857), 4326)) AS geojson_point,
		s.diffusion_level
	FROM synthese.syntheseff AS s
		LEFT JOIN atlas.vm_taxref AS tx ON tx.cd_nom = s.cd_nom
	WHERE EXISTS (
		SELECT 'X'
		FROM atlas.t_subdivided_territory AS m
		WHERE st_intersects(m.geom, s.the_geom_point)
	)
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_observations (id_observation);
CREATE INDEX ON atlas.vm_observations (cd_ref);
CREATE INDEX ON atlas.vm_observations (insee);
CREATE INDEX ON atlas.vm_observations (altitude_retenue);
CREATE INDEX ON atlas.vm_observations (dateobs);
CREATE INDEX index_gist_vm_observations_the_geom_point ON atlas.vm_observations USING gist (the_geom_point);


-- Materialized View: atlas.vm_taxons
CREATE MATERIALIZED VIEW atlas.vm_taxons AS
 WITH obs_min_taxons AS (
         SELECT vm_observations.cd_ref,
            min(date_part('year'::text, vm_observations.dateobs)) AS yearmin,
            max(date_part('year'::text, vm_observations.dateobs)) AS yearmax,
            count(vm_observations.id_observation) AS nb_obs
           FROM atlas.vm_observations
          GROUP BY vm_observations.cd_ref
        ), tx_ref AS (
         SELECT tx_1.cd_ref,
            tx_1.regne,
            tx_1.phylum,
            tx_1.classe,
            tx_1.ordre,
            tx_1.famille,
            tx_1.cd_taxsup,
            tx_1.lb_nom,
            tx_1.lb_auteur,
            tx_1.nom_complet,
            tx_1.nom_valide,
            tx_1.nom_vern,
            tx_1.nom_vern_eng,
            tx_1.group1_inpn,
            tx_1.group2_inpn,
            tx_1.nom_complet_html,
            tx_1.id_rang
           FROM atlas.vm_taxref tx_1
          WHERE (tx_1.cd_ref IN ( SELECT obs_min_taxons.cd_ref
                   FROM obs_min_taxons)) AND tx_1.cd_nom = tx_1.cd_ref
        ), my_taxons AS (
         SELECT DISTINCT n.cd_ref,
            pat.valeur_attribut AS patrimonial,
            pr.valeur_attribut AS protection_stricte
           FROM tx_ref n
             LEFT JOIN taxonomie.cor_taxon_attribut pat ON pat.cd_ref = n.cd_ref AND pat.id_attribut = 1
             LEFT JOIN taxonomie.cor_taxon_attribut pr ON pr.cd_ref = n.cd_ref AND pr.id_attribut = 2
          WHERE (n.cd_ref IN ( SELECT obs_min_taxons.cd_ref
                   FROM obs_min_taxons))
        )
 SELECT tx.cd_ref,
    tx.regne,
    tx.phylum,
    tx.classe,
    tx.ordre,
    tx.famille,
    tx.cd_taxsup,
    tx.lb_nom,
    tx.lb_auteur,
    tx.nom_complet,
    tx.nom_valide,
    tx.nom_vern,
    tx.nom_vern_eng,
    tx.group1_inpn,
    tx.group2_inpn,
    tx.nom_complet_html,
    tx.id_rang,
    t.patrimonial,
    t.protection_stricte,
    omt.yearmin,
    omt.yearmax,
    omt.nb_obs
   FROM tx_ref tx
     LEFT JOIN obs_min_taxons omt ON omt.cd_ref = tx.cd_ref
     LEFT JOIN my_taxons t ON t.cd_ref = tx.cd_ref
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_taxons (cd_ref);


-- Materialized View: atlas.vm_search_taxon
CREATE MATERIALIZED VIEW atlas.vm_search_taxon AS
SELECT row_number() OVER (ORDER BY t.cd_nom,t.cd_ref,t.search_name)::integer AS fid,
  t.cd_nom,
  t.cd_ref,
  t.search_name,
  t.nom_valide,
  t.lb_nom
FROM (
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.lb_nom, ' =  <i> ', t_1.nom_valide, '</i>') AS search_name,
        t_1.nom_valide,
        t_1.lb_nom
  FROM atlas.vm_taxref t_1

  UNION
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.nom_vern, ' =  <i> ', t_1.nom_valide, '</i>' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom
  FROM atlas.vm_taxref t_1
  WHERE t_1.nom_vern IS NOT NULL AND t_1.cd_nom = t_1.cd_ref
) t
JOIN atlas.vm_taxons taxons ON taxons.cd_ref = t.cd_ref;

CREATE UNIQUE INDEX ON atlas.vm_search_taxon(fid);
CREATE INDEX ON atlas.vm_search_taxon(cd_nom);
CREATE INDEX ON atlas.vm_search_taxon(cd_ref);
CREATE INDEX trgm_idx ON atlas.vm_search_taxon USING GIST (search_name gist_trgm_ops);
CREATE UNIQUE INDEX ON atlas.vm_search_taxon (cd_nom, search_name);

-- Materialized View: atlas.vm_mois
CREATE MATERIALIZED VIEW atlas.vm_mois AS
 WITH _01 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '1'::double precision
          GROUP BY vm_observations.cd_ref
        ), _02 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '2'::double precision
          GROUP BY vm_observations.cd_ref
        ), _03 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '3'::double precision
          GROUP BY vm_observations.cd_ref
        ), _04 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '4'::double precision
          GROUP BY vm_observations.cd_ref
        ), _05 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '5'::double precision
          GROUP BY vm_observations.cd_ref
        ), _06 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '6'::double precision
          GROUP BY vm_observations.cd_ref
        ), _07 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '7'::double precision
          GROUP BY vm_observations.cd_ref
        ), _08 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '8'::double precision
          GROUP BY vm_observations.cd_ref
        ), _09 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '9'::double precision
          GROUP BY vm_observations.cd_ref
        ), _10 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '10'::double precision
          GROUP BY vm_observations.cd_ref
        ), _11 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '11'::double precision
          GROUP BY vm_observations.cd_ref
        ), _12 AS (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE date_part('month'::text, vm_observations.dateobs) = '12'::double precision
          GROUP BY vm_observations.cd_ref
        )
 SELECT DISTINCT o.cd_ref,
    COALESCE(a.nb::integer, 0) AS _01,
    COALESCE(b.nb::integer, 0) AS _02,
    COALESCE(c.nb::integer, 0) AS _03,
    COALESCE(d.nb::integer, 0) AS _04,
    COALESCE(e.nb::integer, 0) AS _05,
    COALESCE(f.nb::integer, 0) AS _06,
    COALESCE(g.nb::integer, 0) AS _07,
    COALESCE(h.nb::integer, 0) AS _08,
    COALESCE(i.nb::integer, 0) AS _09,
    COALESCE(j.nb::integer, 0) AS _10,
    COALESCE(k.nb::integer, 0) AS _11,
    COALESCE(l.nb::integer, 0) AS _12
   FROM atlas.vm_observations o
     LEFT JOIN _01 a ON a.cd_ref = o.cd_ref
     LEFT JOIN _02 b ON b.cd_ref = o.cd_ref
     LEFT JOIN _03 c ON c.cd_ref = o.cd_ref
     LEFT JOIN _04 d ON d.cd_ref = o.cd_ref
     LEFT JOIN _05 e ON e.cd_ref = o.cd_ref
     LEFT JOIN _06 f ON f.cd_ref = o.cd_ref
     LEFT JOIN _07 g ON g.cd_ref = o.cd_ref
     LEFT JOIN _08 h ON h.cd_ref = o.cd_ref
     LEFT JOIN _09 i ON i.cd_ref = o.cd_ref
     LEFT JOIN _10 j ON j.cd_ref = o.cd_ref
     LEFT JOIN _11 k ON k.cd_ref = o.cd_ref
     LEFT JOIN _12 l ON l.cd_ref = o.cd_ref
  WHERE o.cd_ref IS NOT NULL
  ORDER BY o.cd_ref
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_mois (cd_ref);


-- Materialized View: atlas.vm_taxons_plus_observes
CREATE MATERIALIZED VIEW atlas.vm_taxons_plus_observes AS
SELECT count(*) AS nb_obs,
   obs.cd_ref,
   tax.lb_nom,
   tax.group2_inpn,
   tax.nom_vern,
   m.id_media,
   m.url,
   m.chemin,
   m.id_type
  FROM atlas.vm_observations obs
    JOIN atlas.vm_taxons tax ON tax.cd_ref = obs.cd_ref
    LEFT JOIN atlas.vm_medias m ON m.cd_ref = obs.cd_ref AND m.id_type = 1
 WHERE date_part('day'::text, obs.dateobs) >= date_part('day'::text, 'now'::text::date - 15) AND date_part('month'::text, obs.dateobs) = date_part('month'::text, 'now'::text::date - 15) OR date_part('day'::text, obs.dateobs) <= date_part('day'::text, 'now'::text::date + 15) AND date_part('month'::text, obs.dateobs) = date_part('day'::text, 'now'::text::date + 15)
 GROUP BY obs.cd_ref, tax.lb_nom, tax.nom_vern, m.url, m.chemin, tax.group2_inpn, m.id_type, m.id_media
 ORDER BY (count(*)) DESC
LIMIT 12
WITH DATA;

-- DROP INDEX atlas.vm_taxons_plus_observes_cd_ref_idx;

CREATE UNIQUE INDEX vm_taxons_plus_observes_cd_ref_idx
  ON atlas.vm_taxons_plus_observes
  USING btree
  (cd_ref);


-- Materialized View: atlas.vm_observations_mailles
CREATE MATERIALIZED VIEW atlas.vm_observations_mailles AS
 SELECT obs.cd_ref,
    obs.id_observation,
    m.id_maille,
    m.geojson_maille,
    date_part('year', dateobs) as annee
   FROM atlas.vm_observations obs
     JOIN atlas.t_mailles_territoire m ON st_intersects(obs.the_geom_point, m.the_geom)
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_observations_mailles (id_observation);
CREATE INDEX ON atlas.vm_observations_mailles (id_maille);
CREATE INDEX ON atlas.vm_observations_mailles (cd_ref);
CREATE INDEX ON atlas.vm_observations_mailles (geojson_maille);
CREATE INDEX ON atlas.vm_observations_mailles (annee);


-- Materialized View: atlas.vm_altitudes (créé par une fonction dans la BDD)
SELECT atlas.create_vm_altitudes();


-- Rétablir les droits SELECT à l'utilisateur de l'application GeoNature-atlas (user_pg dans main/configuration/settings.ini).
-- Remplacer geonatatlas par votre utilisateur de BDD si vous l'avez modifié.
GRANT SELECT ON TABLE atlas.l_communes TO geonatatlas;
GRANT SELECT ON TABLE atlas.t_layer_territoire TO geonatatlas;
GRANT SELECT ON TABLE atlas.t_mailles_territoire TO geonatatlas;
GRANT SELECT ON TABLE atlas.t_subdivided_territory TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_altitudes TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_communes TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_cor_taxon_attribut TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_medias TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_mois TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_observations TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_observations_mailles TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_search_taxon TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_taxons TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_taxons_plus_observes TO geonatatlas;

COMMIT;
