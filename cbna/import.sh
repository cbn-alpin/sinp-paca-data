#!/bin/bash

# Chargements des paramètres de configuration
. settings.ini

# Création du fichier de log
rm -f $log_file
touch $log_file
sudo chmod 777 $log_file

# Chargement dans GeoNature de l'aire du SINP PACA

# Création du schema contenant les tables de données à importer

# Chargement des données CBNA dans une table "cbna_v2019-01-23"

# Example pour lancer un script SQL :
#export PGPASSWORD='$db_pass';psql -h $db_host -U $db_user -d $db_name -f '01-users/01-t_roles.sql' >> $log_file