[CRESA-MSQL-SERVER-DWTANQUESIGMA]

-- credicresa.cat_almacen
CREATE TABLE credicresa.cat_almacen
(
  id VARCHAR(6)
, empresa_id VARCHAR(6)
, grupo_id VARCHAR(8)
, unidadnegocio_id VARCHAR(6)
, canton_id INT
, canal_id VARCHAR(10)
, nombre VARCHAR(50)
, canal_dimension VARCHAR(10)
, unidadnegocio_dimension VARCHAR(20)
, empresacomercial VARCHAR(20)
, aplica_biometria BIT
, es_fisica BIT
, es_activo BIT
, direccion VARCHAR(200)
, canal_externo_id VARCHAR(10)
)
;

-- credicresa.cat_canton
CREATE TABLE credicresa.cat_canton
(
  id INT
, provincia_id INT
, cod VARCHAR(6)
, pais_cod VARCHAR(3)
, provincia_cod VARCHAR(6)
, nombre VARCHAR(50)
, prefijo VARCHAR(4)
, cinec VARCHAR(4)
, es_activo BIT
)
;

-- credicresa.cat_dependencia
CREATE TABLE credicresa.cat_dependencia
(
  id VARCHAR(3)
, nombre VARCHAR(50)
, es_activo BIT
, fecha_creacion VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
)
;

-- credicresa.cat_estadocivil
CREATE TABLE credicresa.cat_estadocivil
(
  id VARCHAR(6)
, nombre VARCHAR(50)
)
;

-- credicresa.cat_estadoverificacion
CREATE TABLE credicresa.cat_estadoverificacion
(
  id INT
, nombre VARCHAR(100)
, activo BIT
, tipo_verificacion VARCHAR(8)
, resolutivo VARCHAR(50)
, naturaleza VARCHAR(4)
)
;

-- credicresa.cat_modelo_aprobador
CREATE TABLE credicresa.cat_modelo_aprobador
(
  id INT
, calificacion_buro_id VARCHAR(1)
, calificacion_confianza_id VARCHAR(1)
, calificacion_final_id VARCHAR(1)
, origen_id VARCHAR(10)
, zona_riesgo_id VARCHAR(8)
, tipo_cliente_id VARCHAR(150)
, dependencia_id VARCHAR(50)
, grupo_id VARCHAR(8)
, edad_min INT
, edad_max INT
, nacionalidad VARCHAR(50)
, capacidad_pago DECIMAL(5,2)
, tipo_verificacion VARCHAR(50)
, entrada_base DECIMAL(5,2)
, es_activo BIT
, fecha_creacion VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, unidadnegocio_id VARCHAR(6)
, canal_id VARCHAR(6)
)
;

-- credicresa.cat_modelo_calificacion
CREATE TABLE credicresa.cat_modelo_calificacion
(
  id VARCHAR(8)
, nombre VARCHAR(50)
, es_activo BIT
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, confianza_desde INT
, confianza_hasta INT
)
;

-- credicresa.cat_nacionalidad
CREATE TABLE credicresa.cat_nacionalidad
(
  id VARCHAR(6)
, nombre VARCHAR(100)
, es_activo BIT
)
;

-- credicresa.cat_nivelinstruccion 
CREATE TABLE credicresa.cat_nivelinstruccion
(
  id VARCHAR(6)
, nombre VARCHAR(50)
)
;


-- credicresa.cat_origen
CREATE TABLE credicresa.cat_origen
(
  id VARCHAR(10)
, nombre VARCHAR(100)
, es_activo BIT
, fecha_creacion VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, codigo_externo INT
)
;

-- credicresa.cat_parroquia
CREATE TABLE credicresa.cat_parroquia
(
  id INT
, canton_id INT
, pais_cod VARCHAR(3)
, provincia_cod VARCHAR(6)
, canton_cod VARCHAR(6)
, cod VARCHAR(6)
, nombre VARCHAR(100)
, cinec VARCHAR(8)
, es_activo BIT
)
;

-- credicresa."cat_profesion "
CREATE TABLE credicresa."cat_profesion "
(
  id VARCHAR(6)
, nombre VARCHAR(50)
, es_activo BIT
)
;

-- credicresa.cat_provincia
CREATE TABLE credicresa.cat_provincia
(
  id INT
, pais_id INT
, cod VARCHAR(6)
, pais_cod VARCHAR(3)
, region_cod VARCHAR(3)
, nombre VARCHAR(100)
, cinec VARCHAR(8)
, es_activo BIT
)
;

-- credicresa.cat_sector
CREATE TABLE credicresa.cat_sector
(
  id INT
, nombre TEXT
, es_activo BIT
, cat_zona_id INT
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, gestor_id INT
)
;

-- credicresa.cat_sector_riesgo_geocerca
CREATE TABLE credicresa.cat_sector_riesgo_geocerca
(
  id INT
, cat_sector_riesgo_id INT
, latitud FLOAT(53)
, longitud FLOAT(53)
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
)
;

-- credicresa.cat_sexo
CREATE TABLE credicresa.cat_sexo
(
  id VARCHAR(6)
, nombre VARCHAR(50)
)
;

-- credicresa.cat_solicitud_estados
CREATE TABLE credicresa.cat_solicitud_estados
(
  id VARCHAR(50)
, nombre VARCHAR(150)
, es_activo BIT
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
)
;

-- credicresa.cat_tipoverificacion
CREATE TABLE credicresa.cat_tipoverificacion
(
  id VARCHAR(8)
, nombre VARCHAR(100)
, jerarquia INT
, estado BIT
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, naturaleza VARCHAR(8)
)
;

