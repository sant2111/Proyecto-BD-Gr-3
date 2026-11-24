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

No se presupone autor → categoría ni una clave alternativa para préstamos sin una regla que la garantice. Las tablas de paso reciben datos crudos, incluso inválidos; no se les impone una clave candidata de negocio. Su contenido se procesa y no constituye el catálogo definitivo.

## 3. Formas normales y evidencias
Libro, rol, usuario, lector, ejemplar y rechazo_carga cumplen FNBC respecto de las DF de negocio identificadas, salvo la redundancia derivada analizada en préstamo: para una fecha de referencia fija, (fecha_limite, fecha_devolucion) determina estado, por lo que este no debe persistirse. Libro cumple las DF internas indicadas, pero su disponibilidad duplica información de otras tablas. La repetición de categorías no prueba una violación de 3FN. Las tablas de paso quedan fuera de la normalización del modelo de negocio por su propósito ETL.

| Consulta en evidencia.sql | Resultado antes |
|---|---|
| E1a–c: stock guardado frente a copias menos préstamos abiertos | 32/32 libros descuadrados; 24 con stock y sin copias. Cien años de soledad: 4 guardados frente a 2 calculados. |
| E2a–b: CASE sobre fechas, hoy y CURRENT_DATE + 30 | 0 diferencias hoy; préstamos 9 y 12 cambiarían a en mora en 30 días sin actualización. |
| E3a–b: INTERSECT de columnas y catálogo de FK | Correo y teléfono comunes; sin FK entre lector y usuario. No prueba que sean la misma persona. |
| E4a–b: restricciones y GROUP BY de préstamos abiertos HAVING count(*) > 1 | Sin índice único parcial; 0 duplicados abiertos. |
| E5a–c: GROUP BY autor, tipo y categoría | 0 autores con varias categorías en la muestra; 14 copias físicas; 9 categorías. |

## 4. Cambios y migración
normalizacion.sql ejecutó BEGIN, bloqueó las tablas, copió datos a tablas temporales, generó 80 copias faltantes y verificó los registros originales con EXCEPT antes de eliminar las columnas derivadas. Se interpretó el stock semilla como total de copias físicas (supuesto de migración). Se agregó unicidad de tipo_rol, control de fechas e índice único parcial para impedir dos préstamos abiertos sobre una copia. Las cuatro verificaciones de pérdida, modificación o stock no reconciliado dieron 0; terminó con COMMIT.

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
Se conservan las seis tablas de negocio y sus FK, eliminando ejemplares_disponibles de libro y estado de prestamo; rol incorpora tipo_rol UNIQUE. Se agregan las dos vistas y las restricciones descritas. Las seis tablas y rechazo_carga quedan en FNBC bajo las DF identificadas; no se identificó una tabla de negocio que quede solamente en 3FN. Las tablas de paso permanecen como estructuras auxiliares. La evidencia de ejecución se adjunta en la carpeta evidencias; los extractos visuales se identifican como reconstrucciones de la salida compartida.

### Comparación antes y después de la normalización

Se restauró el respaldo original en una base independiente y se ejecutaron los cuatro reportes del Hito 2.

| Reporte | Antes | Después |
|---|---:|---:|
| Libros más prestados | 4 | 4 |
| Lectores que más han leído | 2 | 2 |
| Lectores morosos | 3 | 3 |
| Préstamos vencidos | 4 | 4 |

Los cuatro reportes conservaron el mismo contenido. La única diferencia fue el orden de presentación de dos lectores empatados, lo cual no afecta los resultados.
