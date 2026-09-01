# Imágenes — Fase 3 (CRESA)

Esta carpeta se conserva por paridad con `Almar/Fase 3/imagenes`, pero en esta iteración los diagramas se dejaron como **Mermaid embebido en Markdown** dentro de `../analisis_caracterizacion/07_diagramas_arquitectura_dominios.md`, en vez de generar PNG estáticos — no se contó con una herramienta de renderizado de imágenes en esta sesión.

## Si se necesitan como PNG/SVG (para un Word/PowerPoint del cliente)

Exportar los 2 bloques Mermaid de `07_diagramas_arquitectura_dominios.md`:

1. "Arquitectura de datos y gobierno — Cliente y Producto"
2. "Dominios de datos por capa — estado real vs. objetivo"

Opciones de exportación:
- `mmdc` (mermaid-cli): `mmdc -i diagrama.mmd -o diagrama.png`
- Pegar el bloque en https://mermaid.live y exportar PNG/SVG (revisar política de datos antes de pegar contenido sensible en una herramienta externa)
- El editor de artifacts de Claude (renderiza Mermaid nativamente) para una vista previa rápida

Nombres sugeridos al exportar, para mantener paridad con Almar:

```text
diagrama_conceptual_bronze_silver_gold_cresa.png
diagrama_dominios_cliente_producto_cresa.png
```
