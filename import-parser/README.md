# GeoNature Import Parser

## Mise en place

- Mettre à jour les fichiers de configuration.
- Installer Pipenv : ```pip3 install --user pipenv```
- Ajouter le code suivant au fichier `~/.bashrc` :

```
# Add ~/.local/bin to PATH (Pipenv)
if [ -d "${HOME}/.local/bin" ] ; then
    PATH="${HOME}/.local/bin:$PATH"
fi
```

- Recharger le fichier `~/.bashrc` avec la commande : `source ~/.bashrc`
- **Notes** : il est nécessaire de donner les droits d'execution à GCC pour 
tout le monde si l'on veut pouvoir installer correctement le venv 
avec `sudo chmod o+x /usr/bin/gcc`. Une fois l'installation terminée, 
retirer les à nouveau avec  `sudo chmod o-x /usr/bin/gcc`.
- Installer les dépendances :
  - `cd sinp-paca-data/import-parser/`
  - `pipenv install`
- Vérifier que le script `bin/gn_import_parser.py` est bien un lien symbolique 
pointant vers `../import_parser/runner.py`
  - Si ce n'est pas le cas, il faut le recréer : 
  `cd bin/ ; ln -s ../import_parser/runner.py gn_import_parser.py`

## Utiliser le parser

- Lancer une seule commande : `pipenv run python ./bin/gn_import_parser.py <args-opts>`
- Lancer plusieurs commandes :
  - Activer l'environnement virtuel : `pipenv shell`
  - Lancer ensuite les commandes : `python ./bin/gn_import_parser.py <args-opts>`
  - Pour désactiver l'environnement virtuel : 
  `exit` (`deactivate` ne fonctionne pas avec `pipenv`)


## Synchronisation serveur

Pour transférer uniquement le dossier `import-parser/` sur le serveur, 
utiliser `rsync` en testant avec l'option `--dry-run` 
(à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links --exclude venv --exclude .gitignore --exclude settings.ini ./ geonat@db-paca-sinp:~/data/import-parser/ --dry-run
```

## Développement : préparation de l'espace de travail

Sous Debian Buster :
```
cd sinp-paca-data/import-parser/
pip3 install --user pipenv
pipenv install configobj click colorama psycopg2
```
