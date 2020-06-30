# CBNA DATA

## Import donnée de test

* Au prélable, créer localement une base de données GeoNature à l'aide du script `install_db.sh` de GeoNature.
* Copier/coller le fichier `shared/settings.example.ini` en le renomant `shared/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Placer dans le dossier `cbna/data/raw/` le fichier `releve_flore_global.bak` contenant le dump de la table `cbna_flore_global.releve_flore_global` de la base de données Flore du CBNA.
* Utiliser le script `import.sh` pour importer le jeu de données de test du CBNA.
    * Les scripts SQL du dossier `cbna/data/sql/` vont être exécuté séquentiellement.

## Synchronisation serveur

Pour transférer les données sur le serveur, utiliser `rsync` en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -avL --exclude logs --exclude .gitignore --exclude settings.ini --exclude data/raw ./ admin@db-paca-sinp:/home/admin/data/cbna/ --dry-run
```