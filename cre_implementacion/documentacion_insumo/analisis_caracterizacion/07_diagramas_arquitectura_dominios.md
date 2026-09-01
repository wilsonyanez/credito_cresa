# Diagramas de Arquitectura y Dominios — Fase 3 (CRESA)

> Adaptado del anexo equivalente de Almar Fase 3. Diferencia clave: aquí el catálogo (`dlh_cresa`) y los esquemas por capa (`bronze`, `silver`, `gold`, `staging`, `src`, `externo_cresa`) **ya existen y están en producción** — los diagramas muestran cómo conformar Cliente/Producto dentro de esa estructura, no cómo crearla desde cero.

## Alineación con dominios AS-IS / TO-BE

Fase 3 no redefine los 5 dominios de datos de CRESA. Profundiza en los 2 dominios liderados por Azurian (Cliente, Producto); Financiero, Crédito y Operaciones quedan bajo BusinessIT/Handytech (alcance exacto pendiente de confirmar, ver `06_hipotesis_validacion.md` #4).

| Responsable | Dominios |
|---|---|
| Azurian (Fase 3, este documento) | Cliente, Producto |
| Handytech / BusinessIT | Financiero, Crédito, Operaciones |

## Arquitectura de datos y gobierno — Cliente y Producto

```mermaid
flowchart LR
  subgraph Fuentes["Fuentes operacionales (ya integradas)"]
    D365["Dynamics 365 F&O<br/>OData, prefijo d365_*"]
    SIAC["SIAC<br/>réplica activo-activo"]
    CREDI["CrediCresa / Resuelve"]
    RELEX["RELEX<br/>export ya activo"]
    SFTEST["Salesforce<br/>export en prueba"]
  end

  subgraph Pendientes["Fuentes NO integradas (backlog)"]
    VTEX["Vtex transaccional"]
    VSMART["Venta Smart"]
    GENESYS["Genesys"]
  end

  subgraph Bronze["bronze / staging (ya existen, 173 + 223 tablas)"]
    BR_CLI["customersv3, d365_customerv3,<br/>cecustomers, solicitud_credicresa"]
    BR_PRO["d365_releasedproductsv2,<br/>d365_productattributevaluesv3"]
  end

  subgraph Gold_actual["gold (ya existe, 127 tablas — dimensional maduro)"]
    G_PER["dw_cresa_persona_dim<br/>dw_cresa_persona_siac_dim"]
    G_CRE["dw_cresa_estado_credito_dim<br/>dw_cresa_rango_mora_dim<br/>dw_cresa_dias_atraso_dim<br/>dw_cresa_cartera_saldos_fact"]
    G_PRD["dw_cresa_producto_dim<br/>(+5 versiones backup sin marca)"]
  end

  subgraph Silver_nuevo["silver — conformación NUEVA (Fase 3)"]
    S_CLI["dw_cresa_cliente_conformado<br/>llave num_identificacion"]
    S_PRO["dw_cresa_producto_conformado<br/>llave cod_producto"]
  end

  subgraph Gold_nuevo["gold — golden records NUEVOS (Fase 3)"]
    GM_CLI["dw_cresa_maestro_cliente<br/>_certification_status"]
    GM_PRO["dw_cresa_maestro_producto<br/>_certification_status"]
    GM_SF["dw_cresa_cliente_campos_salesforce<br/>cupo_disponible/flag_contactable/optin_*"]
  end

  subgraph Gov["Gobierno transversal"]
    UC["Unity Catalog<br/>ya desplegado"]
    PV["Microsoft Purview<br/>sin evidencia de despliegue"]
    RBAC["RBAC 8 grupos<br/>NO implementado — account users = ALL_PRIVILEGES"]
  end

  subgraph Consumo["Consumo"]
    SFDC["Salesforce Data Cloud<br/>switch 1 oct 2026"]
    RLX2["RELEX<br/>JDBC directo, listo 22 sep 2026"]
    BI["Power BI"]
  end

  D365 --> BR_CLI
  D365 --> BR_PRO
  SIAC --> G_PER
  CREDI --> G_CRE
  RELEX -.export activo.-> RLX2
  SFTEST -.export en prueba.-> SFDC

  VTEX -.no integrado.-> S_CLI
  VSMART -.no integrado.-> S_CLI
  GENESYS -.no integrado.-> S_CLI

  BR_CLI --> S_CLI
  G_PER --> S_CLI
  G_CRE --> S_CLI
  BR_PRO --> S_PRO
  G_PRD --> S_PRO

  S_CLI --> GM_CLI
  S_CLI --> GM_SF
  G_CRE --> GM_SF
  S_PRO --> GM_PRO

  GM_CLI --> SFDC
  GM_SF --> SFDC
  GM_PRO --> RLX2
  GM_CLI --> BI
  GM_PRO --> BI

  UC -.gobierna.-> Bronze
  UC -.gobierna.-> Silver_nuevo
  UC -.gobierna.-> Gold_nuevo
  PV -.debe catalogar, sin evidencia hoy.-> Gold_nuevo
  RBAC -.debe controlar acceso, no implementado.-> Gold_actual
```

## Dominios de datos por capa — estado real vs. objetivo

```mermaid
flowchart TB
  subgraph Oficial["Dominios oficiales del programa DataOn"]
    DO_CLI["Cliente"]
    DO_PRO["Producto"]
  end

  subgraph EstadoBronze["Bronze — estado real"]
    B_CLI["Parcial: prefijos d365_* conviven<br/>con tablas sin prefijo del mismo origen<br/>(customersv3 sin d365_)"]
    B_PRO["EAV sin pivotar<br/>(d365_productattributevaluesv3)"]
  end

  subgraph EstadoSilver["Silver — estado real (gap confirmado)"]
    S_VACIO["42 tablas totales, sin organización<br/>visible por dominio. La conformación<br/>real ocurre en Gold, no aquí"]
  end

  subgraph EstadoGold["Gold — estado real"]
    G_MADURO["127 tablas, modelo dimensional maduro,<br/>PERO sin _certification_status<br/>y con 5 backups de producto_dim<br/>sin marca de vigencia"]
  end

  subgraph Objetivo["Objetivo Fase 3"]
    O_SILVER["Silver conforma de verdad:<br/>dw_cresa_cliente_conformado<br/>dw_cresa_producto_conformado"]
    O_GOLD["Gold certifica:<br/>dw_cresa_maestro_cliente<br/>dw_cresa_maestro_producto<br/>estado temporal→validado→certificado"]
  end

  DO_CLI -.gobierna.-> B_CLI
  DO_PRO -.gobierna.-> B_PRO
  B_CLI --> S_VACIO
  B_PRO --> S_VACIO
  S_VACIO -.salta la conformación.-> G_MADURO

  B_CLI -.Fase 3 corrige.-> O_SILVER
  B_PRO -.Fase 3 corrige.-> O_SILVER
  O_SILVER --> O_GOLD
  G_MADURO -.no se descarta, se referencia.-> O_GOLD
```

## Mensaje para el cliente

El punto de control más importante de Fase 3 no es cargar datos nuevos — **ya existen 649 tablas**. Es introducir la capa de conformación real en Silver (hoy inexistente para Cliente/Producto) y el estado de certificación en Gold (hoy inexistente en cualquier tabla). Si `num_identificacion` y `cod_producto` quedan conformados con reglas de supervivencia explícitas y trazables, Salesforce y RELEX pueden consumir un maestro único en vez de que cada integrador resuelva el cruce por su cuenta.
