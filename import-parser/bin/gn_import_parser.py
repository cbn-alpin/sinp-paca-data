import os
import sys
import csv
import re
import time
import datetime
import configparser

import click
import psycopg2
import psycopg2.extras

@click.command()
@click.argument(
    'filename',
    type=click.Path(exists=True),
)
@click.option(
    '-t',
    '--type',
    'import_type',
    default='s',
    help='Type of import file: s (=synthese), so =(source), d (=dataset), af (=acquisition_framework), o (=organism)',
)
def parse_file(filename, import_type):
    """
    GeoNature 2 Import Parser

    This script parse files containing Postregsql \copy data before integrate their in GeoNature 2 database.
    To avoid to use integer identifiers in import files we use alphanumeric value for nomenclature, dataset,
    organisms or users linked data.

    This script produce new files suffixed by '_rti' (ready to import) where all codes were replaced by integers
    identifiers specific to an GeoNature 2 database.

    Each import files must follow a specific format describe in this SINP Wiki :
    https://wiki-sinp.cbn-alpin.fr/database/exemple-import-synthese

    Access to the GeoNature database must be configured in 'shared/config/settings.ini' file.
    """
    start_time = time.time()
    filename_src = click.format_filename(filename)
    filename_dest =  os.path.splitext(filename_src)[0] + '_rti.csv'
    if import_type == 's' :
        columns_to_remove = ['id_synthese', 'unique_id_.*', 'code_nomenclature_.*',]
        columns_values_to_set = {
            'code_source': 'CEN_PACA_EXPORT',
            'code_module': 'SYNTHESE',
            'code_dataset': 'DFCP',
            'meta_v_taxref': '12',
        }
        nomenclatures_columns_types = get_nomenclatures_columns_types()

    elif import_type == 'so':
        columns_to_remove = ['id_source', 'meta_last_action',]
        columns_values_to_set = {}

    click.echo('Source filename:' + filename_src)
    click.echo('Destination filename:' + filename_dest)
    click.echo('Type:' + import_type)

    csv.register_dialect('sql_copy', delimiter='\t', quotechar='', escapechar='', quoting=csv.QUOTE_NONE)

    if import_type == 's' :
        # Get database infos
        db = GnDatabase()
        db.connect_to_database()
        db.print_database_infos()
        datasets = db.get_all_datasets()
        modules = db.get_all_modules()
        sources = db.get_all_sources()
        nomenclatures = db.get_all_nomenclatures(nomenclatures_columns_types)

    # Open CSV files
    with open(filename_src, 'r', newline='', encoding='utf-8') as f_src:
        total_csv_lines_nbr = calculate_csv_entries_number(f_src)

        reader = csv.DictReader(f_src, dialect='sql_copy')
        with open(filename_dest, 'w', newline='', encoding='utf-8') as f_dest:
            fieldnames = remove_headers(columns_to_remove, reader.fieldnames)
            writer = csv.DictWriter(f_dest, dialect='sql_copy', fieldnames=fieldnames)
            writer.writeheader()

            with click.progressbar(length=int(total_csv_lines_nbr), label="Parsing lines") as pbar:
                try:
                    for row in reader:
                        # Remove useless columns
                        row = remove_columns(columns_to_remove, row)

                        # Insert value in colums
                        row = insert_values_to_columns(columns_values_to_set, row)

                        if import_type == 's' :
                            # Replace Dataset Code
                            row = replace_code_dataset(row, datasets)
                            # Replace Module Code
                            row = replace_code_module(row, modules)
                            # Replace Source Code
                            row = replace_code_source(row, sources)
                            # Replace Source Code
                            row = replace_code_nomenclature(
                                row,
                                nomenclatures,
                                nomenclatures_columns_types
                            )

                        # Write in destination file
                        writer.writerow(row)

                        # Update progressbar
                        pbar.update(int(reader.line_num))
                except csv.Error as e:
                    sys.exit(f'Error in file {filename}, line {reader.line_num}: {e}')

    # Script time elapsed
    time_elapsed = time.time() - start_time
    time_elapsed_for_human = str(datetime.timedelta(seconds=time_elapsed))
    print_info(f'Script time elapsed: {time_elapsed_for_human}')


def print_msg(msg):
    click.echo(click.style(msg, fg='yellow'))


def print_info(msg):
    click.echo(click.style(msg, fg='white', bold='true'))


def print_error(msg):
    click.echo(click.style(msg, fg='red'))


def print_verbose(msg):
    click.echo(click.style(msg, fg='black'))


