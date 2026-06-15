<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];
$tipo   = $_GET['tipo'] ?? 'reservas';

if ($method !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
    exit;
}

switch ($tipo) {
    case 'reservas':
        $stmt = $pdo->query(
            "SELECT r.id, r.fecha, r.horario, r.estado,
                    c.nombre AS cancha, c.tipo AS cancha_tipo, c.precio,
                    u.nombre AS cliente, u.email AS cliente_email
             FROM reservas r
             JOIN canchas c ON r.cancha_id = c.id
             JOIN usuarios u ON r.usuario_id = u.id
             ORDER BY r.fecha DESC, r.horario ASC
             LIMIT 100"
        );
        echo json_encode($stmt->fetchAll());
        break;

    case 'ingresos_snack':
        $stmt = $pdo->query(
            "SELECT v.id, v.creado_en AS fecha, v.total, v.cantidad,
                    p.nombre AS producto,
                    u.nombre AS vendedor
             FROM ventas_snack v
             JOIN productos_snack p ON v.producto_id = p.id
             JOIN usuarios u ON v.usuario_id = u.id
             ORDER BY v.creado_en DESC
             LIMIT 100"
        );
        echo json_encode($stmt->fetchAll());
        break;

    case 'stock_tienda':
        $stmt = $pdo->query(
            "SELECT i.id, i.nombre, i.stock, i.precio_alquiler, i.precio_venta,
                    'Equipamiento' AS categoria, i.activo
             FROM implementos i
             ORDER BY i.nombre ASC"
        );
        echo json_encode($stmt->fetchAll());
        break;

    case 'mantenimiento':
        $stmt = $pdo->query(
            "SELECT t.id, t.tipo, t.descripcion, t.estado, t.avance,
                    t.creado_en, t.cerrado_en,
                    c.nombre AS cancha,
                    rep.nombre AS reportado_por,
                    tec.nombre AS tecnico
             FROM tickets_mantenimiento t
             JOIN canchas c ON t.cancha_id = c.id
             JOIN usuarios rep ON t.reportado_por = rep.id
             LEFT JOIN usuarios tec ON t.tecnico_id = tec.id
             ORDER BY t.creado_en DESC
             LIMIT 100"
        );
        echo json_encode($stmt->fetchAll());
        break;

    case 'resumen':
        // KPIs generales para el dashboard del administrador
        $totalReservas    = $pdo->query("SELECT COUNT(*) FROM reservas")->fetchColumn();
        $ingresosReservas = $pdo->query("SELECT COALESCE(SUM(c.precio),0) FROM reservas r JOIN canchas c ON r.cancha_id=c.id WHERE r.estado='Confirmada'")->fetchColumn();
        $ingresosSnack    = $pdo->query("SELECT COALESCE(SUM(total),0) FROM ventas_snack")->fetchColumn();
        $ticketsPendientes= $pdo->query("SELECT COUNT(*) FROM tickets_mantenimiento WHERE estado='Pendiente'")->fetchColumn();
        $ticketsCompletados= $pdo->query("SELECT COUNT(*) FROM tickets_mantenimiento WHERE estado='Completada'")->fetchColumn();
        $canchasDisp      = $pdo->query("SELECT COUNT(*) FROM canchas WHERE estado='Disponible'")->fetchColumn();

        echo json_encode([
            'total_reservas'       => (int)$totalReservas,
            'ingresos_reservas'    => (float)$ingresosReservas,
            'ingresos_snack'       => (float)$ingresosSnack,
            'tickets_pendientes'   => (int)$ticketsPendientes,
            'tickets_completados'  => (int)$ticketsCompletados,
            'canchas_disponibles'  => (int)$canchasDisp,
        ]);
        break;

    default:
        http_response_code(400);
        echo json_encode(['error' => "Tipo de reporte '$tipo' no reconocido"]);
}
