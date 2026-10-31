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

SELECT p1.nombre, p1.categoria, p1.precio
FROM producto p1
WHERE p1.precio > (
    SELECT AVG(p2.precio)
    FROM producto p2
    WHERE p2.categoria = p1.categoria
);

--Punto 8

SELECT c.nombre, c.ciudad
FROM cliente c
WHERE c.ciudad = 'Cali' 
  AND EXISTS (
      SELECT 1
      FROM pedido ped
      JOIN detalle det ON ped.id_pedido = det.id_pedido
      JOIN producto prod ON det.id_producto = prod.id_producto
      WHERE ped.id_cliente = c.id_cliente
        AND prod.categoria = 'Accesorio'
        AND ped.estado != 'cancelado'
  );

--Punto 9

SELECT c1.nombre
FROM cliente c1
WHERE NOT EXISTS (
    SELECT 1 
    FROM cliente c2 
    WHERE c2.referido_por = c1.id_cliente
);

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



