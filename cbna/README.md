# CBNA DATA

## Import donnée de test

Copier/coller le fichier `settings.example.ini` en le renomant `settings.ini`.
Modifier dans ce fichier les paramètres de connexion à la base de données. 
Utiliser le script `import.sh` pour importer le jeu de données de test du CBNA.

## Synchronisation serveur

Pour transférer les données sur le serveur, utiliser `rsync` en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -avL --exclude logs --exclude .gitignore --exclude settings.ini --exclude data/raw ./cbna admin@db-paca-sinp:/home/admin/data/ --dry-run
```