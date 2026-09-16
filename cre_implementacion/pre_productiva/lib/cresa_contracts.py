"""CRESA: contrato de atributos derivado del DDL, sin inferencia por nombre."""
from pathlib import Path
import re
import yaml

ROOT = Path(__file__).resolve().parents[1]
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
TYPE = re.compile(r"^(STRING|BOOLEAN|INT|BIGINT|SMALLINT|TINYINT|DOUBLE|FLOAT|BINARY|DATE|TIMESTAMP_NTZ|TIMESTAMP|DECIMAL\(\d+,\d+\))$")
PERIOD = re.compile(r"^\d{4}-(0[1-9]|1[0-2])(?:-(0[1-9]|[12]\d|3[01]))?$")

def quote(name):
    if not IDENTIFIER.fullmatch(name):
        raise ValueError(f"Identificador invalido: {name!r}")
    return chr(96) + name + chr(96)

def spark_type(sql_type):
    value = re.sub(r"\s+", "", sql_type.upper())
    if re.fullmatch(r"(N?VARCHAR|N?CHAR)\((\d+|MAX)\)", value) or value in {"TEXT", "NTEXT"}:
        return "STRING"
    mapping = {"BIT": "BOOLEAN", "FLOAT(53)": "DOUBLE", "FLOAT(24)": "FLOAT",
               "DATETIME": "TIMESTAMP_NTZ", "VARBINARY(MAX)": "BINARY",
               "INTEGER": "INT"}
    value = mapping.get(value, value)
    if not TYPE.fullmatch(value):
        raise ValueError(f"Tipo SQL no soportado: {sql_type}")
    return value

def dictionary(path):
    text = Path(path).read_text(encoding="utf-8-sig")
    text = re.sub(r"(?m)^\s*--.*$", "", text)
    tables = {}
    pattern = r'CREATE\s+TABLE\s+([A-Za-z_]\w*)\.("[^"]+"|[A-Za-z_]\w*)\s*\((.*?)\)\s*;'
    for match in re.finditer(pattern, text, re.I | re.S):
        schema, table, body = match.groups()
        table = table.strip('"').strip()
        columns = {}
        for line in body.splitlines():
            line = line.strip().lstrip(",").strip()
            if not line:
                continue
            attribute = re.fullmatch(r"(\w+)\s+([A-Za-z]+(?:\s*\([^)]*\))?)", line)
            if not attribute:
                raise ValueError(f"DDL no reconocido en {schema}.{table}: {line}")
            name, original = attribute.groups()
            key = name.lower()
            if key in columns:
                raise ValueError(f"Atributo duplicado: {schema}.{table}.{name}")
            columns[key] = {"sql_type": original.upper(), "type": spark_type(original)}
        key = (schema.lower(), table.lower())
        if key in tables:
            raise ValueError(f"Entidad DDL ambigua: {key}")
        tables[key] = columns
    if not tables:
        raise ValueError("DDL sin entidades")
    return tables

def read_yaml(path):
    return yaml.safe_load(Path(path).read_text(encoding="utf-8-sig").expandtabs(2))

def contract(config):
    columns = config["columns"]
    names = columns["include"]
    types = columns["types"]
    if not isinstance(names, list) or not names or len(set(names)) != len(names):
        raise ValueError("columns.include debe ser una lista unica no vacia")
    if set(names) != set(types):
        raise ValueError("columns.types no cubre exactamente columns.include")
    for name in names:
        quote(name)
        if not TYPE.fullmatch(types[name]):
            raise ValueError(f"Tipo invalido para {name}: {types[name]}")
    return [(name, types[name]) for name in names]

def ddl(config):
    return ", ".join(f"{quote(name)} {kind}" for name, kind in contract(config))

def entities(root=ROOT):
    paths = sorted((Path(root) / "config/ingestion").glob("*.yml"))
    if len(paths) != 34:
        raise ValueError(f"Se esperaban 34 YAML, se encontraron {len(paths)}")
    return [(path, read_yaml(path)) for path in paths]

def sync_types(check=False):
    definitions = dictionary(ROOT / "sql/02_credicresa_catalogos.sql")
    pending = []
    total = 0
    for path, config in entities():
        table = config["source_table"]
        candidates = [(key, values) for key, values in definitions.items() if key[1] == table.lower()]
        if len(candidates) != 1:
            raise ValueError(f"{table}: se esperaba una coincidencia DDL, hay {len(candidates)}")
        (schema, _), attributes = candidates[0]
        names = config["columns"]["include"] if check else list(attributes)
        if not isinstance(names, list):
            raise ValueError(f"{table}: lista de atributos invalida")
        missing = [name for name in names if name.lower() not in attributes]
        omitted = sorted(set(attributes) - {name.lower() for name in names})
        if missing:
            raise ValueError(f"{table}: atributos sin tipo SQL: {missing}")
        desired = {name: attributes[name.lower()]["type"] for name in names}
        original = {name: attributes[name.lower()]["sql_type"] for name in names}
        if check:
            if config["columns"].get("types") != desired or config["columns"].get("source_types") != original:
                raise ValueError(f"{path.name}: contrato desactualizado respecto al SQL")
            contract(config)
            if config["source_name"] != "credicresa" or config["source_schema"] != "landing":
                raise ValueError(f"{path.name}: namespace incorrecto")
            if config["target"]["bronze_table"] != "credicresa_" + table + "_bronze":
                raise ValueError(f"{path.name}: destino incorrecto")
        else:
            config["source_name"] = "credicresa"
            config["source_schema"] = "landing"
            config["dictionary"] = {"file": "sql/02_credicresa_catalogos.sql",
                                    "schema": schema, "table": table,
                                    "attributes_not_selected": omitted}
            config["columns"]["include"] = names
            config["columns"]["types"] = desired
            config["columns"]["source_types"] = original
            config["target"].update(bronze_catalog="cresa", bronze_schema="bronze",
                                    bronze_table="credicresa_" + table + "_bronze",
                                    write_mode_initial="overwrite", write_mode_delta="overwrite")
            config["target"].pop("merge_strategy", None)
            config["control_plane"] = {"run_table": "cresa.audit01.credicresa_ingestion_runs",
                                      "watermark_table": "cresa.audit01.credicresa_ingestion_watermarks",
                                      "error_table": "cresa.audit01.credicresa_ingestion_table_runs"}
            config["schema_evolution"] = {"mode": "strict", "type_widening": "fail"}
            for key in ("primary_key", "natural_key"):
                value = config.get(key, {}).get("columns")
                if isinstance(value, str):
                    config[key]["columns"] = [value]
            pending.append((path, yaml.safe_dump(config, allow_unicode=True, sort_keys=False)))
        total += len(names)
    for path, content in pending:
        path.write_text(content, encoding="utf-8")
    return {"entities": 34, "attributes": total}
