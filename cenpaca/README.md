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
tar jcvf ../2021-03-01_sinp_paca_cenpaca.tar.bz2 .
```

## Commandes appliquées

### Fichier synthese.csv export 2021-03-01_sinp_paca_cenpaca

Aucune correction appliqué.
### Fichier synthese.csv export 2021-02-21_sinp_paca_cenpaca

Liste des corrections appliquées au fichier `synthese.csv` transmis :

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

# Suppression des caractères de fin de ligne présents dans les valeurs des champs :
sed -i -z 's/\n\r\n//g' synthese.csv
sed -i -z 's/\r\n//g' synthese.csv

# Protection des guillemets doubles
# grep -P '[^"]"[^"]' synthese.csv > synthese.quote_err.csv
sed -i 's#\([^"]\)"\([^"]\)#\1""\2#g' synthese.csv

# Caractères UTF-8 mal encodé : respecter l'ordre des commandes !
# grep -P '\x1A' synthese.csv > synthese.utf8_err.csv
sed -i 's#Rh\x1Ane#Rhône#ig' synthese.csv
sed -i 's#Moll\x1Ages#Mollèges#ig' synthese.csv
sed -i 's#ne/\x1Ale d#ne/île d#g' synthese.csv
sed -i 's#Pierre \x1A Feu#Pierre à Feu#g' synthese.csv
sed -i 's#Domaine de la For\x1At#Domaine de la Forêt#g' synthese.csv
sed -i 's#Bois Fran\x1Aois#Bois François#g' synthese.csv
sed -i "s#/l'\x1Ale aux Castors#/l'île aux Castors#g" synthese.csv
sed -i 's#L\x1Ane#Lône#g' synthese.csv
sed -i 's#Ch\x1Ateau#Château#g' synthese.csv
sed -i "s#L'\x1Alon blanc#L'îlon blanc#g" synthese.csv
sed -i 's#la l\x1Ane de T#la lône de T#g' synthese.csv
sed -i 's#Poulag\x1Are#Poulagère#g' synthese.csv
sed -i 's#Vergi\x1Are#Vergière#g' synthese.csv
sed -i 's#Pibouli\x1Are#Piboulière#g' synthese.csv
sed -i 's#\x1A#é#g' synthese.csv

# Remplacement des caractères NULL mal formé
# grep -P '\tN\tN\t' synthese.csv  > synthese.null_err.csv
sed -i 's#\tN\tN\t#\t\\N\t\\N\t#g' synthese.csv
```
