<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // GET /reservas/ — listar reservas (con nombre de cancha y usuario)
    case 'GET':
        $sql = "SELECT r.*, c.nombre AS cancha_nombre, c.tipo AS cancha_tipo,
                       u.nombre AS cliente_nombre
                FROM reservas r
                JOIN canchas c ON r.cancha_id = c.id
                JOIN usuarios u ON r.usuario_id = u.id
                ORDER BY r.fecha DESC, r.id DESC";
        $stmt = $pdo->query($sql);
        echo json_encode($stmt->fetchAll());
        break;

    // POST /reservas/ — crear reserva
    case 'POST':
        $d = json_decode(file_get_contents('php://input'), true);
        $cancha_id   = intval($d['cancha_id']   ?? 0);
        $usuario_id  = intval($d['usuario_id']  ?? 0);
        $horario     = trim($d['horario']        ?? '');
        $fecha       = trim($d['fecha']          ?? date('Y-m-d'));

        if (!$cancha_id || !$usuario_id || empty($horario)) {
            http_response_code(400);
            echo json_encode(['error' => 'Cancha, usuario y horario son requeridos']);
            break;
        }

        // Validar que la reserva no sea en una fecha/hora pasada
        $start_time = '00:00';
        if (preg_match('/^(\d{2}:\d{2})/', $horario, $matches)) {
            $start_time = $matches[1];
        }
        $resv_datetime = strtotime("$fecha $start_time");
        if ($resv_datetime === false || $resv_datetime < (time() - 300)) {
            http_response_code(400);
            echo json_encode(['error' => 'No se puede crear una reserva en una fecha o hora del pasado.']);
            break;
        }

        // Verificar disponibilidad de la cancha
        $cancha = $pdo->query("SELECT * FROM canchas WHERE id=$cancha_id")->fetch();
        if (!$cancha || $cancha['estado'] !== 'Disponible') {
            http_response_code(409);
            echo json_encode(['error' => 'La cancha no está disponible en este momento']);
            break;
        }

        $stmt = $pdo->prepare(
            "INSERT INTO reservas (cancha_id, usuario_id, horario, fecha, monto, estado)
             VALUES (?, ?, ?, ?, ?, 'Confirmada')"
        );
        $stmt->execute([$cancha_id, $usuario_id, $horario, $fecha, $cancha['precio']]);
        $id = $pdo->lastInsertId();

        // Marcar la cancha como Ocupada
        $pdo->prepare("UPDATE canchas SET estado='Ocupada' WHERE id=?")->execute([$cancha_id]);

        $reserva = $pdo->query(
            "SELECT r.*, c.nombre AS cancha_nombre, u.nombre AS cliente_nombre
             FROM reservas r
             JOIN canchas c ON r.cancha_id=c.id
             JOIN usuarios u ON r.usuario_id=u.id
             WHERE r.id=$id"
        )->fetch();
        http_response_code(201);
        echo json_encode($reserva);
        break;

    // DELETE /reservas/?id=X — cancelar reserva
    case 'DELETE':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) { http_response_code(400); echo json_encode(['error'=>'ID requerido']); break; }
        $reserva = $pdo->query("SELECT * FROM reservas WHERE id=$id")->fetch();
        if (!$reserva) { http_response_code(404); echo json_encode(['error'=>'Reserva no encontrada']); break; }

        $pdo->prepare("UPDATE reservas SET estado='Cancelada' WHERE id=?")->execute([$id]);
        // Liberar la cancha si no tiene otras reservas confirmadas
        $otras = $pdo->prepare(
            "SELECT COUNT(*) as c FROM reservas WHERE cancha_id=? AND estado='Confirmada' AND id!=?"
        );
        $otras->execute([$reserva['cancha_id'], $id]);
        if ($otras->fetch()['c'] === 0) {
            // Verificar si hay algún ticket de mantenimiento activo (sin completar) para esta cancha
            $tix = $pdo->prepare("SELECT COUNT(*) as c FROM tickets_mantenimiento WHERE cancha_id=? AND estado!='Completada'");
            $tix->execute([$reserva['cancha_id']]);
            if ($tix->fetch()['c'] > 0) {
                $pdo->prepare("UPDATE canchas SET estado='Mantenimiento' WHERE id=?")->execute([$reserva['cancha_id']]);
            } else {
                $pdo->prepare("UPDATE canchas SET estado='Disponible' WHERE id=?")->execute([$reserva['cancha_id']]);
            }
        }
        echo json_encode(['success' => true]);
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido']);
}
