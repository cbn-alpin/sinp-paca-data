# CBNA-CBNMED DATA

## Import des données

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini` en le 
renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `cbna-cbnmed/config/settings.sample.ini` 
en le renomant `cbna-cbnmed/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si 
    nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  
    `cbna-cbnmed/config/settings.default.ini`.
* Se placer dans le dossier `cbna-cbnmed/bin/` et utiliser le script 
`./import_initial.sh -v` pour importer le jeu de données des CBNA et CBNMED.
    * Le script se charge de télécharger les données brutes depuis Dropbox
    * Les scripts SQL du dossier `cbna-cbnmed/data/sql/initial/` seront ensuite exécuté séquentiellement.

## Synchronisation serveur

Pour transférer uniquement le dossier `cbna-cbnmed/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links --exclude var --exclude .gitignore --exclude settings.ini --exclude "data/raw/*" ./ geonat@db-paca-sinp:~/data/cbna-cbnmed/ --dry-run
```

## Création de l'archive sur Dropbox

L'archive au format d'échange doit être stocké sur Dropbox au niveau du dossier 
`Applications/data-paca-sinp/cbna-cbnmed`.
Elle doit être compressé au format `.tar.bz2` pour cela se placer dans le
dossier contenant les fichiers `.csv` du format d'échange et lancer la commande :
```
tar jcvf ../2021-02-24_sinp_paca_cbna-cbnmed.tar.bz2 .
```
