-- SQL queries to check where organizations not linked to the INPN are used

-- NOT FIND in SINP migration file => 63
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
;

-- IN meta with actors => 1
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme, string_agg(actors.actor, ', ') AS actors
FROM utilisateurs.bib_organismes AS bo
	JOIN LATERAL (
		SELECT cda1.id_organism, string_agg(datasets_actors.actor, ', ') AS actor
		FROM gn_meta.cor_dataset_actor AS cda1
			JOIN LATERAL (
				SELECT CONCAT(tr.prenom_role, ' ', tr.nom_role) AS actor
				FROM gn_meta.cor_dataset_actor AS cda2
					LEFT JOIN utilisateurs.t_roles AS tr
						ON cda2.id_role = tr.id_role
				WHERE cda2.id_dataset = cda1.id_dataset
					AND cda2.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
					AND cda2.id_role IS NOT NULL

				UNION

				SELECT boc.nom_organisme  AS actor
				FROM gn_meta.cor_dataset_actor AS cda3
					LEFT JOIN utilisateurs.bib_organismes AS boc
						ON cda3.id_organism  = boc.id_organisme
				WHERE cda3.id_dataset = cda1.id_dataset
					AND cda3.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
					AND cda3.id_organism IS NOT NULL
			) datasets_actors ON TRUE
		WHERE cda1.id_organism = bo.id_organisme
		GROUP BY cda1.id_organism

		UNION

		SELECT cafa1.id_organism, string_agg(af_actors.actor, ', ') AS actor
		FROM gn_meta.cor_acquisition_framework_actor AS cafa1
			JOIN LATERAL (
				SELECT CONCAT(tr.prenom_role, ' ', tr.nom_role) AS actor
				FROM gn_meta.cor_acquisition_framework_actor AS cafa2
					LEFT JOIN utilisateurs.t_roles AS tr
						ON cafa2.id_role = tr.id_role
				WHERE cafa2.id_acquisition_framework = cafa1.id_acquisition_framework
					AND cafa2.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
					AND cafa2.id_role IS NOT NULL

				UNION

				SELECT boc.nom_organisme  AS actor
				FROM gn_meta.cor_acquisition_framework_actor AS cafa3
					LEFT JOIN utilisateurs.bib_organismes AS boc
						ON cafa3.id_organism  = boc.id_organisme
				WHERE cafa3.id_acquisition_framework = cafa1.id_acquisition_framework
					AND cafa3.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
					AND cafa3.id_organism IS NOT NULL
			) af_actors ON TRUE
		WHERE cafa1.id_organism = bo.id_organisme
		GROUP BY cafa1.id_organism
	) actors ON TRUE
WHERE id_organisme > 1
	AND bo.additional_data ->> 'isInpnUuid' IS NULL
GROUP BY bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
;

-- NOT IN meta => 62
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
;

-- NOT IN meta but IN t_roles => 52
-- WARNING : find the INPN UUIDs and replace them!
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
	AND bo.id_organisme IN (
		SELECT DISTINCT id_organisme FROM utilisateurs.t_roles WHERE id_organisme IS NOT NULL AND active = TRUE
	)
;
-- NOT IN meta and NOT Linked ! => 10
-- WARNING : delete this entries!
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organisme FROM utilisateurs.t_roles WHERE id_organisme IS NOT NULL AND active = TRUE
	)
;


-- NOT IN meta but IN bib_organismes.id_parent => 0
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
	AND bo.id_organisme IN (
		SELECT DISTINCT id_parent FROM  utilisateurs.bib_organismes WHERE id_parent IS NOT NULL
	)
;

-- NOT IN meta but IN temp_users => 0
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
	AND bo.id_organisme IN (
		SELECT DISTINCT id_organisme FROM utilisateurs.temp_users WHERE id_organisme IS NOT NULL
	)
;

-- NOT IN meta but IN gn_commons.t_parameters => 0
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
	AND bo.id_organisme IN (
		SELECT DISTINCT id_organism FROM gn_commons.t_parameters WHERE id_organism IS NOT NULL
	)
;

-- NOT IN meta but IN gn_synthese.defaults_nomenclatures_value => 0
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
	AND bo.id_organisme IN (
		SELECT DISTINCT id_organism FROM gn_synthese.defaults_nomenclatures_value WHERE id_organism IS NOT NULL
	)
;

-- NOT IN meta but  IN ref_nomenclatures.defaults_nomenclatures_value => 0
SELECT DISTINCT bo.id_organisme, bo.uuid_organisme, bo.nom_organisme
FROM utilisateurs.bib_organismes AS bo
WHERE id_organisme > 1
	AND (bo.additional_data ->> 'isInpnUuid') IS NULL
	AND bo.id_organisme NOT IN (
		SELECT DISTINCT id_organism FROM gn_meta.cor_acquisition_framework_actor WHERE id_organism IS NOT NULL
		UNION
		SELECT DISTINCT id_organism FROM gn_meta.cor_dataset_actor WHERE id_organism IS NOT NULL
	)
	AND bo.id_organisme IN (
		SELECT DISTINCT id_organism FROM ref_nomenclatures.defaults_nomenclatures_value WHERE id_organism IS NOT NULL
	)
;
