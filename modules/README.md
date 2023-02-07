# Gestion des modules de GeoNature

Contient un script partagé de mise à jour des modules (nom, ordre, infos...) ainsi que des
scripts spécifiques à chaque module GeoNature (Export).

## Synchronisation serveur

Pour transférer uniquement le dossier `modules/` sur le serveur, utiliser `rsync`
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links ./ geonat@db-paca-sinp:~/data/modules/ --dry-run
```

## Exécution du SQL

Fichier SQL à éxecuter sur l'instance `db-srv` pour mettre à
jour les modules (nom, ordre, infos...), se placer dans le dossier `modules/`
et utiliser les commandes :
```
source ../shared/config/settings.default.ini
source ../shared/config/settings.ini
psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -f ./shared/01_update_modules.sql
```
