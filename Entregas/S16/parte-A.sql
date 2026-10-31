--Punto 1

SET search_path TO tienda;

SELECT
    p.id_Pedido,
    c.nombre AS nombre_cliente,
    pr.nombre AS nombre_producto,
    d.cantidad,
    (d.cantidad * d.precio_unitario) AS Subtotal
FROM pedido p
         JOIN cliente c   ON p.id_cliente = c.id_cliente
         JOIN detalle d   ON p.id_pedido = d.id_pedido
         JOIN producto pr ON d.id_producto = pr.id_producto
WHERE p.id_pedido = 1003;

--Punto 2

--Punto 3

--Punto 4

--Punto 5

--Punto 6

--Punto 7

--Punto 8

--Punto 9

--Punto 10

WITH gasto_clientes AS (
    SELECT 
        c.id_cliente,
        c.nombre,
        SUM(d.cantidad * d.precio_unitario) AS total_gastado
    FROM cliente c
    JOIN pedido p ON c.id_cliente = p.id_cliente
    JOIN detalle d ON p.id_pedido = d.id_pedido
    WHERE p.estado != 'cancelado'
    GROUP BY c.id_cliente, c.nombre
)
SELECT nombre, total_gastado
FROM gasto_clientes
WHERE total_gastado = (SELECT MAX(total_gastado) FROM gasto_clientes);

--Punto 11

SELECT c.id_cliente, c.nombre
FROM cliente c
WHERE NOT EXISTS (
    SELECT pr.id_producto
    FROM producto pr
    WHERE pr.categoria = 'Grano'
      AND NOT EXISTS (
          SELECT 1
          FROM pedido p
          JOIN detalle d ON p.id_pedido = d.id_pedido
          WHERE p.id_cliente = c.id_cliente
            AND d.id_producto = pr.id_producto
            AND p.estado != 'cancelado'
      )
);

