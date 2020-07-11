import os
import sys
import csv
import re
import time
import datetime

import click
import psycopg2

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
    columns_to_remove = ['id_synthese', 'unique_id_.*', 'code_nomenclature_.*',]

    click.echo('Source filename:' + filename_src)
    click.echo('Destination filename:' + filename_dest)
    click.echo('Type:' + import_type)

    csv.register_dialect('sql_copy', delimiter='\t', quotechar='', escapechar='', quoting=csv.QUOTE_NONE)

    # Get database infos
    db = GnDatabase()
    db.connect_to_database()
    db.print_database_infos()
    db.get_dataset_id('DFCP')

    # Open CSV files
    with open(filename_src, 'r', newline='', encoding='utf-8') as f_src:
        print_msg('Computing CSV file total number of entries...')
        #total_csv_lines_nbr = sum(1 for line in f_src) - 1
        #f_src.seek(0)
        total_csv_lines_nbr = 3562332
        print_info(f'Number of entries in CSV files: {total_csv_lines_nbr} ')

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

                        # Replace Dataset Code

                        # Replace Module Code

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
        self.db_cursor = self.db_connection.cursor()

    def print_database_infos(self):
        # Print PostgreSQL Connection properties
        print_verbose(self.db_connection.get_dsn_parameters())

        # Print PostgreSQL version
        self.db_cursor.execute("SELECT version()")
        record = self.db_cursor.fetchone()
        print_verbose(f'You are connected to - {record}')

    def get_dataset_id(self, code):
        self.db_cursor.execute(f"""
            SELECT dataset_shortname AS code, id_dataset AS id
            FROM gn_meta.t_datasets
            WHERE dataset_shortname = '{code}'
        """)
        records = db_cursor.fetchall()
        print_verbose(records)


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


if __name__ == '__main__':
    parse_file()

