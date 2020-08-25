# CBNA DATA

## Import donnée de test

* Au prélable, créer localement une base de données GeoNature à l'aide du script `install_db.sh` de GeoNature.
* Copier/coller le fichier `shared/settings.example.ini` en le renomant `shared/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Copier/coller le fichier `config/settings.sample.ini` en le renomant `config/settings.ini`.
    * Modifier dans ce fichier les paramètres déjà présent s'ils ne correspondent pas à vos besoins. Si nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  `config/settings.default.ini`.
* Utiliser le script `bin/import_initial.sh` pour importer le jeu de données du CBNA.
    * La sauvegarde (fichier .bak) de la flore globale du CBNA sera téléchargée depuis Dropbox.
    * La sauvegarde sera restoré pour servir de base à l'import.
    * Les scripts SQL du dossier `cbna/data/sql/initial/` vont être exécuté séquentiellement pour réaliser l'import.

## Synchronisation serveur

Pour transférer uniquement le dossier `cbna/` sur le serveur, utiliser `rsync` en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links --exclude var --exclude .gitignore --exclude settings.ini --exclude "data/raw/*" ./ geonat@db-paca-sinp:~/data/cbna/ --dry-run
```
