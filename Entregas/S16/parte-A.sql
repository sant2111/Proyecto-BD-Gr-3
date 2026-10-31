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

--Punto 11