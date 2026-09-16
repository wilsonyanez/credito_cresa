# CRESA — rutas activas

Aplican las reglas del AGENTS.md superior, con estas rutas actualizadas:

- Fuente: config/sources/credicresa.yml.
- Entidades: config/ingestion/credicresa_*.yml (34).
- Job único: config/jobs/job_credicresa_ingesta_periodo.json.
- Despliegue: scripts/cresa_credicresa_desplegar.ps1.
- Reversa: scripts/cresa_credicresa_reversar.ps1.
- Contratos/runtime: lib/cresa_contracts.py y lib/credicresa_runtime.py.
- Diccionario: sql/02_credicresa_catalogos.sql.
- Operación y comandos: README.md.

Cliente CRESA, fuente credicresa, catálogo de pruebas cresa. No tocar artefactos de otros clientes. Mantener una sola implementación en este paquete; los scripts externos son lanzadores. Parquet para datos; Delta para control plane audit01.credicresa_*. Usar tipos explícitos derivados del diccionario, sin inferencia por nombre. Validar 34 entidades/451 atributos, pruebas locales y resultado remoto por separado. La reversa requiere solicitud explícita de ejecución.
