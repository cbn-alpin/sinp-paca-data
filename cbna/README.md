# CBNMED DATA


## Préparation de l'archive

### Vérification de l'archive

Avant de lancer le script d'import initial ou de mise à jour, il est nécessaire
de s'assurer de l'intégrité du format CSV de l'archive et de la possibilité de
pouvoir intégrer les données dans la base (abscence de doublon sur les index uniques).
Pour cela :
* dézipper l'archive reçu
* appliquer les commandes listées sur la page [Outils et commandes utiles pour les imports](https://wiki-sinp.cbn-alpin.fr/database/utilitaires-imports) pour vérifier :
    * le nombre de tabulations de chaque ligne
    * la présence de ligne en doublon
    * la presence de doublon pour la colonne UUID

### Création de l'archive sur Dropbox

L'archive au format d'échange doit être stocké sur Dropbox au niveau du dossier
`Applications/data-paca-sinp/cbna`.
Elle doit être compressé au format `.tar.bz2` pour cela se placer dans le
dossier contenant les fichiers `.csv` du format d'échange et lancer la commande :
```
tar jcvf ../2022-03-11_sinp_paca_cbna.tar.bz2 .
```

## Import des données

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini`
en le renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `cbna/config/settings.sample.ini`
en le renomant `cbna/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si
    nécessaire, vous pouvez aussi y surcharger des paramètres du fichier
    `cbna/config/settings.default.ini`.
* Se placer dans le dossier `cbna/bin/` et utiliser le script :
    *`./import_update.sh -v` pour mettre à jour les données du CBNA.
        * Le script se charge de télécharger les données brutes depuis Dropbox
        * Les scripts SQL du dossier `shared/data/sql/update/` seront ensuite
        exécutés séquentiellement dans ordre déterminé pour la mise à jour.
    * l'import initial a été fait via les script présent dans `cbna-cbnmed/bin/`


## Synchronisation serveur

Pour transférer uniquement le dossier `cbna/` sur le serveur, utiliser `rsync`
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links --exclude var --exclude .gitignore --exclude settings.ini --exclude "data/raw/*" ./ geonat@db-paca-sinp:~/data/cbna/ --dry-run
```
