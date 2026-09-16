-- monto: numerico segun metadatos; codigo: alfanumerico segun metadatos.
-- Aplicar defaults solo cuando falte tipo en el diccionario.
SET ANSI_MODE = TRUE;
WITH entrada(monto, codigo) AS (
  VALUES ('123.45', '00123'), (NULL, NULL)
)
SELECT CAST(monto AS DECIMAL(10,2)) AS monto,
       CAST(codigo AS STRING) AS codigo
FROM entrada;
