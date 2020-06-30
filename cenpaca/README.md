# CEN-PACA DATA

## Import donnée de test

* Si nécessaire, copier/coller le fichier `shared/settings.example.ini` en le renomant `shared/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Placer dans le dossier `cenpaca/data/raw/` le fichier `2020-02-13_cen-paca_synthese_tests_utf8.tar.bz2` contenant l'export d'une table "synthèse" de GeoNature (sans les références externes)
* Utiliser le script `import.sh` pour importer le jeu de données de test du CEN-PACA.
    * L'archive précédemnt uploadée va être décompressée et son fichier SQL exécuté
    * Les scripts SQL du dossier `cenpaca/data/sql/` seront ensuite exécuté séquentiellement.

## Synchronisation serveur

Pour transférer les données sur le serveur, utiliser `rsync` en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -avL --exclude logs --exclude .gitignore --exclude settings.ini --exclude data/raw ./ admin@db-paca-sinp:/home/admin/data/cenpaca/ --dry-run
```