class GnDatabase:
    db_connection = None
    db_cursor = None

    def connect_to_database(self):
        # TODO: use settings.ini parameters
        self.db_connection = psycopg2.connect(
            database='gn2-sinp-paca',
            user='geonatadmin',
            password='geonatadmin',
            host='localhost',
            port='5432',
        )
        self.db_cursor = self.db_connection.cursor(
            cursor_factory = psycopg2.extras.DictCursor,
        )

    def print_database_infos(self):
        # Print PostgreSQL Connection properties
        print(self.db_connection.get_dsn_parameters())

        # Print PostgreSQL version
        self.db_cursor.execute("SELECT version()")
        record = self.db_cursor.fetchone()
        print(f'You are connected to - {record}')

    def get_dataset_id(self, code):
        self.db_cursor.execute(f"""
            SELECT dataset_shortname AS code, id_dataset AS id
            FROM gn_meta.t_datasets
            WHERE dataset_shortname = '{code}'
        """)
        records = self.db_cursor.fetchall()
        print(records)

    def get_all_datasets(self):
        self.db_cursor.execute(f"""
            SELECT dataset_shortname AS code, id_dataset AS id
            FROM gn_meta.t_datasets
        """)
        records = self.db_cursor.fetchall()
        datasets = {}
        for record in records:
            datasets[record['code']] = record['id']
        return datasets

    def get_all_modules(self):
        self.db_cursor.execute(f"""
            SELECT module_code AS code, id_module AS id
            FROM gn_commons.t_modules
        """)
        records = self.db_cursor.fetchall()
        modules = {}
        for record in records:
            modules[record['code']] = record['id']
        return modules

    def get_all_sources(self):
        self.db_cursor.execute(f"""
            SELECT name_source AS code, id_source AS id
            FROM gn_synthese.t_sources
        """)
        records = self.db_cursor.fetchall()
        sources = {}
        for record in records:
            sources[record['code']] = record['id']
        return sources

    def get_all_nomenclatures(self, nomenclatures_columns_types):
        types = list(nomenclatures_columns_types.values())
        nomenclature_types_columns = {value: key for key, value in nomenclatures_columns_types.items()}

        self.db_cursor.execute(f"""
            SELECT bnt.mnemonique AS type, tn.cd_nomenclature AS code, tn.id_nomenclature AS id
            FROM ref_nomenclatures.t_nomenclatures AS tn
                INNER JOIN ref_nomenclatures.bib_nomenclatures_types AS bnt
                    ON (tn.id_type = bnt.id_type)
            WHERE bnt.mnemonique = ANY(%s)
            ORDER BY bnt.mnemonique ASC, tn.cd_nomenclature ASC
        """, (types,))
        records = self.db_cursor.fetchall()
        nomenclatures = {}
        for record in records:
            nomenclatures.setdefault(record['type'], {})
            nomenclatures[record['type']][record['code']] = record['id']
        return nomenclatures



def get_nomenclatures_columns_types():
    config = configparser.ConfigParser()
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_dir = os.path.realpath(f'{current_dir}/../config/')
    config.read(f'{config_dir}/nomenclatures.ini')
    return config['NOMENCLATURES']

# Computing CSV file number of lines without header line
def calculate_csv_entries_number(file_handle):
    print_msg('Computing CSV file total number of entries...')
    total_lines = sum(1 for line in file_handle) - 1
    file_handle.seek(0)
    if total_lines < 1 :
        print_error("Number of total lines in CSV file can't be lower than 1.")
        exit(1)
    print_info(f'Number of entries in CSV files: {total_lines} ')
    return total_lines

# Remove row entries where fieldname match pattern
def remove_headers(col_patterns, fieldnames):
    output = fieldnames.copy()
    for pattern in col_patterns:
        for field in fieldnames:
            if re.match(rf'^{pattern}$', field):
                output.remove(field)
    return output


# Remove row entries where fieldname match pattern
def remove_columns(col_patterns, row):
    fieldnames = list(row.keys())
    for pattern in col_patterns:
        for field in fieldnames:
            if re.match(rf'^{pattern}$', field):
                del row[field]
    return row

def insert_values_to_columns(col_values, row):
    fieldnames = list(row.keys())
    for pattern, value in col_values.items():
        for field in fieldnames:
            if re.match(rf'^{pattern}$', field):
                row[field] = value
    return row

def replace_code_dataset(row, datasets):
    if row['code_dataset'] != None:
        code = row['code_dataset']
        if datasets[code]:
            id = datasets[code]
            row['code_dataset'] = id
    return row

def replace_code_module(row, modules):
    if row['code_module'] != None:
        code = row['code_module']
        if modules[code]:
            id = modules[code]
            row['code_module'] = id
    return row

def replace_code_source(row, sources):
    if row['code_source'] != None:
        code = row['code_source']
        if sources[code]:
            id = sources[code]
            row['code_source'] = id
    return row

def replace_code_nomenclature(row, nomenclatures, columns_types):
    fieldnames = list(row.keys())
    for field in fieldnames:
        if field.startswith('code_nomenclature_'):
            nomenclature_type = columns_types[field]
            code = row[field]
            if code != '\\N':
                row[field] = nomenclatures[nomenclature_type][code]
    return row

if __name__ == '__main__':
    parse_file()

