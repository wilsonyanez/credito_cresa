"""Ejecuta el SQL diagnostico portable sobre datos sinteticos locales."""
import sqlite3
import sys
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'lib'))
from credicresa_quality import diagnose, rule_plan, policy, queries
from cresa_contracts import entities

CFG = dict(source_table='sample', columns=dict(include=['id','part','text'],
           types=dict(id='INT',part='INT',text='STRING'), source_types=dict(text='VARCHAR(3)')),
           primary_key=dict(columns=['id','part']), natural_key=dict(columns=[], pending_definition=True))

class QualityTest(unittest.TestCase):
    def evaluate(self, rows, bootstrap=False):
        with sqlite3.connect(':memory:') as con:
            con.row_factory = sqlite3.Row
            con.execute('CREATE TABLE sample (id INTEGER, part INTEGER, text TEXT)')
            con.executemany('INSERT INTO sample VALUES (?,?,?)', rows)
            result = diagnose(CFG, '`sample`', lambda sql: dict(con.execute(sql).fetchone()), bootstrap)
            self.assertEqual(con.execute('SELECT COUNT(*) FROM sample').fetchone()[0], len(rows))
            return {r['rule_id']:r for r in result}

    def test_composite_duplicates_count_all_members_excluding_null_keys(self):
        result = self.evaluate([(1,1,'a'),(1,1,'b'),(1,2,'c'),(None,1,'d'),(None,1,'e')])
        self.assertEqual(result['PRIMARY_KEY_DUPLICATE']['affected_rows'], 2)
        self.assertEqual(result['PRIMARY_KEY_NULL']['affected_rows'], 2)
        self.assertEqual(result['NATURAL_KEY_PENDING']['status'], 'PENDING')

    def test_text_rules_are_diagnostic_and_null_is_not_blank(self):
        result = self.evaluate([(1,1,None),(2,1,''),(3,1,'   '),(4,1,' x '),(5,1,'abcd')])
        self.assertEqual(result['text_BLANK']['affected_rows'], 2)
        self.assertEqual(result['text_SPACES']['affected_rows'], 2)
        self.assertEqual(result['text_LENGTH']['affected_rows'], 1)
        self.assertEqual(result['text_LENGTH']['action'], 'flag_only')

    def test_bootstrap_does_not_claim_successful_quality_of_empty_data(self):
        result = self.evaluate([], bootstrap=True)
        self.assertEqual(result['EMPTY_SOURCE']['status'], 'EXPECTED_EMPTY')
        self.assertEqual(result['PRIMARY_KEY_NULL']['status'], 'NOT_EVALUATED')
        self.assertEqual(result['BUSINESS_CERTIFICATION']['status'], 'PENDING')

    def test_real_empty_source_warns(self):
        self.assertEqual(self.evaluate([])['EMPTY_SOURCE']['status'], 'WARNING')

    def test_clean_data_does_not_certify_business(self):
        result = self.evaluate([(1,1,'abc')])
        self.assertEqual(result['PRIMARY_KEY_DUPLICATE']['status'], 'PASS')
        self.assertEqual(result['BUSINESS_CERTIFICATION']['status'], 'PENDING')

    def test_invalid_key_fails_before_query(self):
        bad = dict(CFG, primary_key={'columns':['missing']})
        with self.assertRaises(ValueError): rule_plan(bad)

    def test_sql_identifier_injection_rejected(self):
        with self.assertRaises(ValueError): queries(CFG, '`sample`; DROP TABLE sample')

    def test_all_34_contracts_compile_and_pending_keys_are_explicit(self):
        policy()
        pending = []
        for _, cfg in entities():
            rules, sql, duplicates = queries(cfg, '`cresa`.`bronze`.`'+cfg['target']['bronze_table']+'`')
            if any(r['rule_id']=='NATURAL_KEY_PENDING' for r in rules):
                pending.append(cfg['source_table'])
            self.assertTrue(sql.startswith('SELECT COUNT(*)'))
        self.assertEqual(sorted(pending), ['cat_solicitud_estados','cre_solicitante'])

if __name__ == '__main__': unittest.main()
