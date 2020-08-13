# Tâches à faire
- [ ] Afin d'utiliser la même mécanique d'import, préparer un [fichier CSV au format SYNTHESE SINP](https://wiki-sinp.cbn-alpin.fr/database/import-formats#format_synthese_d_import) et modifier l'import
- [ ] La récréation de la table cor_area_synthese est trop longue après un import. Essayer d'utiliser st_subdivide() ? Ne pas tronquer la table, seulement la mettre à jour avec les nouvelles données ?

# Tâches réalisée
- [x] Utiliser le nouveau format de script Bash
- [x] Tester le nouveau script d'import 'cbna'  
- [x] Utiliser le paramètre  de config 'area_table_name' comme variables dans les scripts SQL
- [x] Utiliser la config, les fichiers partagés et le script "area"
- [x] ~~Remplacer les id du fichier `006_insert_meta.sql` par des function récupérant les ids via des 'codes'.~~
- [x] ~~Extraire seulement les observations réalisées en région PACA.~~
