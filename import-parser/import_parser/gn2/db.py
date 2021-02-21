import psycopg2
import psycopg2.extras

from helpers.config import Config

class GnDatabase:
    db_connection = None
    db_cursor = None

    def connect_to_database(self):
        self.db_connection = psycopg2.connect(
            database=Config.get('db_name'),
            user=Config.get('db_user'),
            password=Config.get('db_pass'),
            host=Config.get('db_host'),
            port=Config.get('db_port'),
        )
        self.db_cursor = self.db_connection.cursor(
            cursor_factory = psycopg2.extras.DictCursor,
        )

    def print_database_infos(self):
        print('Database infos:')
        # Print PostgreSQL Connection properties
        for key, value in self.db_connection.get_dsn_parameters().items():
            print(f'\t{key}:{value}')

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

    def get_all_nomenclatures(self):
        nomenclatures_columns_types = Config.getSection('NOMENCLATURES')
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

    def get_all_scinames_codes(self):
        self.db_cursor.execute(f"""
            SELECT DISTINCT cd_nom AS code, lb_nom AS name
            FROM taxonomie.taxref
        """)
        records = self.db_cursor.fetchall()
        codes = {}
        for record in records:
            codes[str(record['code'])] = record['name']
        return codes

    def get_all_organisms(self):
        self.db_cursor.execute(f"""
            SELECT nom_organisme AS code, id_organisme AS id
            FROM utilisateurs.bib_organismes
        """)
        records = self.db_cursor.fetchall()
        organisms = {}
        for record in records:
            organisms[record['code']] = record['id']
        return organisms

    def check_sciname_code(self, sciname_code):
        self.db_cursor.execute(f"""
            SELECT t.cd_nom
            FROM taxonomie.taxref AS t
            WHERE cd_nom = %s
        """, (sciname_code,))
        return self.db_cursor.fetchone() is not None

    def get_all_acquisition_frameworks(self):
        self.db_cursor.execute(f"""
            SELECT acquisition_framework_name AS code, id_acquisition_framework AS id
            FROM gn_meta.t_acquisition_frameworks
        """)
        records = self.db_cursor.fetchall()
        acquisition_frameworks = {}
        for record in records:
            acquisition_frameworks[record['code']] = record['id']
        return acquisition_frameworks
