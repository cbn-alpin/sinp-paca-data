# Fusion d'organismes

Contient deux script Bash permettant :
 - la migration et la fusion des organismes vers le référentiel orgnisme de l'INPN
 - la fusion de plusieurs organismes de GeoNature afin de supprimer les doublons.

## Synchronisation serveur
Pour transférer uniquement le dossier `organism/` sur le serveur, utiliser `rsync`
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```bash
rsync -av \
    --exclude var \
    --exclude .gitignore \
    --exclude settings.ini \
    --exclude "data/raw/*" \
    ./ geonat@db-paca-sinp:~/data/organism/ --dry-run
```

## Procédures

  * Déployer ce dossier sur le serveur à l'aide de `rsync` (voir ci-dessus).
  * Se placer à la racine du dossier `organism/` à l'aide de la commande `cd` : `cd ~/data/organism/`
  * Les scripts de migrations sont présent dans le dossier `bin/`. Pour afficher les options de chaque script
  utiliser l'option `-h`. Exemple : `./bin/merge_organisms.sh -h`
  * L'ensemble des scripts utilisent les fichiers de configuration présent dans le dossier `config/`. Le fichier `settings.default.ini` est chargé en premier lieu. Ses valeurs de paramètres peuvent être écrasé par celles présentes dans un fichier `settings.ini`.
  * Si vous souhaitez modifier des valeurs de configuration par défaut, créer et éditer les valeurs du fichier `settings.ini` avec :
    ```bash
    vi config/settings.ini
    ```
  * Lancer le script Bash de migration :
    * à partir d'une liste dans un fichier TSV dont le nom est précisé dans `settings.ini` : `./bin/migrate_organisms.sh -v`
  * Lancer le script Bash de fusion :
    * à partir d'une liste dans un fichier TSV : `./bin/merge_organisms.sh -v -f <chemin-fichier-tsv>`
    * pour un organisme à fusionner : `./bin/merge_organisms.sh -v -n <id-organisme-à-garder> -o <ids-organismes-à-remplacer>`

### Fonctionnement du script migrate_organisms.sh
- Pour chaque ligne du fichier TSV, nous prenons le premier UUID d'un des 3 fournisseurs (CBNA, CNMED et CENPACA), cet UUID ainsi que le nom de l'organisme associé sont remplacés par ceux des champs `nom_valide` et `uuid_inpn`dans la table `utilisateurs.bib_organismes`. Nous remplaçons en priorité les UUID fournies par le CENPACA car cela permet de garder les informations d'adresses associées.
- Si les autres fournisseurs ont aussi des UUID, nous récupérons l'`id_organisme` de la table `utilisateurs.bib_organismes` où nous venons de corriger l'UUID et nous nous en servons pour remplacer toutes les références dans les tables de la base de données correspondants aux éventuels UUID des autres fournisseurs. À la fin, nous supprimons les entrées dans la table `utilisateurs.bib_organismes` correspondant aux 2 autres fournisseurs.

## Format des fichiers TSV
  * Pour migrate_organisms.sh (format spécifique SINP PACA) :
    * `nom_valide` : nom à utiliser pour l'organisme
    * `uuid_inpn` : UUID de l'INPN à utiliser.
    * `uuid_cenpaca` : UUID dans la base CEN-PACA de cet organisme.
    * `uuid_cbnmed` : UUID dans la base CBNMED de cet organisme.
    * `uuid_cbna` : UUID dans la base CBNA de cet organisme.
  * Pour merge_organisms.sh :
    * `id` : id de l'organisme à garder.
    * `id_duplicates` : id de l'organisme à fusionner dans le précédent.
    * `name` : nom de l'organisme
