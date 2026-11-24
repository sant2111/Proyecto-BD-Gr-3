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
| ejemplar | FNBC | Ninguno (F2); diferencia de 80 copias bajo el supuesto de inventario total (E1c) | FNBC |
| prestamo | 2FN (con fecha de referencia fija) | `estado` es derivado de fechas y del día de consulta (E2); faltaba impedir dos préstamos abiertos sobre una copia (E4) | FNBC, sin `estado` |
| rechazo_carga | FNBC | Ninguno | FNBC |

Para una fecha de referencia fija, (fecha_limite, fecha_devolucion) determina estado. Como el determinante no es una superclave y estado no es un atributo primo, bajo esta interpretación se incumplen 3FN y FNBC. Además, el estado cambia con el tiempo, por lo que se calcula mediante una vista. La repetición de categorías como texto no prueba una violación de 3FN (E5c). Las tablas de paso (stg_*) quedan fuera del análisis por ser auxiliares de ETL.

| Consulta en evidencia.sql | Resultado antes |
|---|---|
| E1a–c: stock guardado frente a copias menos préstamos abiertos | 32/32 libros descuadrados; 24 con stock y sin copias. Cien años de soledad: 4 guardados frente a 2 calculados. |
| E2a–b: CASE sobre fechas, hoy y CURRENT_DATE + 30 | 0 diferencias hoy; préstamos 9 y 12 cambiarían a en mora en 30 días sin actualización. |
| E3a–b: INTERSECT de columnas y catálogo de FK | Correo y teléfono comunes; sin FK entre lector y usuario. No prueba que sean la misma persona. |
| E4a–b: restricciones y GROUP BY de préstamos abiertos HAVING count(*) > 1 | Sin índice único parcial; 0 duplicados abiertos. |
| E5a–c: GROUP BY autor, tipo y categoría | 0 autores con varias categorías en la muestra; 14 copias físicas; 9 categorías. |

## 4. Cambios y migración
normalizacion.sql ejecutó BEGIN, bloqueó las tablas, copió los datos a temporales y generó 80 ejemplares de prueba. Se interpretó el stock semilla como inventario total: 94 unidades frente a 14 copias registradas. Para Cien años de soledad, 3 copias y 1 préstamo abierto frente a stock 4 implicarían 5 copias si el stock fuera disponible, o 4 si fuera total. Se eligió la segunda lectura para minimizar los registros generados. Las 80 copias se marcaron como Físico; no son copias verificadas y en producción requieren validación del inventario. Se verificaron los registros originales con EXCEPT antes de eliminar los derivados, se añadieron unicidad de rol, control de fechas e índice único parcial. Las cuatro verificaciones dieron 0 y se ejecutó COMMIT.

| Tabla | Antes | Después | Base nueva con pruebas |
|---|---:|---:|---:|
| libro | 32 | 32 | 32 |
| lector | 20 | 20 | 20 |
| ejemplar | 14 | 94 | 94 |
| prestamo | 15 | 15 | 15 |

Se actualizó 01_esquema.sql y se ejecutó en biblioteca_hito3_prueba, creada aparte. Las cargas aceptaron 20 lectores y 32 libros sin rechazos, generaron 94 copias y los datos de prueba insertaron 15 préstamos sin borrar el inventario. Los cuatro reportes devolvieron 4 libros (empate incluido), 2 lectores más activos, 3 morosos y 4 préstamos vencidos. La comparación antes y después confirmó que los cuatro reportes conservaron su contenido.

## 5. Decisiones de desnormalización
No se conservan derivados redundantes en las tablas de negocio. libro_disponibilidad calcula copias totales menos préstamos abiertos; prestamo_con_estado calcula devuelto, en mora o activo con CASE y CURRENT_DATE. El índice parcial garantiza como máximo un préstamo abierto por copia. La verificación `SELECT sum(ejemplares),sum(prestados),sum(disponibles),count(*) FILTER (WHERE disponibles<0) FROM biblioteca.libro_disponibilidad;` devolvió 94, 6, 88 y 0. `SELECT estado,count(*) FROM biblioteca.prestamo_con_estado GROUP BY estado;` devolvió 2 activos, 9 devueltos y 4 en mora en la migración. No se requieren triggers para estos derivados. Se conserva fecha_limite como dato histórico del plazo pactado, pues puede haber cambios o excepciones al plazo de 14 días. Se mantienen lector y usuario separados porque no se ha establecido una regla de identidad común.

## 6. Esquema después
Se conservan las seis tablas de negocio y sus FK, eliminando ejemplares_disponibles de libro y estado de prestamo; rol incorpora tipo_rol UNIQUE. Se agregan las dos vistas y las restricciones descritas. Las seis tablas y rechazo_carga quedan en FNBC bajo las DF identificadas; no se identificó una tabla de negocio que quede solamente en 3FN. Las tablas de paso permanecen como estructuras auxiliares. La evidencia de ejecución está en la carpeta evidencias (salidas `.txt` reales).

### Comparación antes y después de la normalización

Se restauró el respaldo original en una base independiente y se ejecutaron los cuatro reportes del Hito 2 (salidas en `evidencias/06_reportes_antes.txt` y `evidencias/07_reportes_despues.txt`).

| Reporte | Antes | Después |
|---|---:|---:|
| Libros más prestados | 4 | 4 |
| Lectores que más han leído | 2 | 2 |
| Lectores morosos | 3 | 3 |
| Préstamos vencidos | 4 | 4 |

Los cuatro reportes conservaron el mismo contenido. Las salidas guardadas en las evidencias 06 y 07 coinciden exactamente.
