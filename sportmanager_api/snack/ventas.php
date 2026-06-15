<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET': // listar ventas del día
        $stmt = $pdo->query(
            "SELECT v.*, p.nombre AS producto_nombre, u.nombre AS vendedor_nombre
             FROM ventas_snack v
             JOIN productos_snack p ON v.producto_id = p.id
             JOIN usuarios u ON v.usuario_id = u.id
             ORDER BY v.creado_en DESC"
        );
        echo json_encode($stmt->fetchAll());
        break;

    case 'POST': // registrar venta y descontar stock
        $d          = json_decode(file_get_contents('php://input'), true);
        $items      = $d['items']      ?? [];   // [{producto_id, cantidad}]
        $usuario_id = intval($d['usuario_id'] ?? 0);

        if (empty($items) || !$usuario_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Items y usuario_id son requeridos']);
            break;
        }

        $insertados = [];
        $pdo->beginTransaction();
        try {
            foreach ($items as $item) {
                $pid      = intval($item['producto_id']);
                $cantidad = intval($item['cantidad'] ?? 1);

                // Verificar stock
                $prod = $pdo->query("SELECT * FROM productos_snack WHERE id=$pid FOR UPDATE")->fetch();
                if (!$prod || $prod['stock'] < $cantidad) {
                    $pdo->rollBack();
                    http_response_code(409);
                    echo json_encode(['error' => "Sin stock suficiente para: {$prod['nombre']}"]);
                    exit;
                }

                $total = $prod['precio'] * $cantidad;
                // Registrar venta
                $stmt = $pdo->prepare(
                    "INSERT INTO ventas_snack (producto_id, usuario_id, cantidad, total)
                     VALUES (?, ?, ?, ?)"
                );
                $stmt->execute([$pid, $usuario_id, $cantidad, $total]);
                $insertados[] = $pdo->lastInsertId();

                // Descontar stock
                $pdo->prepare(
                    "UPDATE productos_snack SET stock = stock - ? WHERE id=?"
                )->execute([$cantidad, $pid]);
            }
            $pdo->commit();
            echo json_encode(['success' => true, 'venta_ids' => $insertados]);
        } catch (Exception $e) {
            $pdo->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido']);
}