-- credicresa.cat_tipovinculo
CREATE TABLE credicresa.cat_tipovinculo
(
  id VARCHAR(6)
, nombre VARCHAR(50)
, es_activo VARCHAR(2)
)
;

-- credicresa.cfg_controlsecuencia
CREATE TABLE credicresa.cfg_controlsecuencia
(
  nombre_secuencia VARCHAR(8)
, ultimo_numero BIGINT
)
;

-- credicresa.cre_solicitante
CREATE TABLE credicresa.cre_solicitante
(
  id BIGINT
, cod_cliente VARCHAR(8)
, tipo_cliente VARCHAR(10)
, es_activo BIT
, apellido_1 VARCHAR(100)
, apellido_2 VARCHAR(100)
, nombre_1 VARCHAR(100)
, nombre_2 VARCHAR(100)
, fecha_nacimiento VARCHAR(10)
, nacionalidad_id VARCHAR(6)
, sexo_id VARCHAR(6)
, estado_civil_id VARCHAR(6)
, nivel_educacion_id VARCHAR(6)
, profesion_id VARCHAR(6)
, identificacion VARCHAR(13)
, celular VARCHAR(10)
, cliente_referencia_ubicacion VARCHAR(200)
, cliente_calle_principal VARCHAR(100)
, cliente_calle_transversal VARCHAR(100)
, cliente_numero_casa VARCHAR(10)
, provincia_id INT
, canton_id INT
, parroquia_id INT
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, cuota_estimada DECIMAL(8,2)
, fecha_cuota_estimada VARCHAR(27)
, cliente_direccion VARCHAR(500)
, email VARCHAR(300)
, numero_cargas INT
, nacionalidad VARCHAR(10)
)
;

-- credicresa.cre_solicitante_mina
CREATE TABLE credicresa.cre_solicitante_mina
(
  id BIGINT
, solicitante_id BIGINT
, propiedad VARCHAR(50)
, valor TEXT
)
;

-- credicresa.cre_solicitud
CREATE TABLE credicresa.cre_solicitud
(
  id BIGINT
, empresa_id VARCHAR(6)
, unidad_negocio_id VARCHAR(6)
, canal_id VARCHAR(10)
, solicitante_id BIGINT
, secuencia_cupo BIGINT
, tipo_solicitud VARCHAR(6)
, almacen_oficina VARCHAR(50)
, tipo_credito_id VARCHAR(6)
, tipo_emprendedor_id VARCHAR(6)
, identificacion_emprendedor VARCHAR(13)
, grupo_cliente VARCHAR(30)
, grupo_impuesto VARCHAR(30)
, modo_pago VARCHAR(30)
, origen_credito_id VARCHAR(10)
, vendedor VARCHAR(8)
, cuota_sugerida DECIMAL(8,2)
, cuota_solicitada DECIMAL(8,2)
, cuota_aprobada DECIMAL(8,2)
, estado VARCHAR(20)
, actualizado VARCHAR(23)
, actualizado_por INT
, creado VARCHAR(23)
, creado_por INT
, secuencia_no BIGINT
, calificacion_buro_id VARCHAR(8)
, calificacion_confianza_id VARCHAR(8)
, calificacion_final_id VARCHAR(8)
, fecha_cambio_estado VARCHAR(27)
, notificacion_acepto BIT
, notificacion_enviada_id BIGINT
, salario_depurado DECIMAL(18,2)
, capacidad_pago DECIMAL(5,2)
, tipo_verificacion VARCHAR(100)
, tipo_verificacion_final VARCHAR(100)
, dia_pago_corte_activo INT
, entrada_base DECIMAL(5,2)
, codigo_cliente INT
, ciclo_corte_cliente INT
, biometria_estado VARCHAR(10)
, biometria_id BIGINT
, lib_direccion_almacen TEXT
, lib_usuario_id BIGINT
, lib_fecha_realizar VARCHAR(23)
, mina_telefono_1 VARCHAR(15)
, mina_telefono_2 VARCHAR(15)
, mina_correo_1 VARCHAR(150)
, mina_correo_2 VARCHAR(150)
, mina_score DECIMAL(7,2)
, final_score DECIMAL(7,2)
, verificacion_original VARCHAR(100)
, verificacion_activa BIT
, modelo_aprobador_id INT
, almacen_origen_id VARCHAR(50)
, riesgo_id VARCHAR(8)
, contador_intentos INT
, vendedor_usuario_id INT
, regestion_intentos INT
, cobertura_intentos INT
)
;

-- credicresa.cre_solicitud_bitacora
CREATE TABLE credicresa.cre_solicitud_bitacora
(
  id BIGINT
, solicitud_id BIGINT
, estado VARCHAR(20)
, creado VARCHAR(27)
, creado_por INT
)
;

-- credicresa.cre_solicituddomicilio
CREATE TABLE credicresa.cre_solicituddomicilio
(
  id BIGINT
, solicitud_id BIGINT
, provincia_id INT
, canton_id INT
, parroquia_id INT
, direccion VARCHAR(500)
, sector VARCHAR(200)
, calle_principal VARCHAR(200)
, calle_transversal VARCHAR(100)
, tipo_domicilio VARCHAR(6)
, referencia VARCHAR(200)
, telefono_fijo VARCHAR(20)
, celular VARCHAR(10)
, tipo_propiedad VARCHAR(6)
, tipo_vivienda VARCHAR(6)
, tiempo_residencia INT
, ubicacion_longitud FLOAT(53)
, ubicacion_latitud FLOAT(53)
, ubicacion_mapa VARCHAR(200)
, es_actual BIT
, manzana VARCHAR(10)
, villa VARCHAR(10)
, actualizado VARCHAR(27)
, actualizado_por INT
, creado VARCHAR(27)
, creado_por INT
)
;

