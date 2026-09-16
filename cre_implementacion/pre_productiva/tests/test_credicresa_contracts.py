import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/"lib"),str(ROOT/"scripts")]
from cresa_contracts import dictionary, spark_type, sync_types, entities, ddl, contract
from credicresa_runtime import settings, selected
from credicresa_cli import Session, OWNER, MARKER

class Widgets:
    def __init__(self, values): self.values=values
    def text(self,key,default): self.values.setdefault(key,default)
    def get(self,key): return self.values[key]

class ContractsTest(unittest.TestCase):
    def test_sql_types(self):
        for original,expected in {"BIT":"BOOLEAN","FLOAT(53)":"DOUBLE","DECIMAL(19, 2)":"DECIMAL(19,2)","VARCHAR(27)":"STRING","DATETIME":"TIMESTAMP_NTZ","VARBINARY(MAX)":"BINARY"}.items():
            self.assertEqual(spark_type(original),expected)
    def test_unknown_type_fails(self):
        with self.assertRaises(ValueError): spark_type("MONEY")
    def test_coverage(self):
        self.assertEqual(sync_types(check=True),{"entities":34,"attributes":451})
    def test_quoted_table_and_case(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/"a.sql"
            p.write_text('CREATE TABLE credicresa."cat_profesion "\n(\n Id INT\n, activo BIT\n)\n;')
            self.assertEqual(dictionary(p)[("credicresa","cat_profesion")]["id"]["type"],"INT")
    def test_unparsed_ddl_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/"a.sql"
            p.write_text("CREATE TABLE credicresa.x (\n id INT NOT NULL\n);")
            with self.assertRaises(ValueError): dictionary(p)
    def test_columns_must_match(self):
        with self.assertRaises(ValueError): contract({"columns":{"include":["id"],"types":{"wrong":"INT"}}})
    def test_period_required(self):
        with self.assertRaises(ValueError): settings(argparse.Namespace(widgets=Widgets({})))
    def test_invalid_calendar_date(self):
        with self.assertRaises(ValueError):
            settings(argparse.Namespace(widgets=Widgets({"period":"2026-02-30","input_batch":"a"*32})))
    def test_period_and_batch(self):
        values=settings(argparse.Namespace(widgets=Widgets({"period":"2026-09","input_batch":"a"*32})))
        self.assertEqual(values["period"],"2026-09")
    def test_bootstrap_forbids_period(self):
        with self.assertRaises(ValueError):
            settings(argparse.Namespace(widgets=Widgets({"period":"2026-09","bootstrap":"true"})))
    def test_filter_no_entities(self):
        with self.assertRaises(ValueError): selected(ROOT,{"table_filter":"^not_an_entity$"})
    def test_job_rejects_other_client(self):
        session=object.__new__(Session)
        with self.assertRaises(ValueError): session.owned_job({"job_id":10,"settings":{"tags":{"client":"other"}}})
    def test_job_accepts_cresa(self):
        session=object.__new__(Session)
        session.owned_job({"job_id":10,"settings":{"tags":OWNER}})
    def test_sql_failure_cannot_succeed(self):
        session=object.__new__(Session)
        session.args=argparse.Namespace(warehouse="w")
        session.api=lambda *a,**kw: {"statement_id":"test","status":{"state":"FAILED","error":{"error_code":"TEST"}}}
        with self.assertRaises(RuntimeError): session.sql("SELECT 1")
    def test_sql_unknown_cannot_succeed(self):
        session=object.__new__(Session)
        session.args=argparse.Namespace(warehouse="w")
        session.api=lambda *a,**kw: {"statement_id":"test","status":{"state":"CLOSED"}}
        with self.assertRaises(RuntimeError): session.sql("SELECT 1")
    def test_sql_success(self):
        session=object.__new__(Session)
        session.args=argparse.Namespace(warehouse="w")
        session.api=lambda *a,**kw: {"statement_id":"test","status":{"state":"SUCCEEDED"}}
        self.assertEqual(session.sql("SELECT 1")["status"]["state"],"SUCCEEDED")


    def test_missing_period_files_prevents_upload(self):
        with tempfile.TemporaryDirectory() as temp:
            period=Path(temp)/"2026-09"
            period.mkdir()
            session=object.__new__(Session)
            session.args=argparse.Namespace(period="2026-09",input_root=temp,table_filter="^sis_peticiones$",seed_format="csv")
            session.state={"job_id":1}
            session.id="a"*32
            session.ready=lambda: None
            session.owned_job=lambda job: None
            session.api=lambda *args: {}
            uploads=[]
            session.cli_call=lambda *args,**kwargs: uploads.append(args)
            with self.assertRaises(FileNotFoundError): session.period()
            self.assertEqual(uploads,[])

    def test_period_upload_uses_immutable_batch(self):
        with tempfile.TemporaryDirectory() as temp:
            folder=Path(temp)/"2026-09"/"sis_peticiones"
            folder.mkdir(parents=True)
            (folder/"data.csv").write_text("id\\n1\\n")
            session=object.__new__(Session)
            session.args=argparse.Namespace(period="2026-09",input_root=temp,table_filter="^sis_peticiones$",seed_format="csv",delimiter=",")
            session.state={"job_id":1}
            session.id="a"*32
            session.ready=lambda: None
            session.owned_job=lambda job: None
            session.api=lambda *args: {}
            uploads=[]
            session.cli_call=lambda *args,**kwargs: uploads.append(args)
            session.log=lambda message: None
            session.save=lambda: None
            runs=[]
            session.run=lambda args: runs.append(args)
            session.period()
            copies=[call for call in uploads if call[:2]==("fs","cp")]
            self.assertIn("/2026-09/"+session.id+"/sis_peticiones/data.csv",copies[0][-1])
            self.assertTrue(any(call[:2]==("fs","mkdirs") for call in uploads))
            self.assertNotIn("--overwrite",uploads[0])
            self.assertEqual(runs[0]["input_batch"],session.id)
            self.assertEqual(runs[0]["bootstrap"],"false")

    def test_reversal_rejects_active_runs_before_deleting(self):
        session=object.__new__(Session)
        session.state={"job_id":1,"verified_objects":[{"schema":"credicresa","table":"sis_peticiones"}]}
        session.ready=lambda: None
        session.jobs=lambda: [{"job_id":1}]
        session.owned_job=lambda job: None
        calls=[]
        def api(method,endpoint):
            calls.append((method,endpoint))
            return {"runs":[{"run_id":1}]} if "runs/list" in endpoint else {}
        session.api=api
        with self.assertRaises(ValueError): session.reverse()
        self.assertTrue(all(method=="get" for method,_ in calls))


    def test_reversal_preview_reads_only_owned_inventory(self):
        import base64
        session=object.__new__(Session)
        objects=[{"schema":schema,"table":table} for _,cfg in entities() for schema,table in (("credicresa",cfg["source_table"]),("bronze",cfg["target"]["bronze_table"]))]
        session.state={"job_id":1,"verified_objects":objects}
        session.args=argparse.Namespace(workspace_path="/Workspace/Users/test/cresa/credicresa",execute=False)
        session.ready=lambda: None
        session.jobs=lambda: [{"job_id":1}]
        calls=[]
        def api(method,endpoint):
            calls.append((method,endpoint))
            if "jobs/get" in endpoint: return {"job_id":1,"settings":{"tags":OWNER}}
            if "runs/list" in endpoint: return {}
            if "workspace/export" in endpoint: return {"content":base64.b64encode(json.dumps(OWNER).encode()).decode()}
            schema=endpoint.split("schema_name=")[1].split("&")[0]
            return {"tables":[{"name":obj["table"],"table_type":"VIEW","comment":MARKER} for obj in objects if obj["schema"]==schema]}
        session.api=api
        messages=[]
        session.log=messages.append
        session.reverse()
        self.assertTrue(all(method=="get" for method,_ in calls))
        self.assertTrue(messages[-1].startswith("PLAN:"))
    def test_reversal_preview_accepts_confirmed_missing_job_and_bronze(self):
        import base64
        session=object.__new__(Session)
        objects=[{"schema":schema,"table":table} for _,cfg in entities() for schema,table in (("credicresa",cfg["source_table"]),("bronze",cfg["target"]["bronze_table"]))]
        session.state={"job_id":1,"verified_objects":objects}
        session.args=argparse.Namespace(workspace_path="/Workspace/Users/test/cresa/credicresa",execute=False)
        session.ready=lambda: None
        session.jobs=lambda: []
        calls=[]
        def api(method,endpoint):
            calls.append((method,endpoint))
            if "jobs/get" in endpoint: return {"job_id":1,"settings":{"tags":OWNER}}
            if "runs/list" in endpoint: return {}
            if "workspace/export" in endpoint: return {"content":base64.b64encode(json.dumps(OWNER).encode()).decode()}
            schema=endpoint.split("schema_name=")[1].split("&")[0]
            return {"tables":[{"name":obj["table"],"table_type":"VIEW","comment":MARKER} for obj in objects if obj["schema"]==schema and schema=="credicresa"]}
        session.api=api
        messages=[]
        session.log=messages.append
        session.reverse()
        self.assertTrue(all(method=="get" for method,_ in calls))
        self.assertIn("34 vistas",messages[-1])
        self.assertIn("ya ausente",messages[-1])

class SchemaReversalTest(unittest.TestCase):
    def session(self, extra_volume=False, functions=False):
        session=object.__new__(Session)
        inventory={("credicresa",cfg["source_table"]):{} for _,cfg in entities()}
        calls=[]
        def api(method,endpoint):
            calls.append((method,endpoint))
            if "/schemas/" in endpoint:
                return {"comment":"Base fuente de CRESA"}
            if "/volumes?" in endpoint:
                volumes=[{"name":"data","volume_type":"MANAGED","catalog_name":"cresa","schema_name":"credicresa"}]
                if extra_volume: volumes.append({"name":"otro"})
                return {"volumes":volumes}
            if "/functions?" in endpoint:
                return {"functions":[{"name":"ajena"}] if functions else []}
            raise AssertionError(endpoint)
        session.api=api
        return session,inventory,calls

    def test_schema_plan_reads_only_and_never_cascades(self):
        session,inventory,calls=self.session()
        self.assertEqual(session.schema_drop_plan(inventory),
                         ["DROP VOLUME cresa.credicresa.data","DROP SCHEMA cresa.credicresa RESTRICT"])
        self.assertTrue(all(method=="get" for method,_ in calls))

    def test_extra_table_blocks_schema_deletion(self):
        session,inventory,calls=self.session()
        inventory[("credicresa","otro_proyecto")]={}
        with self.assertRaises(ValueError): session.schema_drop_plan(inventory)
        self.assertEqual(calls,[])

    def test_extra_volume_blocks_schema_deletion(self):
        session,inventory,_=self.session(extra_volume=True)
        with self.assertRaises(ValueError): session.schema_drop_plan(inventory)

    def test_function_blocks_schema_deletion(self):
        session,inventory,_=self.session(functions=True)
        with self.assertRaises(ValueError): session.schema_drop_plan(inventory)

    def test_schema_plan_accepts_already_removed_views(self):
        session,inventory,_=self.session()
        self.assertEqual(len(session.schema_drop_plan({})),2)

    def test_final_verification_rejects_remaining_schema(self):
        session,_,_=self.session()
        session.jobs=lambda: []
        session.uc_list=lambda *args: [{"name":"credicresa"}]
        with self.assertRaises(RuntimeError): session.verify_reversal([],1,True)

    def test_final_verification_preserves_unrelated_schema(self):
        session,_,_=self.session()
        session.jobs=lambda: [{"job_id":2}]
        session.uc_list=lambda *args: [{"name":"otro_proyecto"}]
        session.args=argparse.Namespace(workspace_path="/Workspace/Users/test/cresa/credicresa")
        session.api=lambda *args: {"objects":[{"path":"/Workspace/Users/test/cresa/otro_proyecto"}]}
        messages=[]
        session.log=messages.append
        session.verify_reversal([{"schema":"credicresa","table":"x"}],1,True)
        self.assertTrue(messages[-1].startswith("SUCCESS"))

    def test_inventory_error_blocks_schema_deletion(self):
        session,inventory,_=self.session()
        def fail(*args): raise RuntimeError("No autorizado")
        session.api=fail
        with self.assertRaises(RuntimeError): session.schema_drop_plan(inventory)

if __name__=="__main__": unittest.main()
