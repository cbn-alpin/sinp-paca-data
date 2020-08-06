import os
import sys
import csv
import time
import datetime


import click


from gn2.db import GnDatabase
from helpers.helpers import print_msg, print_info, print_error, print_verbose, find_ranges
from gn2.parser import *


# Define OS Environment variables
root_dir = os.path.realpath(f'{os.path.dirname(os.path.abspath(__file__))}/../')
config_dir = os.path.realpath(f'{root_dir}/config/')
os.environ['IMPORT_PARSER.PATHES.ROOT'] = root_dir
os.environ['IMPORT_PARSER.PATHES.CONFIG'] = config_dir


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
        scinames_codes = db.get_all_scinames_codes()

    # Open CSV files
    with open(filename_src, 'r', newline='', encoding='utf-8') as f_src:
        total_csv_lines_nbr = calculate_csv_entries_number(f_src)
        reports = {
            'lines_removed_total': 0,
            'lines_removed_list': {},
        }

        reader = csv.DictReader(f_src, dialect='sql_copy')
        with open(filename_dest, 'w', newline='', encoding='utf-8') as f_dest:
            fieldnames = remove_headers(columns_to_remove, reader.fieldnames)
            writer = csv.DictWriter(f_dest, dialect='sql_copy', fieldnames=fieldnames)
            writer.writeheader()


            with click.progressbar(length=int(total_csv_lines_nbr), label="Parsing lines") as pbar:
                try:
                    for row in reader:
                        # Initialize variables
                        write_row = True

                        # Remove useless columns
                        row = remove_columns(columns_to_remove, row)

                        # Insert value in colums
                        row = insert_values_to_columns(columns_values_to_set, row)

                        if import_type == 's' :
                            # Check Sciname code
                            if check_sciname_code(row, scinames_codes) == False:
                                write_row = False
                                print_error(f"Line {reader.line_num} removed, sciname code {row['cd_nom']} not exists in TaxRef !")
                                reports['lines_removed_total'] += 1
                                if str(row['cd_nom']) not in reports['lines_removed_list']:
                                    reports['lines_removed_list'][str(row['cd_nom'])] = []
                                reports['lines_removed_list'][str(row['cd_nom'])].append(reader.line_num)

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
                        if write_row == True:
                            writer.writerow(row)

                        # Update progressbar
                        pbar.update(int(reader.line_num))
                except csv.Error as e:
                    sys.exit(f'Error in file {filename}, line {reader.line_num}: {e}')
    # Report
    print_msg('Lines removed')
    print_info(f"   Total: {reports['lines_removed_total']: }")
    print_info(f'   List of lines with unkown scinames codes removed:')
    for key in reports['lines_removed_list']:
        grouped_removed_lines = list(find_ranges(reports['lines_removed_list'][key]))
        removed_lines_to_print = []
        for line_group in grouped_removed_lines:
            if (line_group[0] == line_group[1]):
                removed_lines_to_print.append(str(line_group[0]))
            else:
                removed_lines_to_print.append(str(line_group[0]) + '-' + str(line_group[1]))
        print_info(f"       #{key}: {', '.join(removed_lines_to_print)}")


    # Script time elapsed
    time_elapsed = time.time() - start_time
    time_elapsed_for_human = str(datetime.timedelta(seconds=time_elapsed))
    print_msg('Script time')
    print_info(f'   Elapsed: {time_elapsed_for_human}')


if __name__ == '__main__':
    parse_file()