-- credicresa.cre_solicitudlaboral
CREATE TABLE credicresa.cre_solicitudlaboral
(
  id BIGINT
, solicitud_id BIGINT
, provincia_id INT
, canton_id INT
, parroquia_id INT
, actividad_laboral_id VARCHAR(8)
, actividad_economica_id VARCHAR(10)
, cargas_familiares INT
, calle_principal VARCHAR(100)
, calle_transversal VARCHAR(100)
, nombre_empresa VARCHAR(200)
, salario DECIMAL(10,2)
, origen_ingresos VARCHAR(100)
, direccion VARCHAR(500)
, sector VARCHAR(50)
, referencia VARCHAR(250)
, tiempo_laboral INT
, fecha_ingreso_laboral VARCHAR(27)
, telefono_fijo VARCHAR(20)
, celular VARCHAR(10)
, relacion_dependencia_id VARCHAR(6)
, profesion_id VARCHAR(6)
, es_actual BIT
, actualizado VARCHAR(27)
, actualizado_por INT
, creado VARCHAR(27)
, creado_por INT
)
; 

-- credicresa.cre_solicitudreferencia
CREATE TABLE credicresa.cre_solicitudreferencia
(
  id BIGINT
, solicitud_id BIGINT
, parroquia_id INT
, tipo_vinculo_id VARCHAR(6)
, nombres VARCHAR(100)
, telefono_fijo VARCHAR(20)
, celular VARCHAR(10)
, operadora_celular VARCHAR(10)
, es_actual BIT
, apellidos VARCHAR(100)
, actualizado VARCHAR(27)
, actualizado_por INT
, creado VARCHAR(27)
, creado_por INT
)
;

-- credicresa.lcr_cuentas
CREATE TABLE credicresa.lcr_cuentas
(
  id BIGINT
, codigo_cliente BIGINT
, identificacion VARCHAR(20)
, tipo_identificacion VARCHAR(20)
, nombre1 VARCHAR(100)
, nombre2 VARCHAR(100)
, apellido1 VARCHAR(100)
, apellido2 VARCHAR(100)
, celular VARCHAR(20)
, email VARCHAR(100)
, es_activa BIT
, cuota_maxima DECIMAL(18,2)
, cuota_reservada DECIMAL(18,2)
, solicitante_id BIGINT
, solicitud_origen_id BIGINT
, creado VARCHAR(27)
, creado_por INT
, actualizado VARCHAR(27)
, actualizado_por INT
, segmento_id VARCHAR(8)
, direccion_domicilio VARCHAR(500)
)
;

-- credicresa.lcr_graduacion
CREATE TABLE credicresa.lcr_graduacion
(
  id INT
, graduacion_id BIGINT
, codigo_empresa VARCHAR(10)
, codigo_cliente VARCHAR(20)
, calificacion_anterior VARCHAR(10)
, calificacion_nueva VARCHAR(10)
, indicador_rescate BIT
, cantidad_cortes_evaluados INT
, maximo_dias_atraso INT
, creado VARCHAR(27)
, creado_por INT
, fecha_corte VARCHAR(27)
, envio_notificacion VARCHAR(1)
, estado_registro VARCHAR(1)
, segmento_anterior_id VARCHAR(10)
, segmento_nuevo_id VARCHAR(10)
, identificacion VARCHAR(13)
, capacidad_pago DECIMAL(5,2)
, tipo_cliente VARCHAR(10)
, relacion_dependencia_id VARCHAR(6)
, unidad_negocio_id VARCHAR(6)
, canal_id VARCHAR(10)
, grupo_id VARCHAR(8)
, edad INT
, nacionalidad VARCHAR(50)
, riesgo_id VARCHAR(8)
, politica_id INT
, salario_depurado DECIMAL(10,2)
, origen_credito_id VARCHAR(10)
, cuota_maxima_anterior DECIMAL(18,2)
, cuota_maxima_nueva DECIMAL(18,2)
, almacen_oficina VARCHAR(50)
, lcr_id BIGINT
, segmento_lcr_anterior VARCHAR(10)
, estado_procesamiento VARCHAR(1)
, estado_notificacion VARCHAR(1)
, error_notificacion VARCHAR(500)
, fecha_recepcion VARCHAR(27)
, fecha_procesamiento VARCHAR(27)
, error_descripcion VARCHAR(500)
, bitacora_id BIGINT
, solicitante_id BIGINT
, cuenta_id BIGINT
, intentos_procesamiento INT
, origen_datos VARCHAR(50)
)
;

-- credicresa.lcr_reserva_cuotas
CREATE TABLE credicresa.lcr_reserva_cuotas
(
  id BIGINT
, cuenta_id BIGINT
, empresa_id VARCHAR(6)
, almacen_id VARCHAR(6)
, origen VARCHAR(10)
, pedido_id VARCHAR(10)
, monto DECIMAL(18,6)
, es_activo BIT
, creado_por INT
, creado VARCHAR(27)
, actualizado_por INT
, actualizado VARCHAR(27)
, sobre_cupo DECIMAL(18,6)
)
;

