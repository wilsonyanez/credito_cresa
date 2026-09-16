import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from cresa_eliminar_catalogos import statements, signature
from credicresa_cli import MARKER

class CleanupTest(unittest.TestCase):
    def group(self):
        return {'schema':{'catalog_name':'cresa','name':'bronze','full_name':'cresa.bronze','schema_id':'1'},
                'tables':[{'name':'credicresa_sis_peticiones','full_name':'cresa.bronze.credicresa_sis_peticiones','table_type':'VIEW','comment':MARKER,'table_id':'2'}],
                'volumes':[{'name':'credicresa_data','full_name':'cresa.bronze.credicresa_data','volume_type':'MANAGED','volume_id':'3'}],'functions':[]}
    def test_plan_uses_restrict_and_keeps_catalog(self):
        sql=statements({'contents':[self.group()],'jobs':[]})
        self.assertEqual(len(sql),3)
        self.assertTrue(sql[-1].endswith('RESTRICT'))
        self.assertFalse(any('CASCADE' in s or 'DROP CATALOG' in s for s in sql))
    def test_other_client_blocked(self):
        group=self.group(); group['schema']['catalog_name']='almar'
        with self.assertRaises(ValueError): statements({'contents':[group]})
    def test_unknown_table_blocked(self):
        group=self.group(); group['tables'][0]['name']='otro_proyecto'
        with self.assertRaises(ValueError): statements({'contents':[group]})
    def test_unowned_view_blocked(self):
        group=self.group(); group['tables'][0]['comment']='otro'
        with self.assertRaises(ValueError): statements({'contents':[group]})
    def test_external_volume_blocked(self):
        group=self.group(); group['volumes'][0]['volume_type']='EXTERNAL'
        with self.assertRaises(ValueError): statements({'contents':[group]})
    def test_changed_identity_changes_signature(self):
        inv={'contents':[self.group()],'jobs':[]}; before=signature(inv)
        inv['contents'][0]['tables'][0]['table_id']='new'
        self.assertNotEqual(before,signature(inv))

if __name__=='__main__': unittest.main()
