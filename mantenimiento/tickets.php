<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        $stmt = $pdo->query(
            "SELECT t.*, c.nombre AS cancha_nombre, c.tipo AS cancha_tipo,
                    u.nombre AS reportado_por_nombre,
                    tec.nombre AS tecnico_nombre
             FROM tickets_mantenimiento t
             JOIN canchas c ON t.cancha_id = c.id
             JOIN usuarios u ON t.reportado_por = u.id
             LEFT JOIN usuarios tec ON t.tecnico_id = tec.id
             ORDER BY t.creado_en DESC"
        );
        echo json_encode($stmt->fetchAll());
        break;

    case 'POST': // registrar nueva incidencia
        $d               = json_decode(file_get_contents('php://input'), true);
        $cancha_id       = intval($d['cancha_id']       ?? 0);
        $reportado_por   = intval($d['reportado_por']   ?? 0);
        $tipo            = trim($d['tipo']               ?? '');
        $descripcion     = trim($d['descripcion']        ?? '');

        if (!$cancha_id || !$reportado_por || empty($tipo)) {
            http_response_code(400);
            echo json_encode(['error' => 'cancha_id, reportado_por y tipo son requeridos']);
            break;
        }

        // Validar si la cancha está Ocupada
        $cancha = $pdo->query("SELECT estado FROM canchas WHERE id=$cancha_id")->fetch();
        if ($cancha && $cancha['estado'] === 'Ocupada') {
            http_response_code(409);
            echo json_encode(['error' => 'No se puede registrar mantenimiento porque la cancha está Ocupada en juego.']);
            break;
        }

        // Limpieza urgente
        if (stripos($tipo, 'limpieza') !== false) {
            $tipo = 'Limpieza Urgente';
        }

        $stmt = $pdo->prepare(
            "INSERT INTO tickets_mantenimiento (cancha_id, reportado_por, tipo, descripcion, estado)
             VALUES (?, ?, ?, ?, 'Pendiente')"
        );
        $stmt->execute([$cancha_id, $reportado_por, $tipo, $descripcion]);
        $id = $pdo->lastInsertId();

        // Si la cancha está Disponible, pasarla a Mantenimiento
        $cancha = $pdo->query("SELECT estado FROM canchas WHERE id=$cancha_id")->fetch();
        if ($cancha && $cancha['estado'] === 'Disponible') {
            $pdo->prepare("UPDATE canchas SET estado='Mantenimiento' WHERE id=?")->execute([$cancha_id]);
        }

        $ticket = $pdo->query(
            "SELECT t.*, c.nombre AS cancha_nombre, u.nombre AS reportado_por_nombre
             FROM tickets_mantenimiento t
             JOIN canchas c ON t.cancha_id=c.id
             JOIN usuarios u ON t.reportado_por=u.id
             WHERE t.id=$id"
        )->fetch();
        http_response_code(201);
        echo json_encode($ticket);
        break;

    case 'PUT': // actualizar ticket (asignar técnico, avance, completar)
        $id = intval($_GET['id'] ?? 0);
        $d  = json_decode(file_get_contents('php://input'), true);
        if (!$id) { http_response_code(400); echo json_encode(['error'=>'ID requerido']); break; }

        // Validar conflicto de estado si la cancha está Ocupada
        // Solo validar si se está cambiando estado o asignando técnico (no solo avance)
        $ticket = $pdo->query("SELECT * FROM tickets_mantenimiento WHERE id=$id")->fetch();
        if ($ticket) {
            $cId = $ticket['cancha_id'];
            $cancha = $pdo->query("SELECT estado FROM canchas WHERE id=$cId")->fetch();
            $cambiaEstadoOTecnico = isset($d['estado']) || isset($d['tecnico_id']);
            if ($cambiaEstadoOTecnico && $cancha && $cancha['estado'] === 'Ocupada') {
                http_response_code(409);
                echo json_encode(['error' => 'No se puede poner la cancha en Mantenimiento porque actualmente está Ocupada en juego.']);
                break;
            }
        }

        $fields = []; $vals = [];
        if (isset($d['tecnico_id']))  { $fields[] = 'tecnico_id=?';  $vals[] = $d['tecnico_id']; }
        if (isset($d['avance']))      { $fields[] = 'avance=?';       $vals[] = $d['avance']; }
        if (isset($d['estado'])) {
            $fields[] = 'estado=?';
            $vals[]   = $d['estado'];
            if ($d['estado'] === 'En Proceso' && !isset($d['tecnico_id'])) {
                // no cambiar cancha aquí
            }
            if ($d['estado'] === 'Completada') {
                $fields[] = 'cerrado_en=NOW()';
            }
        }

        if (empty($fields)) { http_response_code(400); echo json_encode(['error'=>'Sin datos']); break; }

        $vals[] = $id;
        $pdo->prepare("UPDATE tickets_mantenimiento SET ".implode(',',$fields)." WHERE id=?")->execute($vals);

        // Sincronizar estado de cancha
        $ticket = $pdo->query("SELECT * FROM tickets_mantenimiento WHERE id=$id")->fetch();
        if ($ticket) {
            $nuevoEstadoCancha = match($ticket['estado']) {
                'Pendiente'  => 'Mantenimiento',
                'En Proceso' => 'Mantenimiento',
                'Completada' => 'Disponible',
                default      => null,
            };
            if ($nuevoEstadoCancha) {
                if ($nuevoEstadoCancha === 'Disponible') {
                    // Solo marcar como Disponible si no hay otros tickets activos (sin completar) para esta cancha
                    $tix = $pdo->prepare("SELECT COUNT(*) as c FROM tickets_mantenimiento WHERE cancha_id=? AND estado!='Completada' AND id!=?");
                    $tix->execute([$ticket['cancha_id'], $id]);
                    if ($tix->fetch()['c'] > 0) {
                        $nuevoEstadoCancha = 'Mantenimiento';
                    }
                }
                $pdo->prepare("UPDATE canchas SET estado=? WHERE id=?")->execute([$nuevoEstadoCancha, $ticket['cancha_id']]);
            }
        }

        $updated = $pdo->query(
            "SELECT t.*, c.nombre AS cancha_nombre, u.nombre AS reportado_por_nombre,
                    tec.nombre AS tecnico_nombre
             FROM tickets_mantenimiento t
             JOIN canchas c ON t.cancha_id=c.id
             JOIN usuarios u ON t.reportado_por=u.id
             LEFT JOIN usuarios tec ON t.tecnico_id=tec.id
             WHERE t.id=$id"
        )->fetch();
        echo json_encode($updated);
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido']);
}
