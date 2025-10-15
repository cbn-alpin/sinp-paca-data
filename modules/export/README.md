# Export SIT ZH

## Création de la table ref_geo.sit_zones_humides
- Récupérer la dernière version version des polygones des zones humides au format Shape.
- Extraire l'archie Zip des fichiers "Shape" dans une dossier
- Se placer dans le dossier contenant les fichiers "Shape"
- À partir du fichier Shape des zones humides fourni créé un fichier SQL à l'aide de la
commande `shp2pgsql` :
    ```bash
        shp2pgsql -I -W LATIN1 ./2024-04-29_sit_zh_export_global.shp ref_geo.sit_zones_humides > 2024-04-29_sit_zh.sql
    ```
- Assurez vous de la présence des colonnes : `site`, `code` et `geom`.
- Transférer le fichier SQL créé sur le serveur : `scp ./2024-04-29_sit_zh.sql geonat@db-paca-sinp:~/data/modules/export/`
- Archiver la table précédente :`psql -h localhost -p 5432 -U geonatadmin -c "ALTER TABLE ref_geo.sit_zones_humides RENAME TO ref_geo.sit_zones_humides_2023 ;"`
- Créer la nouvelle table : `psql -h localhost -p 5432 -U geonatadmin -d geonature2db -f "/home/geonat/data/modules/export/2024-04-29_sit_zh.sql"`
- Vérifier le contenu et la présence de la nouvelle table sur le serveur via Dbeaver par exemple.

## Problème des géométries des zones humides et de la Synthèse de GeoNature
Pour fonctionner, il est nécessaire que les géomérties des zones humides soient de type
multipolygones. Or, certaines ZH (137 en 2024) sont de type GeometryCollection. Cela
pose problème et il est donc nécessaire de les convertir avec cette requête SQL :

    ```sql
        UPDATE ref_geo.sit_zones_humides SET
            geom = st_multi(st_collectionextract(ST_MakeValid(geom), 3))
        WHERE gid IN (
                SELECT gid
                FROM ref_geo.sit_zones_humides
                WHERE st_isvalid(geom) = FALSE
        	) ;
    ```

Le problème peut également se poser avec les géométrie de la Synthese de GeoNature.
Il est possible de détecter les géométries invalides à l'aide de la fonction Postgis `st_isvalid()`.
Voici un exemple de requête pour détecter les géométries invalide de la Synthèse de GeoNature :

    ```sql
        SELECT id_synthese, the_geom_4326
        FROM gn_synthese.synthese AS s
        WHERE the_geom_4326 IS NOT NULL
            AND st_isvalid(the_geom_4326) = FALSE
        ORDER BY id_synthese ;
    ```
# Export OPIE
Territoire : tout PACA ; Période : du 01/01/2005 au 31/12/2024 ; Taxons concernés : familles suivantes : Papilionidae, Hesperiidae, Pieridae, Nymphalidae, Lycaenidae, Riodinidae, Zygaenidae.