-- credicresa.sec_usuario
CREATE TABLE credicresa.sec_usuario
(
  Id INT
, perfil_id INT
, almacen_id VARCHAR(6)
, email VARCHAR(300)
, nombre_completo VARCHAR(300)
, activo BIT
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, clave VARCHAR(20)
, identificacion VARCHAR(35)
)
;

-- credicresa.sis_peticiones 
CREATE TABLE credicresa.sis_peticiones
(
  id BIGINT
, identificacion VARCHAR(10)
, api VARCHAR(100)
, metodo VARCHAR(20)
, url VARCHAR(2048)
, request TEXT
, status VARCHAR(150)
, response TEXT
, creado VARCHAR(27)
, creado_por INT
)
;

-- credicresa.ver_respuesta_proveedor
CREATE TABLE credicresa.ver_respuesta_proveedor
(
  id BIGINT
, verificacion_id BIGINT
, solicitud_id BIGINT
, gestor_id INT
, motivo TEXT
, fecha_resolucion VARCHAR(27)
, estado VARCHAR(100)
, evidencia_url TEXT
, comentario TEXT
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
)
;

-- credicresa.ver_transaccional_verificacion
CREATE TABLE credicresa.ver_transaccional_verificacion
(
  id BIGINT
, solicitud_id BIGINT
, verificador_id INT
, tipo_verificacion_id VARCHAR(8)
, estado_verificacion INT
, fecha_verificacion VARCHAR(27)
, creado VARCHAR(27)
, actualizado VARCHAR(27)
, creado_por INT
, actualizado_por INT
, latitud FLOAT(53)
, longitud FLOAT(53)
, tipo_asignacion VARCHAR(20)
, sector_id INT
, provincia_id INT
, canton_id INT
, parroquia_id INT
, almacen_id VARCHAR(6)
, direccion VARCHAR(300)
, estado_envio_terceros VARCHAR(10)
, fecha_envio_terceros VARCHAR(27)
, anterior_verificacion_id BIGINT
, solicitud_intento INT
)
;

-- dbo.AUTORIZACION
CREATE TABLE dbo.AUTORIZACION
(
  ID INT
, APP_UID VARCHAR(32)
, APP_NUMBER INT
, IDENTIFICACION_ENVIO VARCHAR(13)
, CELULAR_ENVIO VARCHAR(15)
, CORREO_ENVIO VARCHAR(50)
, CALLBACK_ENVIO VARCHAR(50)
, TITULO_ENVIO VARCHAR(100)
, LEYENDA_ENVIO TEXT
, GRUPO_ENVIO VARCHAR(100)
, FORMULARIO_ENVIO VARBINARY(MAX)
, RETORNO_ENVIO VARCHAR(200)
, FORCE_ENVIO VARCHAR(1)
, STATUS INT
, ERROR INT
, MENSAJE VARCHAR(50)
, IDENTIFICACION_RESPUESTA VARCHAR(13)
, CELULAR_RESPUESTA VARCHAR(15)
, CORREO_RESPUESTA VARCHAR(50)
, CODIGO_RESPUESTA VARCHAR(50)
, URL_RESPUESTA VARCHAR(80)
, GRUPO_RESPUESTA VARCHAR(100)
, VALIDACION_RESPUESTA VARCHAR(100)
, INTENTOS_RESPUESTA VARCHAR(100)
, FCREACION_RESPUESTA VARCHAR(50)
, FMODIFICACION_RESPUESTA VARCHAR(50)
, FABIERTO_RESPUESTA VARCHAR(100)
, IP_RESPUESTA VARCHAR(20)
, ESTADO_RESPUESTA VARCHAR(100)
, CALLBACK_RESPUESTA VARCHAR(100)
, FORMULARIO_RESPUESTA VARBINARY(MAX)
, TIPO_RESPUESTA VARCHAR(20)
, FECHA_CREACION DATETIME
, FECHA_ELIMINACION DATETIME
, FECHA_ACTUALIZACION DATETIME
)
;

-- dbo.BITACORA
CREATE TABLE dbo.BITACORA
(
  APP_UID VARCHAR(32)
, SOLICITUD INT
, TAS_UID VARCHAR(32)
, USR_UID VARCHAR(32)
, NUM INT
, TAREA VARCHAR(25)
, FECHA_INICIO DATETIME
, COMENTARIO TEXT
, ESTADO VARCHAR(32)
, FECHA_FIN DATETIME
)
;

-- dbo.CLIENTE_CONYUGUE_DATOS
CREATE TABLE dbo.CLIENTE_CONYUGUE_DATOS
(
  APP_UID VARCHAR(32)
, CLIENTE_CEDULA VARCHAR(10)
, CLIENTE_CONYUGUE_CEDULA VARCHAR(10)
, CLIENTE_CONYUGUE_APELLIDO_PATERNO VARCHAR(100)
, CLIENTE_CONYUGUE_APPELLIDO_MATERNO VARCHAR(100)
, CLIENTE_CONYUGUE_NOMBRE1 VARCHAR(100)
, CLIENTE_CONYUGUE_NOMBRE2 VARCHAR(100)
, CLIENTE_CONYUGUE_NUMERO_CELULAR1 VARCHAR(10)
, CLIENTE_CONYUGUE_CELULAR2 VARCHAR(10)
)
;

