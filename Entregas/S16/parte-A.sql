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

SELECT
    c.nombre AS cliente,
    r.nombre AS recomendado_por
FROM cliente c
         LEFT JOIN cliente r ON c.referido_por = r.id_cliente;

--Punto 3

SELECT
    p.nombre AS producto
FROM producto p
         LEFT JOIN detalle d ON p.id_producto = d.id_producto
WHERE d.id_producto IS NULL;

--Punto 4

SELECT
    c.nombre,
    COUNT(p.id_pedido) AS total_pedidos
FROM cliente c
         LEFT JOIN pedido p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre
ORDER BY total_pedidos DESC;

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



