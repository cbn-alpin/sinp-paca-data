# CEN-PACA DATA

## Import donnée de test

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini` en le renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `cenpaca/config/settings.sample.ini` en le renomant `cenpaca/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  `cenpaca/config/settings.default.ini`.
* Se placer dans le dossier `cenpaca/bin/` et utiliser le script `./import_initial.sh -v` pour importer le jeu de données de test du CEN-PACA.
    * Le script se charge de télécharger les données brutes depuis Dropbox
    * Les scripts SQL du dossier `cenpaca/data/sql/initial/` seront ensuite exécuté séquentiellement.

## Synchronisation serveur

Pour transférer uniquement le dossier `cenpaca/` sur le serveur, utiliser `rsync` en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links --exclude var --exclude .gitignore --exclude settings.ini --exclude "data/raw/*" ./ geonat@db-paca-sinp:~/data/cenpaca/ --dry-run
```
