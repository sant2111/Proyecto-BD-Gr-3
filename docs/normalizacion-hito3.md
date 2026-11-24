# Hito 3 — Normalización de la biblioteca

## 1. Esquema antes
El modelo original tiene seis tablas de negocio: libro (ISBN, título, autor, categoría, año, ejemplares_disponibles); rol (id_rol, tipo_rol); usuario (id_usuario, id_rol, correo, contraseña, nombre, teléfono); lector (documento, nombres, apellidos, correo, teléfono); ejemplar (ISBN, id_ejemplar, tipo); préstamo (id_prestamo, documento, ISBN, id_ejemplar, fecha_prestamo, fecha_limite, fecha_devolucion, estado). Las FK conectan usuario con rol, ejemplar con libro y préstamo con lector y ejemplar. También existen rechazo_carga y tres tablas de paso: stg_linea, stg_libro y stg_lector.

## 2. Dependencias funcionales (DF) y claves candidatas
| Tabla | Claves candidatas | DF y regla de negocio |
|---|---|---|
| libro | ISBN | ISBN → demás atributos: identifica una edición del catálogo. |
| rol | id_rol; tipo_rol después del cambio | id_rol → tipo_rol; cada tipo de rol debe ser único. |
| usuario | id_usuario, correo | Cada identificador o correo único determina los demás datos de la cuenta. |
| lector | documento, correo | Cada documento o correo único identifica al lector y sus datos. |
| ejemplar | (ISBN, id_ejemplar) | La pareja identifica una copia y determina su tipo. El número de copia es local al libro. |
| prestamo | id_prestamo | Identifica lector, copia y fechas de la operación. El estado se deduce de las fechas y del día de consulta. |
| rechazo_carga | id | Identifica el evento de rechazo y sus detalles. |

Las DF se justifican por la regla de negocio y por las claves/UNIQUE del esquema; los datos solo sirven para refutar (consultas F1–F6 de `evidencia_df.sql`, resultados en `evidencias/08_dependencias.txt`). Se refutó (isbn, id_ejemplar) → documento en préstamo (F4: la copia 1 de *Cien años de soledad* pasó por dos lectores), por eso la clave de préstamo es id_prestamo. No se presupone autor → categoría ni una clave alternativa para préstamos sin una regla que la garantice. Las tablas de paso reciben datos crudos, incluso inválidos; no se les impone una clave candidata de negocio. Su contenido se procesa y no constituye el catálogo definitivo.

## 3. Formas normales y evidencias
| Tabla | Forma normal (antes) | Problema encontrado | Forma normal (después) |
|---|---|---|---|
| libro | FNBC en sus DF internas | `ejemplares_disponibles` es un dato derivado (copias menos préstamos abiertos) que ya estaba desfasado: E1 | FNBC, sin la columna |
| rol | FNBC | `tipo_rol` sin UNIQUE permitía roles duplicados | FNBC con `tipo_rol` UNIQUE |
| usuario | FNBC | Ninguno; comparte correo/teléfono con lector pero no se prueba que sea la misma persona (E3) | FNBC |
| lector | FNBC | Ninguno | FNBC |
| ejemplar | FNBC | Ninguno (F2); faltaban 80 copias que el stock decía tener (E1c) | FNBC |
| prestamo | FNBC | `estado` es derivado de fechas y del día de consulta (E2); faltaba impedir dos préstamos abiertos sobre una copia (E4) | FNBC, sin `estado` |
| rechazo_carga | FNBC | Ninguno | FNBC |

Para una fecha de referencia fija, (fecha_limite, fecha_devolucion) determina estado, por lo que no debe persistirse. La repetición de categorías como texto no prueba una violación de 3FN (E5c). Las tablas de paso (stg_*) quedan fuera del análisis por ser auxiliares de ETL.

| Consulta en evidencia.sql | Resultado antes |
|---|---|
| E1a–c: stock guardado frente a copias menos préstamos abiertos | 32/32 libros descuadrados; 24 con stock y sin copias. Cien años de soledad: 4 guardados frente a 2 calculados. |
| E2a–b: CASE sobre fechas, hoy y CURRENT_DATE + 30 | 0 diferencias hoy; préstamos 9 y 12 cambiarían a en mora en 30 días sin actualización. |
| E3a–b: INTERSECT de columnas y catálogo de FK | Correo y teléfono comunes; sin FK entre lector y usuario. No prueba que sean la misma persona. |
| E4a–b: restricciones y GROUP BY de préstamos abiertos HAVING count(*) > 1 | Sin índice único parcial; 0 duplicados abiertos. |
| E5a–c: GROUP BY autor, tipo y categoría | 0 autores con varias categorías en la muestra; 14 copias físicas; 9 categorías. |

