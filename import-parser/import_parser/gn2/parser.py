import os
import sys
import re
import uuid
import configparser

from helpers.config import Config
from helpers.helpers import print_msg, print_info, print_error, print_verbose, find_ranges, is_uuid


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
def remove_headers(fieldnames):
    output = fieldnames.copy()
    if Config.get('actions.remove_columns'):
        col_patterns = Config.get('actions.remove_columns.params')
        for pattern in col_patterns:
            for field in fieldnames:
                if re.match(rf'^{pattern}$', field):
                    output.remove(field)
    return output

# Add new row entries if necessary
def add_headers(fieldnames):
    output = fieldnames.copy()
    if Config.get('actions.add_uuid_obs') and 'unique_id_sinp' not in fieldnames:
        output.insert(0, 'unique_id_sinp')
    return output

# Remove row entries where fieldname match pattern
def remove_columns(row):
    if Config.get('actions.remove_columns'):
        col_patterns = Config.get('actions.remove_columns.params')
        fieldnames = list(row.keys())
        for pattern in col_patterns:
            for field in fieldnames:
                if re.match(rf'^{pattern}$', field):
                    del row[field]
    return row

# Add row entries if necessary
def add_columns(row):
    if Config.get('actions.add_uuid_obs') and 'unique_id_sinp' not in row:
        row['unique_id_sinp'] = Config.get('null_value_string')
    return row

def insert_values_to_columns(row):
    if Config.get('actions.set_values'):
        col_values =  Config.get('actions.set_values.params')
        fieldnames = list(row.keys())
        for pattern, value in col_values.items():
            for field in fieldnames:
                if re.match(rf'^{pattern}$', field):
                    row[field] = value
    return row

def add_uuid_obs(row):
    if Config.get('actions.add_uuid_obs'):
        if not is_uuid(row['unique_id_sinp']):
            row['unique_id_sinp'] = uuid.uuid4()
    return row

def check_sciname_code(row, scinames_codes):
    exists = True
    if row['cd_nom'] != None:
        exists = (str(row['cd_nom']) in scinames_codes)
    return exists

def replace_code_dataset(row, datasets):
    if 'code_dataset' in row.keys() and row['code_dataset'] != None:
        code = row['code_dataset']
        if datasets[code]:
            id = datasets[code]
            row['code_dataset'] = id
    return row

def replace_code_module(row, modules):
    if 'code_module' in row.keys() and row['code_module'] != None:
        code = row['code_module']
        if modules[code]:
            id = modules[code]
            row['code_module'] = id
    return row

def replace_code_source(row, sources):
    if 'code_source' in row.keys() and row['code_source'] != None:
        code = row['code_source']
        if sources[code]:
            id = sources[code]
            row['code_source'] = id
    return row

def replace_code_nomenclature(row, nomenclatures):
    columns_types = Config.getSection('NOMENCLATURES')
    fieldnames = list(row.keys())
    for field in fieldnames:
        if field.startswith('code_nomenclature_'):
            nomenclature_type = columns_types[field]
            code = row[field]
            if code != '\\N':
                row[field] = nomenclatures[nomenclature_type][code]
    return row
