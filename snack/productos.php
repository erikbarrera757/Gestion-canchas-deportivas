<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        $stmt = $pdo->query(
            "SELECT * FROM productos_snack WHERE activo=1 ORDER BY nombre ASC"
        );
        echo json_encode($stmt->fetchAll());
        break;

    case 'POST': // agregar producto
        $d = json_decode(file_get_contents('php://input'), true);
        if (empty($d['nombre']) || !isset($d['precio'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Nombre y precio son requeridos']);
            break;
        }
        $stmt = $pdo->prepare(
            "INSERT INTO productos_snack (nombre, precio, stock) VALUES (?, ?, ?)"
        );
        $stmt->execute([$d['nombre'], $d['precio'], $d['stock'] ?? 0]);
        $id = $pdo->lastInsertId();
        echo json_encode($pdo->query("SELECT * FROM productos_snack WHERE id=$id")->fetch());
        break;

    case 'PUT': // actualizar stock o datos
        $id = intval($_GET['id'] ?? 0);
        $d  = json_decode(file_get_contents('php://input'), true);
        if (!$id) { http_response_code(400); echo json_encode(['error'=>'ID requerido']); break; }
        $fields = []; $vals = [];
        foreach (['nombre','precio','stock'] as $f) {
            if (isset($d[$f])) { $fields[] = "$f=?"; $vals[] = $d[$f]; }
        }
        $vals[] = $id;
        $pdo->prepare("UPDATE productos_snack SET ".implode(',',$fields)." WHERE id=?")->execute($vals);
        echo json_encode($pdo->query("SELECT * FROM productos_snack WHERE id=$id")->fetch());
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido']);
}
