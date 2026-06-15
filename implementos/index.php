<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        $stmt = $pdo->query("SELECT * FROM implementos WHERE activo=1 ORDER BY nombre ASC");
        echo json_encode($stmt->fetchAll());
        break;

    case 'POST': // procesar transacción
        $d              = json_decode(file_get_contents('php://input'), true);
        $implemento_id  = intval($d['implemento_id'] ?? 0);
        $usuario_id     = intval($d['usuario_id']    ?? 0);
        $tipo           = $d['tipo'] ?? ''; // 'Alquiler' o 'Venta'

        if (!$implemento_id || !$usuario_id || !in_array($tipo, ['Alquiler','Venta'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Datos incompletos']);
            break;
        }

        $impl = $pdo->query("SELECT * FROM implementos WHERE id=$implemento_id FOR UPDATE")->fetch();
        if (!$impl || $impl['stock'] < 1) {
            http_response_code(409);
            echo json_encode(['error' => 'Implemento no disponible']);
            break;
        }

        $monto = $tipo === 'Alquiler' ? $impl['precio_alquiler'] : $impl['precio_venta'];

        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare(
                "INSERT INTO transacciones_implementos (implemento_id, usuario_id, tipo, monto)
                 VALUES (?, ?, ?, ?)"
            );
            $stmt->execute([$implemento_id, $usuario_id, $tipo, $monto]);

            // Solo descontar stock en venta definitiva
            if ($tipo === 'Venta') {
                $pdo->prepare("UPDATE implementos SET stock = stock - 1 WHERE id=?")->execute([$implemento_id]);
            }
            $pdo->commit();
            echo json_encode(['success' => true, 'monto' => $monto, 'tipo' => $tipo]);
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
