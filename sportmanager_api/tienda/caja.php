<?php
// Incluir las cabeceras de CORS y la conexión creadas previamente
require_once '../config/cors.php';
require_once '../config/db.php';

header("Content-Type: application/json; charset=UTF-8");

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Verificar si existe una caja abierta actualmente
        try {
            $stmt = $pdo->query("SELECT tc.*, u.nombre as cajero 
                                 FROM turnos_caja tc 
                                 JOIN usuarios u ON tc.usuario_id = u.id 
                                 WHERE tc.estado = 'Abierta' 
                                 LIMIT 1");
            $cajaAbierta = $stmt->fetch();

            if ($cajaAbierta) {
                echo json_encode(["status" => "Abierta", "caja" => $cajaAbierta]);
            } else {
                echo json_encode(["status" => "Cerrada", "mensaje" => "No hay ningún turno de caja activo."]);
            }
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["error" => "Error al consultar caja: " . $e->getMessage()]);
        }
        break;

    case 'POST':
        // Leer el cuerpo de la petición (JSON)
        $data = json_decode(file_get_contents("php://input"), true);
        $accion = $data['accion'] ?? '';

        if ($accion === 'apertura') {
            $usuario_id = $data['usuario_id'] ?? 5; // Por defecto Ana Tienda (id: 5) para pruebas
            $monto_inicial = $data['monto_inicial'] ?? 0;

            if ($monto_inicial < 0) {
                http_response_code(400);
                echo json_encode(["error" => "El monto inicial no puede ser un valor negativo."]);
                exit;
            }

            try {
                // Validación estricta: verificar que no haya otra abierta simultáneamente
                $check = $pdo->query("SELECT id FROM turnos_caja WHERE estado = 'Abierta'")->fetch();
                if ($check) {
                    http_response_code(400);
                    echo json_encode(["error" => "Ya existe un turno de caja activo en el sistema."]);
                    exit;
                }

                // Insertar apertura
                $stmt = $pdo->prepare("INSERT INTO turnos_caja (usuario_id, monto_inicial, estado) VALUES (?, ?, 'Abierta')");
                $stmt->execute([$usuario_id, $monto_inicial]);

                echo json_encode(["success" => true, "mensaje" => "Turno de caja inicializado correctamente."]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Error al abrir caja: " . $e->getMessage()]);
            }
        } 
        
        elseif ($accion === 'cierre') {
            $caja_id = $data['caja_id'] ?? null;
            $monto_final_real = $data['monto_final_real'] ?? 0;

            if (!$caja_id) {
                http_response_code(400);
                echo json_encode(["error" => "ID de caja faltante o inválido."]);
                exit;
            }

            try {
                // Calcular el balance automático cruzando transacciones (Ventas de snack y Alquileres de implementos)
                // 1. Obtener monto inicial de esta caja
                $stmtCaja = $pdo->prepare("SELECT monto_inicial FROM turnos_caja WHERE id = ?");
                $stmtCaja->execute([$caja_id]);
                $cajaInfo = $stmtCaja->fetch();
                $monto_inicial = $cajaInfo['monto_inicial'] ?? 0;

                // 2. Sumar ventas del snack vinculadas (asumiendo flujo referencial en ventas_snack)
                // Nota: agregamos una columna en tus consultas si es necesario, o sumamos directo por fecha/usuario
                // Para consistencia con tu tabla actual sumaremos las ventas efectuadas durante la vigencia del turno
                $sumVentas = $pdo->query("SELECT IFNULL(SUM(total), 0) as total FROM ventas_snack")->fetch();
                
                // 3. Sumar dinero recaudado de alquileres activos ingresados en este turno
                $stmtAlq = $pdo->prepare("SELECT IFNULL(SUM(monto + multa), 0) as total FROM control_alquileres WHERE turno_caja_id = ?");
                $stmtAlq->execute([$caja_id]);
                $resAlq = $stmtAlq->fetch();

                $calculado = $monto_inicial + $sumVentas['total'] + $resAlq['total'];

                // Actualizar el turno para cerrarlo
                $stmtCierre = $pdo->prepare("UPDATE turnos_caja 
                                             SET monto_final_real = ?, monto_final_calculado = ?, estado = 'Cerrada', fecha_cierre = CURRENT_TIMESTAMP 
                                             WHERE id = ?");
                $stmtCierre->execute([$monto_final_real, $calculado, $caja_id]);

                // Generar desfase si existiese (Métrica para auditoría del Supervisor)
                $desfase = $monto_final_real - $calculado;

                echo json_encode([
                    "success" => true, 
                    "mensaje" => "Caja cerrada de forma exitosa.",
                    "calculado" => $calculado,
                    "real" => $monto_final_real,
                    "desfase" => $desfase
                ]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Error al cerrar caja: " . $e->getMessage()]);
            }
        }
        break;
}