# CEN-PACA DATA

## Import des données

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini` 
en le renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `cenpaca/config/settings.sample.ini` 
en le renomant `cenpaca/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si 
    nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  
    `cenpaca/config/settings.default.ini`.
* Se placer dans le dossier `cenpaca/bin/` et utiliser le script 
`./import_initial.sh -v` pour importer le jeu de données de test du CEN-PACA.
    * Le script se charge de télécharger les données brutes depuis Dropbox
    * Les scripts SQL du dossier `cenpaca/data/sql/initial/` seront ensuite exécuté séquentiellement.

## Synchronisation serveur

Pour transférer uniquement le dossier `cenpaca/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links --exclude var --exclude .gitignore --exclude settings.ini --exclude "data/raw/*" ./ geonat@db-paca-sinp:~/data/cenpaca/ --dry-run
```

## Création de l'archive sur Dropbox

L'archive au format d'échange doit être stocké sur Dropbox au niveau du dossier 
`Applications/data-paca-sinp/cen-paca`.
Elle doit être compressé au format `.tar.bz2` pour cela se placer dans le
dossier contenant les fichiers `.csv` du format d'échange et lancer la commande :
```
tar jcvf ../2021-02-21_sinp_paca_cenpaca.tar.bz2 .
```

## Extraction de lignes d'un fichier

L'ouverture du fichier `synthese.csv` dans un éditeur de texte peut poser
problème contenu de sa taille.
Il est possible d'extraire un nombre réduit de lignes du début du fichier 
à l'aide de la commande suivante :
```
head -1000 synthese.csv > synthese.extract.csv
```
Pour extraire des lignes de la fin du fichier, utiliser la commande
:
```
tail -1000 synthese.csv > synthese.extract_end.csv
```
