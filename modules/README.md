# Gestion des modules de GeoNature

Contient un fichier SQL à éxecuter sur l'instance `db-srv` pour mettre à 
jour les modules : nom, ordre, infos...

## Synchronisation serveur

Pour transférer uniquement le dossier `cbna-cbnmed/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links ./ geonat@db-paca-sinp:~/data/modules/ --dry-run
```


## Exécution du SQL

Se placer dans le dossier `modules/` et utiliser les commandes :
```
source ../shared/config/settings.default.ini
source ../shared/config/settings.ini
psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -f ./data/sql/01_update_modules.sql
```
