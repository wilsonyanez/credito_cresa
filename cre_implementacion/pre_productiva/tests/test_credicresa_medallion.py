import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'lib'))
from credicresa_medallion import layer_contracts, targets, transform
from cresa_contracts import entities


class MedallionTest(unittest.TestCase):
    def test_all_entities_have_four_distinct_owned_targets(self):
        objects = [item for _, cfg in entities() for item in targets(cfg)]
        self.assertEqual(len(objects), 136)
        self.assertEqual(len(set(objects)), 136)
        self.assertTrue(all(table.startswith('credicresa_') for schema, table in objects if schema != 'credicresa'))

    def test_job_dependencies_and_existing_notebooks(self):
        job = json.loads((ROOT / 'config/jobs/job_credicresa_ingesta_periodo.json').read_text())
        self.assertEqual([t['task_key'] for t in job['tasks']],
                         ['credicresa_'+n for n in ('fuente','bronze','silver','gold','verificar')])
        for index, task in enumerate(job['tasks']):
            path = task['notebook_task']['notebook_path'].split('/cresa/credicresa/')[1]
            self.assertTrue((ROOT / (path+'.py')).is_file())
            if index:
                self.assertEqual(task['depends_on'], [{'task_key':job['tasks'][index-1]['task_key']}])

    def test_unsupported_publication_is_rejected(self):
        import yaml
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for layer in ('silver','gold'):
                target = root / 'config' / layer
                target.mkdir(parents=True)
                data = yaml.safe_load((ROOT / 'config' / layer / 'credicresa.yml').read_text())
                data['publish_to_consumers'] = True
                (target / 'credicresa.yml').write_text(yaml.safe_dump(data))
            with self.assertRaises(ValueError):
                layer_contracts(root)

    def test_dry_run_requires_control_plane(self):
        spark = MagicMock()
        spark.catalog.tableExists.return_value = False
        with self.assertRaises(RuntimeError):
            transform(spark, ROOT, {'dry_run':True}, 'silver')
        spark.createDataFrame.assert_not_called()

    def test_dry_run_preserves_rows_and_does_not_publish(self):
        spark = MagicMock()
        cfg = entities()[0][1]
        frame = MagicMock()
        frame.count.return_value = 7
        values = dict(period='', input_batch='', dry_run=True, table_filter='')
        with patch('credicresa_runtime.selected', return_value=[(None,cfg)]), \
             patch('credicresa_runtime.typed', return_value=frame), \
             patch('credicresa_runtime.assert_owned', return_value=True), \
             patch('credicresa_runtime.publish') as publish, \
             patch('credicresa_medallion.diagnose', return_value=[dict(total_rows=7, status='PASS')]):
            result = transform(spark, ROOT, values, 'silver')
        self.assertEqual(result['rows'], 7)
        self.assertFalse(result['published_to_consumers'])
        publish.assert_not_called()
        spark.createDataFrame.assert_not_called()

    def test_publication_failure_records_failed_and_raises(self):
        spark = MagicMock()
        cfg = entities()[0][1]
        frame = MagicMock()
        frame.count.return_value = 7
        values = dict(period='', input_batch='', dry_run=False, table_filter='')
        with patch('credicresa_runtime.selected', return_value=[(None,cfg)]), \
             patch('credicresa_runtime.typed', return_value=frame), \
             patch('credicresa_runtime.assert_owned', return_value=True), \
             patch('credicresa_runtime.publish', side_effect=RuntimeError('write failed')), \
             patch('credicresa_medallion.diagnose', return_value=[dict(rule_id='TEST', type='test', columns=[], total_rows=7, affected_rows=0, status='PASS', action='flag_only')]):
            with self.assertRaises(RuntimeError):
                transform(spark, ROOT, values, 'gold')
        self.assertEqual(spark.createDataFrame.call_args.args[0][0][5], 'FAILED')

if __name__ == '__main__':
    unittest.main()
