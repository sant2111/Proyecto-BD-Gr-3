# Verificación Hito 2 — Parte B

## Entorno de prueba

Se usó la base de datos aislada `curso_qa`, preparada con el esquema de `postgres/init/01_esquema.sql`.

- Libros cargados: 32
- Lectores cargados: 20
- Ejemplares de prueba insertados: 14
- Préstamos de prueba insertados: 15
- Regla de mora: un préstamo está en mora si `fecha_devolucion IS NULL` y `fecha_limite < CURRENT_DATE`. Un préstamo que vence hoy queda excluido.

## Resultados de los reportes

### Reporte 1: libros más prestados

| ISBN | Título | Préstamos |
|---|---|---:|
| 9780000000001 | Cien años de soledad | 4 |
| 9780000000004 | Rayuela | 3 |
| 9780000000007 | Ficciones | 2 |
| 9780000000005 | Pedro Páramo | 2 |


### Reporte 2: lectores que más libros han leído

| Documento | Lector | Libros leídos |
|---|---|---:|
| 1000000002 | Santiago | 3 |
| 1000000001 | Mariana | 3 |


### Reporte 3: lectores morosos

| Documento | Lector |
|---|---|
| 1000000005 | Camila Hernández Torres |
| 1000000003 | Valentina López Díaz |
| 1000000004 | Juan David Martínez Ruiz |


### Reporte 4: préstamos en mora

| Lector | Correo | Teléfono | Libro | Fecha límite | Días de mora |
|---|---|---|---|---|---:|
| Juan David Martínez Ruiz | juan.martinez@correo-ejemplo.edu.co | 3001000004 | Ficciones | 2026-10-06 | 26 |
| Valentina López Díaz | valentina.lopez@correo-ejemplo.edu.co | 3001000003 | La sombra del viento | 2026-10-16 | 16 |
| Juan David Martínez Ruiz | juan.martinez@correo-ejemplo.edu.co | 3001000004 | Cien años de soledad | 2026-10-26 | 6 |
| Camila Hernández Torres | camila.hernandez@correo-ejemplo.edu.co | 3001000005 | Pedro Páramo | 2026-10-30 | 2 |


## Tabla de verificación de los ocho casos

| # | Caso | Resultado esperado | Resultado obtenido | ¿Coincidió? |
|---|---|---|---|---|
| 1 | Libro sin préstamos | Aparece con 0 o se documenta el alcance del reporte | No aparece en el top 3. Se documenta que el reporte presenta los tres primeros puestos y sus empates | Sí, con el alcance del top 3 documentado |
| 2 | Empate en el podio de libros | Aparecen ambos libros empatados | Ficciones y Pedro Páramo aparecen con 2 préstamos cada uno | Sí |
| 3 | Empate de lectores que más leen | Aparecen todos los lectores empatados | Santiago y Mariana aparecen con 3 libros leídos cada uno | Sí |
| 4 | Lector con préstamos abiertos y ninguno devuelto | No aparece como ganador | Juan David no aparece entre los ganadores del Reporte 2 | Sí |
| 5 | Préstamo devuelto tarde | No cuenta como mora | El préstamo devuelto tarde no aparece en los reportes 3 ni 4 | Sí |
| 6 | Préstamo que vence hoy | Se excluye usando `< CURRENT_DATE` | El préstamo que vence hoy se excluye; Juan David aparece por otros préstamos vencidos | Sí |
| 7 | Lector con dos préstamos en mora | Una fila en el Reporte 3 y dos en el Reporte 4 | Juan David aparece una vez en el Reporte 3 y dos veces en el Reporte 4 | Sí |
| 8 | Lector sin préstamos | No afecta los reportes ni aparece donde no corresponde | Los lectores sin préstamos no aparecen en los resultados observados | Sí |

## Evidencia de ejecución

La carga de datos de prueba terminó con:

```text
INSERT 0 14
INSERT 0 15
```

Los cuatro reportes devolvieron resultados. Sin embargo, la ejecución del archivo `reportes.sql` terminó con un error después del Reporte 4:

```text
ERROR: syntax error at or near "ORDER"
LINE 1: ORDER BY dias_mora DESC;
```

La copia revisada de `reportes.sql` tiene un `ORDER BY dias_mora DESC;` duplicado al final y también incluye instrucciones de carga de datos que pertenecen a `datos-prueba.sql`. Por eso, aunque los reportes dieron resultados, falta limpiar el archivo y repetir la ejecución para confirmar que termine sin errores.