-- dbo.CLIENTE_DATOS
CREATE TABLE dbo.CLIENTE_DATOS
(
  APP_UID VARCHAR(32)
, APP_NUMBER INT
, SOLICITUD_FECHA_HORA DATETIME
, CLIENTE_CEDULA VARCHAR(10)
, CLIENTE_APELLIDO_PATERNO VARCHAR(100)
, CLIENTE_APELLIDO_MATERNO VARCHAR(100)
, CLIENTE_NOMBRE1 VARCHAR(100)
, CLIENTE_NOMBRE2 VARCHAR(100)
, ESTADO VARCHAR(30)
, CLIENTE_ACTIVIDAD_ECONOMICA VARCHAR(20)
, CLIENTE_EDAD INT
, CLIENTE_NUMERO_CELULAR1 VARCHAR(10)
, ID INT
, ESTADO_VERIFICACION VARCHAR(20)
, MOTIVO_VERIFICACION VARCHAR(200)
, FECHA_VERIFICACION DATETIME
, SOLICITUD_TIENDA VARCHAR(50)
, COMENTARIO_VERIFICACION VARCHAR(200)
, CLIENTE_CANTON_NACIMIENTO VARCHAR(10)
, USUARIO_VERIFICACION VARCHAR(50)
, CLIENTE_FECHA_NACIMIENTO DATETIME
, CLIENTE_TELEFONO_FIJO VARCHAR(10)
, CLIENTE_TIPO_SOLICITANTE VARCHAR(100)
, CLIENTE_ESTADO_CIVIL VARCHAR(20)
, CLIENTE_CORREO VARCHAR(100)
, CLIENTE_BARRIO VARCHAR(100)
, CLIENTE_SECTOR VARCHAR(100)
, CLIENTE_REFERENCIA_UBICACION VARCHAR(100)
, CLIENTE_CALLE_PRINCIPAL VARCHAR(100)
, CLIENTE_CALLE_TRANSVERSAL VARCHAR(100)
, CLIENTE_CANTON VARCHAR(20)
, CLIENTE_PARROQUIA VARCHAR(20)
, CLIENTE_PROVINCIA VARCHAR(20)
, CLIENTE_GRUPO_FAMILIAR INT
, CLIENTE_NUMERO_CASA VARCHAR(30)
, CLIENTE_NUMERO_WHATSAPP VARCHAR(10)
, CLIENTE_NUMERO_CELULAR2 VARCHAR(10)
, CLIENTE_CEDULA_CONYUGUE VARCHAR(10)
, CLIENTE_TIPO_REDSOCIAL VARCHAR(10)
, CLIENTE_REDSOCIAL VARCHAR(100)
, FECHA_CREACION DATETIME
, FECHA_ACTUALIZACION DATETIME
, DIRECCION_MAPS VARCHAR(400)
, CLIENTE_LATITUD VARCHAR(50)
, CLIENTE_LONGITUD VARCHAR(50)
, CLIENTE_VIVIENDA VARCHAR(10)
, SOLICITUD_COD_TIENDA VARCHAR(10)
)
;

-- dbo."CLIENTE_DATOS_LABORAL "
CREATE TABLE dbo."CLIENTE_DATOS_LABORAL "
(
  ID INT
, APP_UID VARCHAR(32)
, CLIENTE_CEDULA VARCHAR(50)
, CLIENTE_NOMBRE_NEGOCIO VARCHAR(50)
, CLIENTE_CALLE_PRINCIPAL_TRABAJO VARCHAR(100)
, CLIENTE_NUMERO_TRABAJO VARCHAR(50)
, CLIENTE_CALLE_TRANSVERSAL_TRABAJO VARCHAR(100)
, CLIENTE_REFERENCIA_UBICACION_TRABAJO VARCHAR(100)
, CLIENTE_TELEFONO_FIJO_TRABAJO VARCHAR(50)
, CLIENTE_CELULAR_TRABAJO VARCHAR(50)
, CLIENTE_LONGITUD_TRABAJO VARCHAR(50)
, CLIENTE_LATITUD_TRABAJO VARCHAR(50)
, CLIENTE_PROVINCIA_LABORAL VARCHAR(100)
, CLIENTE_CANTON_LABORAL VARCHAR(100)
, CLIENTE_PARROQUIA_LABORAL VARCHAR(100)
, CLIENTE_TIPO_ACTIVIDAD_ECONOMICA VARCHAR(20)
, CLIENTE_ACTIVIDAD_ECONOMICA VARCHAR(20)
, CLIENTE_SUBACTIVIDAD VARCHAR(20)
, FECHA_CREACION DATETIME
, FECHA_ACTUALIZACION DATETIME
, FECHA_ELIMINACION DATETIME
)
;

-- dbo.DAT_ANALISTA
CREATE TABLE dbo.DAT_ANALISTA
(
  APP_UID VARCHAR(96)
, COD_PRODUCTO VARCHAR(20)
, TIPO_SOLICITANTE VARCHAR(30)
, SEGMENTO_FINAL VARCHAR(5)
, SOLICITUD INT
, ESTADO_MODELO_INTERNO VARCHAR(2)
, CALIFICACION_ICS_MODELO_INTERNO VARCHAR(2)
, CANAL_ORIGEN VARCHAR(50)
, CALIFICACION_SOCIO_DEMOGRAFICO_MODELO_INTERNO VARCHAR(2)
, RESPUESTA_VERIFICACION VARCHAR(50)
, REGION VARCHAR(50)
, CLIENTE_CEDULA VARCHAR(30)
, CALIFICACION_BM_MODELO_INTERNO VARCHAR(2)
, CODIGO_TIENDA VARCHAR(60)
, FECHA_CREACION DATETIME
, COD_FAMILIA VARCHAR(50)
, PRECALIFICACION VARCHAR(8)
, OTPD_TIPO VARCHAR(20)
, SCORE_BURO VARCHAR(150)
, SEGMENTO_BURO VARCHAR(150)
, CODIGO_BIOMETRIA VARCHAR(50)
, URL_BIOMETRIA VARCHAR(200)
, STATUS_BIOMETRIA VARCHAR(5)
, OTPD_CODIGO VARCHAR(50)
, CALIFICACION_CR_MODELO_INTERNO VARCHAR(2)
, CUENTA VARCHAR(50)
, USUARIO_CREADOR VARCHAR(134)
, RESPUESTA_VERIFICACION_CRESA VARCHAR(30)
)
;

