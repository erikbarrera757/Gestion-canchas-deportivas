<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // GET /notificaciones/?usuario_id=X — obtener notificaciones de un usuario
    case 'GET':
        $usuario_id = intval($_GET['usuario_id'] ?? 0);
        if (!$usuario_id) {
            http_response_code(400);
            echo json_encode(['error' => 'usuario_id requerido']);
            break;
        }
        $stmt = $pdo->prepare(
            "SELECT * FROM notificaciones
             WHERE usuario_destino_id = ?
             ORDER BY creado_en DESC
             LIMIT 50"
        );
        $stmt->execute([$usuario_id]);
        echo json_encode($stmt->fetchAll());
        break;

    // PUT /notificaciones/?id=X — marcar notificación como leída
    case 'PUT':
        $id = intval($_GET['id'] ?? 0);
        // Si id=0 y viene usuario_id, marcar TODAS como leídas
        $usuario_id = intval($_GET['usuario_id'] ?? 0);
        if ($id) {
            $pdo->prepare("UPDATE notificaciones SET leida=1 WHERE id=?")->execute([$id]);
        } elseif ($usuario_id) {
            $pdo->prepare("UPDATE notificaciones SET leida=1 WHERE usuario_destino_id=?")->execute([$usuario_id]);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'id o usuario_id requerido']);
            break;
        }
        echo json_encode(['success' => true]);
        break;

    // DELETE /notificaciones/?id=X — eliminar una notificación
    case 'DELETE':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) { http_response_code(400); echo json_encode(['error' => 'ID requerido']); break; }
        $pdo->prepare("DELETE FROM notificaciones WHERE id=?")->execute([$id]);
        echo json_encode(['success' => true]);
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido']);
}
