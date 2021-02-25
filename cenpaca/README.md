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

## Commandes appliquées
### Fichier synthese.csv export 2021-02-21_sinp_paca_cenpaca
```
# Suppression des tabulation présentes dans les valeurs des champs :
sed -i 's#BENCE Stéphane\t\tpointage#BENCE Stéphane\tpointage#g' synthese.csv
sed -i 's#BENCE Stéphane\ti\tpointage#BENCE Stéphane\tpointage#g' synthese.csv
sed -i 's#Vallon de la Maline\t\tSRID=2154#Vallon de la Maline\tSRID=2154#g' synthese.csv
sed -i 's#avec \tCORENTIN Yves#avec CORENTIN Yves#g' synthese.csv

sed -i 's#BENCE Stéphane\tavec \tLEMARCHAND Cécile#BENCE Stéphane\tavec LEMARCHAND Cécile#g' synthese.csv
sed -i 's#BENCE Stéphane\tavec\tLEMARCHAND Cécile#BENCE Stéphane\tavec LEMARCHAND Cécile#g' synthese.csv
sed -i 's#BENCE Stéphane\tavec\tSCOFFIER Stéphanie#BENCE Stéphane\tavec SCOFFIER Stéphanie#g' synthese.csv
sed -i 's#BENCE Stéphane\t\tIBAñEZ Damien#BENCE Stéphane\tIBAñEZ Damien#g' synthese.csv
sed -i 's#BENCE Stéphane\tavec \tPELISSIER Robert#BENCE Stéphane\tavec PELISSIER Robert#g' synthese.csv

# Caractères UTF-8 mal encodé
sed -i 's#\x1A#_#g' synthese.csv

# Protection des guillemets doubles
sed -i 's#"#""#g' synthese.csv

# Remplacement des caractères NULL mal formé
sed -i 's#\tN\t#\t\\N\t#g' synthese.csv

# Suppression des caractères de fin de ligne présents dans les valeurs des champs :
sed -i -z 's/\n\r\n//g' synthese.csv
sed -i -z 's/\r\n//g' synthese.csv
```
