# Gestion de la mise à jour de la vm_observation de l'Atlas

Contient un fichier SQL à éxecuter sur l'instance `db-srv` pour mettre à 
jour la VM `atlas.vm_observations` afin qu'elle utilise une VM `atlas.t_subdivided_territory`.
Cette dernière VM contient les polygones correspondant à la subdivision du territoire
à l'aide de la fonction Postgis `st_subdivide()`.
La mise à jour de la VM `atlas.vm_observations` prend environs 5 mn pour 5 millions d'observations
dans la synthèse contre plusieurs heures avec l'ancien mécanisme.

## Synchronisation serveur

Pour transférer uniquement le dossier `atlas/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links ./ geonat@db-paca-sinp:~/data/atlas/ --dry-run
```


## Exécution du SQL

Se placer dans le dossier `atlas/` et utiliser les commandes :
```
source ../shared/config/settings.default.ini
source ../shared/config/settings.ini
psql -h "${db_host}" -U "${db_user}" -d "gnatlas" -f ./data/sql/01_update_vm_observations.sql
```
