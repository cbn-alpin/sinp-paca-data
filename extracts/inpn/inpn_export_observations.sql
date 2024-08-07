-- Query to extracts observation for SINP
-- Usage (from local computer): cat ./inpn_export_observations.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_inpn_obs_extracts.csv

COPY (
WITH 

----extraction organismes gestionnaires des données
cda AS (
		-- ATTENTION : pas de récupération de l'organisme d'un utilisateur lié.
		SELECT
			d.id_dataset,
			string_agg(DISTINCT orga.nom_organisme::TEXT, ', '::TEXT) AS acteurs
		FROM gn_meta.t_datasets AS d
			JOIN gn_meta.cor_dataset_actor AS act 
				ON act.id_dataset = d.id_dataset
			JOIN utilisateurs.bib_organismes AS orga 
				ON orga.id_organisme = act.id_organism	
		GROUP BY d.id_dataset
	),
	
----extraction mailles rattachées à id_synthese
	mailles AS (
			select 
			s.id_synthese,
			'grille nationale 5km x 5km' as typelocalisation, --7 
			string_agg(la.area_name,'|') as codelocalisation
		FROM gn_synthese.synthese AS s
		join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
		join ref_geo.l_areas la on cas.id_area = la.id_area 
		--JOIN ref_geo.l_areas AS a ON st_within(st_transform(s.the_geom_point, 2154), a.geom)
		JOIN ref_geo.bib_areas_types AS bat ON bat.id_type = la.id_type 
		WHERE bat.type_code = 'M5'
			--AND s.the_geom_point IS NOT null
		group by s.id_synthese
	),
	
----extraction précision de la localisation et code insee
	champ_jsonb as (
select id_synthese,specs."precisionLabel" as precisionlabel,specs."communeInseeCode" as insee
from gn_synthese.synthese,jsonb_to_record(additional_data) AS specs("precisionLabel" text,"communeInseeCode" text )
),
----Faune, floutage à la maille 5 km ; récupération de la du code de la maille 
	faune AS (
		SELECT
			s.id_synthese,
			NULL as geometrie,
			NULL AS nomLieu,
			NULL AS comment_context ,
			NULL AS comment_description,
			'OUI' AS deefloutage,
			NULL AS sensireferentiel,
			NULL AS sensiversionreferentiel,
			m.typelocalisation,
			m.codelocalisation
		FROM gn_synthese.synthese AS s
			JOIN taxonomie.taxref AS t 
				ON s.cd_nom = t.cd_nom
			JOIN mailles AS m 
				ON s.id_synthese = m.id_synthese
		WHERE t.regne = 'Animalia'
	),
----Flore Pr/NSP floutage à la maille 5 km ; récupération de la du code de la maille
	flore_pr AS (
		SELECT
			s.id_synthese,
			NULL as geometrie,
			NULL AS nomLieu,
			NULL AS comment_context,
			NULL AS comment_description,
			'OUI' AS deefloutage,
			CASE s.id_nomenclature_sensitivity 
				WHEN 66 THEN 'Van Es J., Noble V., Garraud L., Abdulhak S. & Michaud H. 2021. Définition de la liste des espèces sensibles de la flore vasculaire de la région Sud. Conservatoire botanique national alpin et Conservatoire botanique national méditerranéen. 19 p.'
				ELSE NULL
			END AS sensireferentiel,
			CASE s.id_nomenclature_sensitivity 
				WHEN 66 THEN '2021'
				ELSE NULL
			END AS sensiversionreferentiel,
			m.typelocalisation,
			m.codelocalisation
		FROM gn_synthese.synthese AS s
			JOIN taxonomie.taxref AS t 
				ON s.cd_nom = t.cd_nom
			JOIN gn_meta.t_datasets AS td
				ON s.id_dataset = td.id_dataset
			JOIN mailles AS m 
				ON s.id_synthese = m.id_synthese
		WHERE t.regne IN ('Plantae', 'Fungi', 'Protozoa')
			AND td.id_nomenclature_data_origin IN (74, 75)
	),
	
----Flore Pu non floutée
	
	flore_pu AS (
		SELECT
			s.id_synthese ,
			case 
				when cj.precisionlabel ='commune' then NULL
				else st_asewkt(s.the_geom_local)				
			end AS geometrie,

			s.place_name AS nomLieu,
			s.comment_context ,
			s.comment_description,
			n16.label_default AS deefloutage ,
			CASE s.id_nomenclature_sensitivity 
				WHEN 66 THEN 'Van Es J., Noble V., Garraud L., Abdulhak S. & Michaud H. 2021. Définition de la liste des espèces sensibles de la flore vasculaire de la région Sud. Conservatoire botanique national alpin et Conservatoire botanique national méditerranéen. 19 p.'
				ELSE NULL
			END AS sensireferentiel,
			CASE s.id_nomenclature_sensitivity 
				WHEN 66 THEN '2021'
				ELSE NULL
			END AS sensiversionreferentiel,
			case 
				when cj.precisionlabel ='commune' and LENGTH(insee) = 5 then 'commune' --2
				when cj.precisionlabel ='commune' and LENGTH(insee) = 2 then 'département' --3
				else 'géométrie' --5
			end as typelocalisation,
			case 
				when cj.precisionlabel ='commune' then cj.insee
				else NULL
			end as codelocalisation

		FROM gn_synthese.synthese AS s
			JOIN taxonomie.taxref AS t
				ON s.cd_nom = t.cd_nom
			JOIN gn_meta.t_datasets AS td 
				ON s.id_dataset = td.id_dataset
			LEFT JOIN ref_nomenclatures.t_nomenclatures AS n16 
				ON s.id_nomenclature_blurring = n16.id_nomenclature
			LEFT JOIN champ_jsonb AS cj 
				ON s.id_synthese = cj.id_synthese
		WHERE t.regne IN ('Plantae', 'Fungi', 'Protozoa')
			AND td.id_nomenclature_data_origin NOT IN (74, 75)
	),
----Fusion des 3 requêtes : faune, flore Pr et flore Pu
	observations AS (
		SELECT * FROM faune
		UNION
		SELECT * FROM flore_pr
		UNION
		SELECT * FROM flore_pu
	)
	
----requêt finale	
	SELECT
		--sujet observation
		s.unique_id_sinp AS "idSINPOccTax",
		n15.label_default AS "statutObservation",
		s.nom_cite AS "nomCite",
		gl.geometrie,
		gl.typelocalisation as "typeLocalisation",
		gl.codelocalisation as "codeLocalisation",
		n1.label_default AS "natureObjetGeo",
		case 
			when gl.typelocalisation = 'géométrie' then s.precision
			else null --pour precisiongeometrie quand maille ou commune ou département, ...
		end as "precisionGeometrie",
		gl.nomLieu,
		s.date_min::date AS "dateDebut",
		s.date_min::time WITHOUT time ZONE AS "heureDebut",
		s.date_max::date AS "dateFin",
		s.date_max::time WITHOUT time ZONE AS "heureFin",
		t.cd_nom AS "cdNom",
		n22.label_default AS "niveauValidationValRegOuNat",
		s.determiner AS determinateur,
		s.meta_create_date AS "dateDetermination",
		s.altitude_min AS "altitudeMin",
		(s.altitude_min + s.altitude_max) / 2 AS "altitudeMoyenne",
		s.altitude_max AS "altitudeMax",
		s.count_min AS "denombrementMin",
		s.count_max AS "denombrementMax",
		s.depth_min AS "profondeurMin",
		(s.depth_max - s.depth_min) / 2 AS "profondeurMoyenne",
		s.depth_max AS "profondeurMax",
		s.observers AS observateur,
		gl.comment_context AS commentaire,
		--Source
		COALESCE(s.meta_update_date, s.meta_create_date) AS "dEEDateDerniereModification",
		s.meta_update_date AS "dEEDateTransformation",
		gl.deefloutage AS "dEEFloutage",
		n9.label_default AS "diffusionNiveauPrecision",
		n21.label_default AS "dSPublique",
		s.entity_source_pk_value AS "idOrigine",
		d.unique_dataset_id AS "idSINPJdd",
		cda.acteurs AS "organismeGestionnaireDonnee",
		s.reference_biblio AS "referenceBiblio",
		NULL AS "sensiDateAttribution",
		n14.label_default AS "sensiNiveau",
		sensireferentiel AS "sensiReferentiel",
		sensiversionreferentiel AS "sensiVersionReferentiel",
		n17.label_default AS "statutSource",
		--Descriptif sujet
		gl.comment_description AS "obsDescription",
		n4.label_default AS "obsTechnique",
		n6.label_default AS "occEtatBiologique",
		n19.label_default AS "occMethodeDetermination",
		n7.label_default AS "occNaturalite",
		n11.label_default AS "occSexe",
		n10.label_default AS "occStadeDeVie",
		n5.label_default AS "occStatutBiologique",
		n8.label_default AS "preuveExistante",
		s.digital_proof AS "uRLPreuveNumerique",
		s.non_digital_proof AS "preuveNonNumerique",
		n20.label_default AS "occComportement",
		--regroupement observation
		s.unique_id_sinp_grp AS "idSINPRegroupement",
		s.grp_method AS "methodeRegroupement",
		n2.label_default AS "typeRegroupement",
		n12.label_default AS "objetDenombrement",
		n13.label_default AS "typeDenombrement"
	FROM observations AS gl
		JOIN gn_synthese.synthese AS s
			ON gl.id_synthese = s.id_synthese
		JOIN taxonomie.taxref AS t
			ON t.cd_nom = s.cd_nom
		JOIN gn_meta.t_datasets AS d 
			ON d.id_dataset = s.id_dataset
		JOIN gn_meta.t_acquisition_frameworks AS af
			ON d.id_acquisition_framework = af.id_acquisition_framework
		JOIN gn_synthese.t_sources AS sources
			ON sources.id_source = s.id_source
		LEFT JOIN cda
			ON d.id_dataset = cda.id_dataset
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n1 
			ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n2
			ON s.id_nomenclature_grp_typ = n2.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n4
			ON s.id_nomenclature_obs_technique = n4.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n5
			ON s.id_nomenclature_bio_status = n5.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n6
			ON s.id_nomenclature_bio_condition = n6.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n7
			ON s.id_nomenclature_naturalness = n7.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n8
			ON s.id_nomenclature_exist_proof = n8.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n9
			ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n10
			ON s.id_nomenclature_life_stage = n10.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n11
			ON s.id_nomenclature_sex = n11.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n12
			ON s.id_nomenclature_obj_count = n12.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n13
			ON s.id_nomenclature_type_count = n13.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n14
			ON s.id_nomenclature_sensitivity = n14.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n15
			ON s.id_nomenclature_observation_status = n15.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n17
			ON s.id_nomenclature_source_status = n17.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n18
			ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n19
			ON s.id_nomenclature_determination_method = n19.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n20
			ON s.id_nomenclature_behaviour = n20.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n21 
			ON d.id_nomenclature_data_origin = n21.id_nomenclature
		LEFT JOIN ref_nomenclatures.t_nomenclatures AS n22 
			ON s.id_nomenclature_valid_status = n22.id_nomenclature
		where d.dataset_name not ilike '%mnhn%'
		--limit 10000
) TO stdout
WITH (format csv, header, delimiter E'\t', null '\N');