## 4. Cambios y migración
normalizacion.sql ejecutó BEGIN, bloqueó las tablas, copió datos a tablas temporales, generó 80 copias faltantes y verificó los registros originales con EXCEPT antes de eliminar las columnas derivadas. Se interpretó el stock semilla como total de copias físicas (supuesto de migración). Se eligió «total» y no «disponibles» porque el valor guardado era inconsistente con la otra lectura: *Cien años de soledad* tenía 3 copias y 1 préstamo abierto pero stock 4, de modo que «disponibles» implicaría 5 copias y «total» implica 4, la lectura que genera menos copias inventadas; las 80 copias generadas se marcan como tipo 'Físico' y pueden corregirse si el grupo conoce el inventario real. Se agregó unicidad de tipo_rol, control de fechas e índice único parcial para impedir dos préstamos abiertos sobre una copia. Las cuatro verificaciones de pérdida, modificación o stock no reconciliado dieron 0; terminó con COMMIT.

| Tabla | Antes | Después | Base nueva con pruebas |
|---|---:|---:|---:|
| libro | 32 | 32 | 32 |
| lector | 20 | 20 | 20 |
| ejemplar | 14 | 94 | 94 |
| prestamo | 15 | 15 | 15 |

Se actualizó 01_esquema.sql y se ejecutó en biblioteca_hito3_prueba, creada aparte. Las cargas aceptaron 20 lectores y 32 libros sin rechazos, generaron 94 copias y los datos de prueba insertaron 15 préstamos sin borrar el inventario. Los cuatro reportes devolvieron 4 libros (empate incluido), 2 lectores más activos, 3 morosos y 4 préstamos vencidos. La comparación antes y después confirmó que los cuatro reportes conservaron su contenido.

## 5. Decisiones de desnormalización
**Decisión: no se desnormaliza nada.** Los dos datos derivados que existían se calculan en vistas y no se guardan. No se midió rendimiento porque no hay una consulta lenta que justifique guardar una copia (con 94 copias y 15 préstamos, no la habría), y sin copia guardada no hay nada que pueda desincronizarse ni triggers que mantener.

| Dato | Decisión | Cómo se obtiene | Consulta de verificación y resultado |
|---|---|---|---|
| Disponibilidad por libro (antes `libro.ejemplares_disponibles`) | Se calcula | Vista `libro_disponibilidad`: copias menos préstamos abiertos | `SELECT sum(ejemplares), sum(prestados), sum(disponibles), count(*) FILTER (WHERE disponibles<0) FROM biblioteca.libro_disponibilidad;` → 94, 6, 88 y 0 |
| Estado del préstamo (antes `prestamo.estado`) | Se calcula | Vista `prestamo_con_estado`: `CASE` sobre las fechas y `CURRENT_DATE` | `SELECT estado, count(*) FROM biblioteca.prestamo_con_estado GROUP BY estado;` → 2 activos, 9 devueltos, 4 en mora |

Reglas que mantienen la integridad sin copias guardadas: el índice único parcial `prestamo_abierto_uk` permite como máximo un préstamo abierto por copia, y el `CHECK` `prestamo_fechas_ck` impide fechas incoherentes.

Dos casos que parecen redundancia y no lo son:
- **`fecha_limite`** se conserva: es un dato histórico del plazo pactado en cada préstamo, y la biblioteca puede cambiar el plazo de 14 días o dar plazos especiales (S20, A5). Su determinante es el préstamo, no el estado actual del catálogo, así que es correcto en 3FN.
- **`lector` y `usuario`** se mantienen separados: comparten correo y teléfono (E3), pero no hay una regla de negocio que diga que son la misma persona.

## 6. Esquema después
- **Tablas de negocio (6):** libro, rol, usuario, lector, ejemplar y prestamo, con las mismas FK de antes.
- **Columnas eliminadas:** `libro.ejemplares_disponibles` y `prestamo.estado`.
- **Restricciones nuevas:** `rol.tipo_rol` UNIQUE, `prestamo_fechas_ck` e índice único parcial `prestamo_abierto_uk`.
- **Vistas nuevas:** `libro_disponibilidad` y `prestamo_con_estado`.
- **Forma normal:** las seis tablas de negocio y rechazo_carga quedan en FNBC bajo las DF identificadas; ninguna queda solo en 3FN. Las tablas de paso (stg_linea, stg_libro, stg_lector) son auxiliares del proceso de carga y quedan fuera del análisis.
- **Evidencia:** salidas reales en la carpeta `evidencias/` (`.txt`).

### Comparación antes y después de la normalización

Se restauró el respaldo original en una base independiente y se ejecutaron los cuatro reportes del Hito 2 (salidas en `evidencias/06_reportes_antes.txt` y `evidencias/07_reportes_despues.txt`).

| Reporte | Antes | Después |
|---|---:|---:|
| Libros más prestados | 4 | 4 |
| Lectores que más han leído | 2 | 2 |
| Lectores morosos | 3 | 3 |
| Préstamos vencidos | 4 | 4 |

Los cuatro reportes conservaron el mismo contenido. La única diferencia fue el orden de presentación de dos lectores empatados, lo cual no afecta los resultados.