-- dbo.DAT_CATALOGO
CREATE TABLE dbo.DAT_CATALOGO
(
  ID INT
, PRO_UID VARCHAR(40)
, TAS_UID VARCHAR(40)
, COD_CATALOGO VARCHAR(40)
, CODIGO VARCHAR(40)
, DESCRIPCION VARCHAR(400)
, VALOR VARCHAR(500)
, CODIGO_INTEGRACION VARCHAR(40)
, CAMPO1 VARCHAR(150)
, CAMPO2 VARCHAR(50)
, DEPENDIENTE VARCHAR(50)
, ESTADO INT
, FECHA_INSERCION DATETIME
, FECHA_MODIFICACION DATETIME
)
;

-- dbo.DAT_MATRIZ_VERIFICACION
CREATE TABLE dbo.DAT_MATRIZ_VERIFICACION
(
  REGION VARCHAR(50)
, SEGMENTO_FINAL VARCHAR(5)
, TIPO_SOLICITANTE VARCHAR(100)
, NACIONALIDAD VARCHAR(20)
, CANAL_ORIGEN VARCHAR(50)
, CLIENTE_CEDULA VARCHAR(10)
, RESPUESTA_VERIFICACION TEXT
, APP_UID VARCHAR(32)
, FECHA_VERIFICACION DATETIME
)
;

-- dbo.EQUIFAX_WS
CREATE TABLE dbo.EQUIFAX_WS
(
  SEGMENTACION VARCHAR(150)
, FECHA_CREACION DATETIME
, FECHA_ACTUALIZACION DATETIME
, FECHA_ELIMINACION DATETIME
, IDENTIFICACION VARCHAR(45)
)
;

-- dbo.HISTORICO_CAMBIO_POLITICAS
CREATE TABLE dbo.HISTORICO_CAMBIO_POLITICAS
(
  ID INT
, APP_UID VARCHAR(32)
, APP_NUMBER INT
, CEDULA_CLIENTE VARCHAR(13)
, USR_UID_ANALISTA VARCHAR(32)
, NOMBRE_ANALISTA VARCHAR(100)
, COD_AGENCIA VARCHAR(50)
, NOMBRE_AGENCIA VARCHAR(100)
, FAMILIA VARCHAR(100)
, CUPO DECIMAL(15,2)
, CUOTA DECIMAL(15,2)
, PLAZO INT
, ENTRADA DECIMAL(15,2)
, FECHA_CAMBIO DATETIME
)
;

-- dbo.LISTAS_NEGRAS_AUTOMATICAS
CREATE TABLE dbo.LISTAS_NEGRAS_AUTOMATICAS
(
  ID INT
, APP_NUMBER INT
, APP_UID VARCHAR(32)
, CEDULA VARCHAR(10)
, CODIGO_BLOQUEO VARCHAR(10)
, DESCRIPCION_BLOQUEO VARCHAR(50)
, ESTADO INT
, USR_UID_CREACION VARCHAR(32)
, USR_UID_MODIFICACION VARCHAR(32)
, FECHA_CREACION DATETIME
, FECHA_MODIFICACION DATETIME
)
;

-- dbo.LOG_SCRAPPING
CREATE TABLE dbo.LOG_SCRAPPING
(
  CLIENTE_CEDULA VARCHAR(30)
, CONSULTAS BIGINT
, DATA VARBINARY(MAX)
, RESULTADO_WS VARCHAR(10)
, ANIO INT
, MES INT
, NOMBRE_WS VARCHAR(150)
)
;

-- dbo.LOG_VERIFICACION_PREGUNTAS
CREATE TABLE dbo.LOG_VERIFICACION_PREGUNTAS
(
  ID INT
, APP_NUMBER VARCHAR(50)
, CODIGO_INTERNO VARCHAR(100)
, CEDULA VARCHAR(20)
, CORREO VARCHAR(100)
, CELULAR VARCHAR(15)
, TOKEN VARCHAR(100)
, DATA_PREGUNTAS TEXT
, RESPUESTA_API TEXT
, CALIFICACION INT
, CALIFICACION_MENSAJE VARCHAR(100)
, CANAL VARCHAR(30)
, ESTADO VARCHAR(100)
, CALLBACK_CLIENTE TEXT
, CALLBACK_CHATBOT TEXT
, USUARIO VARCHAR(100)
, FECHA_CREACION DATETIME
, FECHA_MODIFICACION DATETIME
, FECHA_ELIMINACION DATETIME
)
;

