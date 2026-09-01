# Checklist general de cumplimiento — `cat_sector`

Fecha: 2026-08-27  
Estado: En validación preproducción

## Requisitos de entrega

- [x] 01. Aplicar recomendaciones aprobadas del trabajo previo.
- [x] 02. Crear checklist general de cumplimiento.
- [x] 03. Crear YAML asociado.
- [x] 04. Ubicar YAML en `config/ingestion/`.
- [x] 05. Crear archivo asociado del job.
- [x] 06. Ubicar job en `config/ingestion/job/`.
- [x] 07. Crear JSON asociado.
- [x] 08. Ubicar JSON en `config/ingestion/JSON/`.
- [x] 09. Generar instrucciones de ejecución.
- [x] 10. Incluir conteo por tabla y alerta SMTP.
- [x] 11. Incluir alertas ante validaciones fallidas.
- [x] 12. Actualizar `create_databricks_jobs.ps1` y su versión ampliada.
- [x] 13. Crear curl único para el job de `cat_sector`.
- [x] 14. Añadir SQL y `cat_sector` al script maestro.
- [x] 15. Crear README único descriptivo.
- [x] 16. Validar cumplimiento de tareas.
- [x] 17. Usar la sentencia SQL proporcionada.

## Validaciones técnicas

- [ ] YAML parseado con un validador YAML disponible.
- [x] JSON asociado válido mediante `ConvertFrom-Json`.
- [x] Consulta contiene las nueve columnas solicitadas.
- [x] Tabla origen: `CREDITO_CRESA.dbo.cat_sector`.
- [x] Tabla destino: `dlh_cresa.bronze.credito_cresa_cat_sector`.
- [x] Clave primaria: `id`.
- [x] Incremental configurado con watermark `actualizado`.
- [x] Validaciones de unicidad, binario, nulos y fechas.
- [x] Alertas SMTP para conteo, duración y fallos de calidad.
- [ ] Ejecutar notebook en modo test.
- [ ] Comparar conteo origen/destino.
- [ ] Validar correo SMTP end-to-end.
- [ ] Obtener aprobación formal del Data Owner.

## Matriz de archivos

| Entregable | Ubicación | Estado |
|---|---|---|
| YAML | `templates_ingenieria/config/ingestion/credito_cresa_cat_sector.yml` | Creado |
| Job JSON | `templates_ingenieria/config/ingestion/job/credito_cresa_cat_sector_job.json` | Creado |
| JSON entidad | `templates_ingenieria/config/ingestion/JSON/credito_cresa_cat_sector.json` | Creado |
| Job compatible | `templates_ingenieria/config/jobs/credito_cresa_cat_sector_job.json` | Creado |
| Runbook | `templates_ingenieria/docs/INGEST_credito_cresa_cat_sector_run.md` | Creado |
| Curl | `templates_ingenieria/scripts/create_job_credito_cresa_cat_sector.sh` | Creado |
| PowerShell | `templates_ingenieria/scripts/create_databricks_jobs.ps1` | Creado |
| Script maestro | `templates_ingenieria/scripts/create_all_jobs_comprehensive_v2.sh` | Actualizado |
| Checklist | Este archivo | Creado |
| README | `templates_ingenieria/scripts/README_cat_sector.md` | Creado |

## Resultado

**17 requisitos documentales: 17/17 preparados.** La activación productiva permanece condicionada a las casillas de ejecución, SMTP y aprobación de gobierno.
