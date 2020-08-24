# GeoNature Import Parser

## Mise en place

- Mettre à jour les fichiers de configuration.
- Installer les dépendances :
```
cd sinp-paca-data/import-parser/
pip3 install --user pipenv
pipenv install
```
- Utiliser le parser : 
  - Lancer une seule commande : `pipenv run python ./bin/gn_import_parser.py <args-opts>`
  - Lancer plusieurs commandes :
    - Activer l'environnement virtuel : `pipenv shell`
    - Lancer ensuite les commandes : `python ./bin/gn_import_parser.py <args-opts>`
    - Pour désactiver l'environnement virtuel : `exit` (`deactivate` ne fonctionne pas avec `pipenv`)


## Développement : préparation de l'espace de travail

Sous Debian Buster :
```
cd sinp-paca-data/import-parser/
pip3 install --user pipenv
pipenv install configobj click colorama psycopg2
```
