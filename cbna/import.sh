#!/bin/bash
# Encoding : UTF-8

#+----------------------------------------------------------------------------------------------------------+
# Define constants
TIME_START=$(date +%s)
CUR_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

#+----------------------------------------------------------------------------------------------------------+
# Load config
if [ -f ${CUR_DIR}/settings.ini ] ; then
	source ${CUR_DIR}/settings.ini
	echo -e "${Gra}Config : ${Gre}OK${RCol}"
else
	echo -e "\e[1;31mPlease configure the script by renaming the file 'settings.sample.ini' to 'settings.ini'.\e[0m"
	exit;
fi

#+----------------------------------------------------------------------------------------------------------+
# Test zone
# if ! [ -d "${raw_dir}/ADMIN-EXPRESS-COG_1-0__SHP__FRA_2017-06-19/" ]; then
#     echo "NON PRESENT : ${raw_dir}"
# fi
# exit

#+----------------------------------------------------------------------------------------------------------+
# Load functions
. functions.ini

#+----------------------------------------------------------------------------------------------------------+
# Check commands use by this script exist
echo -e "${Yel}Vérification de la présence des commandes nécessaire au script...${RCol}"
commands=("wget", "p7zip", "shp2pgsql")
for cmd in "${commands[@]}"; do
    if [ ! -x $(command -v $cmd) ]; then
        echo -e "${Red}Erreur: veuillez installer la commande '$cmd'.${RCol}" >&2
        exit 1
    fi
done

#+----------------------------------------------------------------------------------------------------------+
# Create log file
cd $CUR_DIR

if [ ! -d "${log_dir}" ]; then
    echo -e "${Yel}Création du dossier de log...${RCol}"
    mkdir -p "${log_dir}"
fi

echo -e "${Yel}Création du fichier de log...${RCol}"
rm -f "$log_file"
touch "$log_file"
sudo chmod 777 "$log_file"

echo -e "${Whi}CBNA import script started at : `date -d @${TIME_START} "+%Y-%m-%d %H:%M:%S"`${RCol}"

#+----------------------------------------------------------------------------------------------------------+
# Create french region SQL file
raw_region_file_path="${raw_dir}/admin-express-cog_$ae_version.7z"
sql_region_file_path="${sql_dir}/001_region_tmp.sql"
if ! [ -d "${raw_dir}/ADMIN-EXPRESS-COG_1-0__SHP__FRA_2017-06-19/" ]; then
    echo -e "${Yel}Téléchargement du fichier Admin Express...${RCol}"
    if ! [ -f "$raw_region_file_path" ]; then
        wget $ae_url -O $raw_region_file_path
    fi
    
    echo -e "${Yel}Décompression de l'archive...${RCol}"
    cd ${raw_dir}/
    p7zip -d ${raw_dir}/admin-express-cog_$ae_version.7z 
    
    echo -e "${Yel}Création fichier SQL du contour des régions françaises...${RCol}"
    cd ${raw_dir}/ADMIN-EXPRESS-COG_1-0__SHP__FRA_2017-06-19/ADMIN-EXPRESS-COG/1_DONNEES_LIVRAISON_2017-06-19/ADE-COG_1-0_SHP_LAMB93_FR/
    shp2pgsql -c -D -s 2154 -I REGION ref_geo.tmp_region > $sql_region_file_path;
fi

#+----------------------------------------------------------------------------------------------------------+
# Run SQL scripts in order
cd $CUR_DIR/

echo -e "${Yel}Réinitialisation de toute la base${RCol}"
export PGPASSWORD="$db_pass";psql -h $db_host -U $db_user -d $db_name -f "${sql_dir}/000_initialize.sql" >> $log_file

echo -e "${Yel}Chargement du contour du territoire SINP${RCol}"
export PGPASSWORD="$db_pass";psql -h $db_host -U $db_user -d $db_name -f $sql_region_file_path >> $log_file

echo -e "${Yel}Insertion dans GeoNature du territoire SINP${RCol}"
export PGPASSWORD="$db_pass";psql -h $db_host -U $db_user -d $db_name -f "${sql_dir}/002_sinp_zone.sql" >> $log_file

# Chargement des données CBNA dans un schema "releve_flore_globale"
echo -e "${Yel}Chargement des données brutes du CBNA${RCol}"
export PGPASSWORD="$db_pass";psql -h $db_host -U $db_user -d $db_name -f "${sql_dir}/003_import_cbna_raw.sql" >> $log_file

/usr/bin/pg_restore --exit-on-error --verbose --jobs "${pg_restore_jobs}" \
    --host $db_host --port $db_port --username $db_user --dbname $db_name \
    --schema "cbna_flore_global" --no-owner "${raw_dir}/releve_flore_global"

export PGPASSWORD="$db_pass";psql -h $db_host -U $db_user -d $db_name -f "${sql_dir}/004_rename_cbna.sql" >> $log_file

#+----------------------------------------------------------------------------------------------------------+
# Show time elapsed
TIME_END=$(date +%s)
TIME_DIFF=$(($TIME_END - $TIME_START));
echo -e "${Whi}Total time elapsed : "`displayTime "$TIME_DIFF"`"${RCol}"