-- dbo.OFERTA_COMERCIAL
CREATE TABLE dbo.OFERTA_COMERCIAL
(
  APP_UID VARCHAR(32)
, COD_FAMILIA VARCHAR(50)
, CUPO INT
, ENTRADA FLOAT(53)
, PLAZO INT
, CUOTA FLOAT(53)
, CEDULA VARCHAR(13)
, CANAL VARCHAR(20)
, TIENDA VARCHAR(32)
, FECHA_ACTUALIZACION DATETIME
, APP_NUMBER INT
, CUPO_UTILIZADO DECIMAL(10,2)
, CUPO_DISPONIBLE DECIMAL(10,2)
)
;

-- dbo.REFERENCIAS_PERSONALES
CREATE TABLE dbo.REFERENCIAS_PERSONALES
(
  APP_UID VARCHAR(32)
, CLIENTE_CEDULA VARCHAR(10)
, CLIENTE_REFERENCIAS_PERSONALES_APELLIDO_PATERNO1 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_APELLIDO_MATERNO1 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_NOMBRE1 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_PARENTESCO1 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_CELULAR1 VARCHAR(10)
, CLIENTE_REFERENCIAS_PERSONALES_FIJO1 VARCHAR(10)
, ESTADO INT
, FECHA_CREACION DATETIME
, FECHA_ACTUALIZACION DATETIME
, FECHA_ELIMINACION DATETIME
, OBSERVACION_VENDEDOR VARCHAR(200)
, CLIENTE_REFERENCIAS_PERSONALES_APELLIDO_PATERNO2 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_APELLIDO_MATERNO2 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_NOMBRE2 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_PARENTESCO2 VARCHAR(30)
, CLIENTE_REFERENCIAS_PERSONALES_CELULAR2 VARCHAR(10)
, CLIENTE_REFERENCIAS_PERSONALES_FIJO2 VARCHAR(10)
)
;

-- dbo.SYS_USUARIOS
CREATE TABLE dbo.SYS_USUARIOS
(
  USR_UID VARCHAR(32)
, USR_USERNAME VARCHAR(30)
, USR_FECHA_CREACION DATETIME
, USR_COD_ASESOR VARCHAR(10)
, USR_NOMBRE VARCHAR(50)
, USR_ESTADO INT
, USR_COD_TIENDA VARCHAR(32)
)
;

-- dbo.TELEFONOS_BLOQUEADOS
CREATE TABLE dbo.TELEFONOS_BLOQUEADOS
(
  ID INT
, COD_TIENDA VARCHAR(5)
, TELEFONO VARCHAR(10)
, MOTIVO VARCHAR(200)
, ESTADO VARCHAR(1)
, FECHA_CREACION DATETIME
, FECHA_ACTUALIZACION DATETIME
, FECHA_ELIMINACION DATETIME
, USR_UID VARCHAR(40)
)
;

-- dbo.consulta_sigma_verificaciones
CREATE TABLE dbo.consulta_sigma_verificaciones
(
  idPersonas INT
, cmpIdentificacion VARCHAR(10)
, mensaje TEXT
, cmpRegion VARCHAR(50)
, ESTADO VARCHAR(30)
, PRECALIFICACION VARCHAR(8)
, cupo INT
)
;

-- dbo.tb_Indicadores_DeudaActual_SbsSicomRfr_combined
CREATE TABLE dbo.tb_Indicadores_DeudaActual_SbsSicomRfr_combined
(
  identificacion VARCHAR(255)
, id FLOAT(53)
, FechaCorte VARCHAR(255)
, Segmento VARCHAR(255)
, Institucion VARCHAR(255)
, TipoDeudor VARCHAR(255)
, TipoCredito VARCHAR(255)
, Calificacion VARCHAR(255)
, PorVencer FLOAT(53)
, NoDevengaInt FLOAT(53)
, Vencido FLOAT(53)
, DemandaJudicial FLOAT(53)
, CarteraCastigada FLOAT(53)
, Total FLOAT(53)
, DiasVencido VARCHAR(255)
)
;

-- dbo.tb_Indicadores_NODeudaActual_SbsSicomRfr_combined
CREATE TABLE dbo.tb_Indicadores_NODeudaActual_SbsSicomRfr_combined
(
  id FLOAT(53)
, identificacion VARCHAR(255)
, deuda_actual VARCHAR(255)
)
;

-- dbo.tbl_equifax_ws_sigma
CREATE TABLE dbo.tbl_equifax_ws_sigma
(
  id INT
, appUid VARCHAR(96)
, identificacion VARCHAR(45)
, score VARCHAR(150)
, segmentacion VARCHAR(150)
, ingresos VARCHAR(150)
, gastosFinancierosMensuales VARCHAR(150)
, capacidadPagoMensual VARCHAR(150)
, politica VARCHAR(396)
, valor VARCHAR(69)
, tiempoBloqueo INT
, dataJson TEXT
, estado INT
, fechaCreacion DATETIME
, fechaActulizacion DATETIME
, fechaElimenacion DATETIME
)
;

-- sys.trace_xe_action_map
CREATE TABLE sys.trace_xe_action_map
(
  trace_column_id INT
, package_name VARCHAR(60)
, xe_action_name VARCHAR(60)
)
;

-- sys.trace_xe_event_map
CREATE TABLE sys.trace_xe_event_map
(
  trace_event_id INT
, package_name VARCHAR(60)
, xe_event_name VARCHAR(60)
)
;




