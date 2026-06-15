<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // GET /canchas/ — listar todas las canchas
    case 'GET':
        $sql = "SELECT c.*, 
                       r.fecha AS reserva_fecha, 
                       r.horario AS reserva_horario,
                       u.nombre AS reserva_cliente
                FROM canchas c
                LEFT JOIN (
                    SELECT r1.*
                    FROM reservas r1
                    INNER JOIN (
                        SELECT cancha_id, MAX(id) as max_id
                        FROM reservas
                        WHERE estado = 'Confirmada'
                        GROUP BY cancha_id
                    ) r2 ON r1.id = r2.max_id
                ) r ON c.id = r.cancha_id
                LEFT JOIN usuarios u ON r.usuario_id = u.id
                ORDER BY c.id ASC";
        $stmt = $pdo->query($sql);
        echo json_encode($stmt->fetchAll());
        break;

    // POST /canchas/ — registrar cancha
    case 'POST':
        $d = json_decode(file_get_contents('php://input'), true);
        if (empty($d['nombre']) || empty($d['tipo'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Nombre y tipo son requeridos']);
            break;
        }
        // Verificar duplicado
        $check = $pdo->prepare("SELECT id FROM canchas WHERE LOWER(nombre)=LOWER(?)");
        $check->execute([$d['nombre']]);
        if ($check->fetch()) {
            http_response_code(409);
            echo json_encode(['error' => 'Ya existe una cancha con ese nombre']);
            break;
        }
        $stmt = $pdo->prepare(
            "INSERT INTO canchas (nombre, tipo, precio, estado) VALUES (?, ?, ?, 'Disponible')"
        );
        $stmt->execute([$d['nombre'], $d['tipo'], $d['precio'] ?? 0]);
        $id = $pdo->lastInsertId();
        $cancha = $pdo->query("SELECT * FROM canchas WHERE id=$id")->fetch();
        http_response_code(201);
        echo json_encode($cancha);
        break;

    // PUT /canchas/?id=X — actualizar cancha
    case 'PUT':
        $id = intval($_GET['id'] ?? 0);
        $d  = json_decode(file_get_contents('php://input'), true);
        if (!$id) { http_response_code(400); echo json_encode(['error'=>'ID requerido']); break; }

        // Validar conflicto de estado: no poner Mantenimiento si está Ocupada
        if (!empty($d['estado'])) {
            $cur = $pdo->query("SELECT estado FROM canchas WHERE id=$id")->fetch();
            // Validar que no se marque como Disponible si hay tickets de mantenimiento activos (sin completar)
            if ($d['estado'] === 'Disponible') {
                $tix = $pdo->prepare("SELECT COUNT(*) as c FROM tickets_mantenimiento WHERE cancha_id=? AND estado!='Completada'");
                $tix->execute([$id]);
                if ($tix->fetch()['c'] > 0) {
                    http_response_code(409);
                    echo json_encode(['error' => 'No se puede marcar la cancha como Disponible porque tiene tareas de mantenimiento activas pendientes.']);
                    break;
                }
            }
            // Validar que no se marque como Ocupada si la cancha está en Mantenimiento o tiene tickets activos
            if ($d['estado'] === 'Ocupada') {
                if ($cur && $cur['estado'] === 'Mantenimiento') {
                    http_response_code(409);
                    echo json_encode(['error' => 'No se puede poner en Ocupada una cancha que está en Mantenimiento. Complete las tareas primero.']);
                    break;
                }
                $tix = $pdo->prepare("SELECT COUNT(*) as c FROM tickets_mantenimiento WHERE cancha_id=? AND estado!='Completada'");
                $tix->execute([$id]);
                if ($tix->fetch()['c'] > 0) {
                    http_response_code(409);
                    echo json_encode(['error' => 'No se puede marcar la cancha como Ocupada porque tiene tareas de mantenimiento activas pendientes.']);
                    break;
                }
            }
            // Validar que no se marque como Mantenimiento si la cancha está Ocupada
            if ($d['estado'] === 'Mantenimiento') {
                if ($cur && $cur['estado'] === 'Ocupada') {
                    http_response_code(409);
                    echo json_encode(['error' => 'No se puede poner la cancha en Mantenimiento porque actualmente está Ocupada en juego.']);
                    break;
                }
            }
        }

        $fields = [];
        $vals   = [];
        foreach (['nombre','tipo','precio','estado'] as $f) {
            if (isset($d[$f])) { $fields[] = "$f=?"; $vals[] = $d[$f]; }
        }
        if (empty($fields)) { http_response_code(400); echo json_encode(['error'=>'Sin datos']); break; }
        $vals[] = $id;
        $pdo->prepare("UPDATE canchas SET ".implode(',',$fields)." WHERE id=?")->execute($vals);
        $cancha = $pdo->query("SELECT * FROM canchas WHERE id=$id")->fetch();
        echo json_encode($cancha);
        break;

    // DELETE /canchas/?id=X — eliminar cancha
    case 'DELETE':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) { http_response_code(400); echo json_encode(['error'=>'ID requerido']); break; }
        $cancha = $pdo->query("SELECT * FROM canchas WHERE id=$id")->fetch();
        if (!$cancha) { http_response_code(404); echo json_encode(['error'=>'No encontrada']); break; }
        // No eliminar si está en uso o mantenimiento
        if (in_array($cancha['estado'], ['Ocupada','Mantenimiento'])) {
            http_response_code(409);
            echo json_encode(['error' => 'No se puede eliminar una cancha Ocupada o en Mantenimiento']);
            break;
        }
        // Verificar reservas activas
        $resv = $pdo->prepare("SELECT COUNT(*) as c FROM reservas WHERE cancha_id=? AND estado='Confirmada'");
        $resv->execute([$id]);
        if ($resv->fetch()['c'] > 0) {
            http_response_code(409);
            echo json_encode(['error' => 'La cancha tiene reservas activas pendientes']);
            break;
        }
        try {
            $pdo->prepare("DELETE FROM canchas WHERE id=?")->execute([$id]);
            echo json_encode(['success' => true, 'message' => 'Cancha eliminada']);
        } catch (PDOException $e) {
            http_response_code(409);
            echo json_encode(['error' => 'No se puede eliminar esta cancha porque contiene historial de reservas o reportes de mantenimiento asociados.']);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido']);
}