[MySlq-Fedora-CobranzaWeb]
-- cobranza_web.com_cub_cobros_cuotas_cresa_tb
CREATE TABLE cobranza_web.com_cub_cobros_cuotas_cresa_tb
(
  empresa VARCHAR(5)
, desAgencia VARCHAR(60)
, documento VARCHAR(20)
, nomcliente VARCHAR(200)
, numCredito VARCHAR(20)
, numComprobante VARCHAR(30)
, interesMora DECIMAL(16, 6)
, gastoCobranza DECIMAL(16, 6)
, dfechavencimiento DATETIME
, monto DECIMAL(38, 6)
, fechacreacion DATETIME
, autorizacion VARCHAR(30)
, cuotaFin INT
, valorCapital DECIMAL(16, 6)
, valorInteres DECIMAL(16, 6)
, tipoPago VARCHAR(50)
, vertical VARCHAR(15)
, estadoPago VARCHAR(30)
, estado VARCHAR(30)
, tipoCartera VARCHAR(30)
, clase VARCHAR(30)
)
;


[MySlq-Fedora-dwh_cresa]
-- dwh_cresa.cobro_tipo_credito_tb
CREATE TABLE dwh_cresa.cobro_tipo_credito_tb
(
  tipoCredito VARCHAR(25)
, monto DECIMAL(19, 2)
, fechaCreacion VARCHAR(10)
)
;


[CRESA SQLSERVER DWH_CRESA]
-- cobranza.cub_cobro_cuotas
CREATE TABLE cobranza.cub_cobro_cuotas
(
  empresa VARCHAR(5)
, desAgencia VARCHAR(50)
, documento VARCHAR(15)
, nomcliente VARCHAR(50)
, numCredito VARCHAR(25)
, numComprobante VARCHAR(50)
, interesMora DECIMAL(19,2)
, gastoCobranza DECIMAL(19,2)
, dfechavencimiento DATETIME
, monto DECIMAL(19,2)
, fechacreacion VARCHAR(10)
, autorizacion BIGINT
, cuotaFin BIGINT
, valorCapital DECIMAL(19,2)
, valorInteres DECIMAL(19,2)
, emision_estado_cuenta DECIMAL(19,2)
, tipoPago VARCHAR(25)
, vertical VARCHAR(25)
, estadoPago INT
, estado TEXT
, tipoCartera INT
, clase INT
, cid_asiento VARCHAR(25)
)
;


[MS SQL Server - ICEUIODWH2 - dwh]
-- dbo.dw_cresa_verificaciones_credi_cresa
CREATE TABLE dbo.dw_cresa_verificaciones_credi_cresa
(
  numero_solicitud BIGINT
, codigo_cliente BIGINT
, tipo_cliente VARCHAR(10)
, identificacion VARCHAR(13)
, fecha_bitacora VARCHAR(27)
, estado_bitacora VARCHAR(20)
, fecha_creacion_verificacion VARCHAR(27)
, fecha_verificacion VARCHAR(27)
, fecha_actualizacion_verificacion VARCHAR(27)
, tipo_verificacion VARCHAR(100)
, descripcion VARCHAR(100)
, resolutivo VARCHAR(50)
, respuesta_verificacion TEXT
, comentario TEXT
, id_verificacion BIGINT
, anterior_verificacion_id BIGINT
)
;

-- dbo.dw_cresa_solicitudes_credi_cresa
CREATE TABLE dbo.dw_cresa_solicitudes_credi_cresa
(
  numero_solicitud BIGINT
, fecha_creacion DATETIME
, fecha_actualizacion DATETIME
, calificacion_buro VARCHAR(8)
, calificacion_confianza VARCHAR(8)
, calificacion_origina VARCHAR(8)
, calificacion_modelo VARCHAR(50)
, calificacion_siac VARCHAR(6)
, estado_solicitud VARCHAR(150)
, cuota DECIMAL(38,6)
, tipo_verificacion VARCHAR(100)
, estado_verificacion VARCHAR(100)
, biometria_estado VARCHAR(10)
, tienda_creacion VARCHAR(50)
, origen_credito VARCHAR(10)
, tienda_liberacion_id VARCHAR(50)
, tienda_liberacion VARCHAR(50)
, cedula_vendedor VARCHAR(35)
, vendedor VARCHAR(300)
, identificacion_emprendedor VARCHAR(13)
, nombre_emprededor VARCHAR(50)
, mina_telefono_1 VARCHAR(15)
, mina_telefono_2 VARCHAR(15)
, telefono_solicitud VARCHAR(10)
, mina_correo_1 VARCHAR(150)
, mina_correo_2 VARCHAR(150)
, correo_solicitud VARCHAR(300)
, codigo_cliente BIGINT
, cedula_cliente VARCHAR(13)
, tipo_cliente VARCHAR(10)
, tipo_cliente_credito VARCHAR(13)
, dependencia VARCHAR(50)
, nombre_cliente VARCHAR(403)
, fecha_nacimiento VARCHAR(10)
, nacionalidad INT
, sexo VARCHAR(50)
, estado_civil VARCHAR(50)
, nivel_educacion VARCHAR(50)
, profesion INT
, direccion VARCHAR(701)
, grupo VARCHAR(8)
, salario DECIMAL(18,2)
, edad_min INT
, edad_max INT
, capacidad_pago DECIMAL(5,2)
, entrada_base DECIMAL(5,2)
, unidad_negocio VARCHAR(12)
, ingreso INT
, aprobada INT
, liberado INT
, consumo INT
, cuota_maxima DECIMAL(16,2)
, cuota_utilizada DECIMAL(16,2)
, cuota_disponible DECIMAL(16,2)
, devuelta INT
, calificacion_graduada VARCHAR(50)
, sector_cliente VARCHAR(200)
)
;

