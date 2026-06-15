<?php
require_once '../config/cors.php';
require_once '../config/db.php';

header("Content-Type: application/json; charset=UTF-8");

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        try {
            // Retorna los implementos deportivos y los alquileres activos para la UI
            $implementos = $pdo->query("SELECT * FROM implementos WHERE activo = 1")->fetchAll();
            
            $alquileresActivos = $pdo->query("SELECT ca.*, i.nombre AS implemento, u.nombre AS cliente 
                                              FROM control_alquileres ca
                                              JOIN implementos i ON ca.implemento_id = i.id
                                              JOIN usuarios u ON ca.usuario_id = u.id
                                              WHERE ca.estado_alquiler = 'Activo'")->fetchAll();
            
            echo json_encode([
                "implementos" => $implementos,
                "alquileres" => $alquileresActivos
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["error" => "Error al obtener datos de alquileres: " . $e->getMessage()]);
        }
        break;

    case 'POST':
        $data = json_decode(file_get_contents("php://input"), true);
        $accion = $data['accion'] ?? '';

        // ────────────────────────────────────────────────────────
        // SUB-FLUJO: REGISTRAR ALQUILER (CU18)
        // ────────────────────────────────────────────────────────
        if ($accion === 'alquilar') {
            $implemento_id = $data['implemento_id'] ?? null;
            $usuario_id = $data['usuario_id'] ?? 2; // Cliente de prueba por defecto
            $horas = $data['horas'] ?? 1;

            if (!$implemento_id || $horas <= 0) {
                http_response_code(400);
                echo json_encode(["error" => "Parámetros insuficientes o inválidos para procesar el alquiler."]);
                exit;
            }

            try {
                $pdo->beginTransaction();

                // 1. Validar REGLA DE NEGOCIO (RF-08): Debe existir una caja abierta obligatoriamente
                $stmtCaja = $pdo->query("SELECT id FROM turnos_caja WHERE estado = 'Abierta' LIMIT 1");
                $caja = $stmtCaja->fetch();
                if (!$caja) {
                    throw new Exception("Operación bloqueada: No se puede registrar un alquiler si no se ha inicializado una caja de turno.");
                }
                $turno_caja_id = $caja['id'];

                // 2. Validar disponibilidad física del artículo (Stock > 0)
                $stmtImp = $pdo->prepare("SELECT stock, precio_alquiler, nombre FROM implementos WHERE id = ? AND activo = 1");
                $stmtImp->execute([$implemento_id]);
                $imp = $stmtImp->fetch();

                if (!$imp || $imp['stock'] <= 0) {
                    throw new Exception("El implemento seleccionado no cuenta con unidades disponibles en este momento.");
                }

                // 3. Calcular costo base matemática
                $monto_total = $imp['precio_alquiler'] * $horas;

                // 4. Registrar la transacción de préstamo
                $stmtInsert = $pdo->prepare("INSERT INTO control_alquileres (implemento_id, usuario_id, turno_caja_id, horas, monto, estado_alquiler) VALUES (?, ?, ?, ?, ?, 'Activo')");
                $stmtInsert->execute([$implemento_id, $usuario_id, $turno_caja_id, $horas, $monto_total]);

                // 5. Restar 1 unidad del stock de implementos
                $stmtSub = $pdo->prepare("UPDATE implementos SET stock = stock - 1 WHERE id = ?");
                $stmtSub->execute([$implemento_id]);

                $pdo->commit();
                echo json_encode(["success" => true, "mensaje" => "Alquiler de '" . $imp['nombre'] . "' registrado con éxito. Ticket emitido."]);

            } catch (Exception $e) {
                if ($pdo->inTransaction()) $pdo->rollBack();
                http_response_code(400);
                echo json_encode(["error" => $e->getMessage()]);
            }
        }

        // ────────────────────────────────────────────────────────
        // SUB-FLUJO: PROCESAR DEVOLUCIÓN Y MULTAS (CU19)
        // ────────────────────────────────────────────────────────
        elseif ($accion === 'devolver') {
            $alquiler_id = $data['alquiler_id'] ?? null;
            $estado_fisico = $data['estado_fisico_retorno'] ?? 'Buen Estado';

            if (!$alquiler_id) {
                http_response_code(400);
                echo json_encode(["error" => "ID del alquiler no especificado."]);
                exit;
            }

            try {
                $pdo->beginTransaction();

                // 1. Obtener datos del alquiler vigente
                $stmtAlq = $pdo->prepare("SELECT ca.*, i.precio_venta AS costo_reposicion 
                                          FROM control_alquileres ca
                                          JOIN implementos i ON ca.implemento_id = i.id
                                          WHERE ca.id = ? AND ca.estado_alquiler = 'Activo'");
                $stmtAlq->execute([$alquiler_id]);
                $alquiler = $stmtAlq->fetch();

                if (!$alquiler) {
                    throw new Exception("El registro de alquiler no está activo o ya fue devuelto.");
                }

                // 2. Algoritmo de cálculo de multas indexado según el estado constructivo (CU19 - Requerimiento del Informe)
                $multa = 0.00;
                if ($estado_fisico === 'Dañado') {
                    // Penalización por daño parcial estructural: 50% del valor venal de reposición
                    $multa = $alquiler['costo_reposicion'] * 0.50;
                } elseif ($estado_fisico === 'Extraviado') {
                    // Extravió completo: Se cobra el 100% del costo de reposición comercial cargado al cliente
                    $multa = $alquiler['costo_reposicion'];
                }

                // 3. Actualizar la ficha de control del préstamo
                $stmtUpdateAlq = $pdo->prepare("UPDATE control_alquileres 
                                                SET estado_fisico_retorno = ?, multa = ?, estado_alquiler = 'Devuelto', fecha_retorno = CURRENT_TIMESTAMP 
                                                WHERE id = ?");
                $stmtUpdateAlq->execute([$estado_fisico, $multa, $alquiler_id]);

                // 4. Devolución física al stock si no se destruyó o extravió por completo
                if ($estado_fisico !== 'Extraviado') {
                    $stmtAdd = $pdo->prepare("UPDATE implementos SET stock = stock + 1 WHERE id = ?");
                    $stmtAdd->execute([$alquiler['implemento_id']]);
                }

                $pdo->commit();

                $msg = ($multa > 0) 
                    ? "Retorno procesado con incidencias críticas. Estado: $estado_fisico. Se aplicó una multa automatizada de $multa Bs."
                    : "Devolución limpia procesada con éxito. El implemento deportivo vuelve a estar 'Disponible'.";

                echo json_encode(["success" => true, "mensaje" => $msg]);

            } catch (Exception $e) {
                if ($pdo->inTransaction()) $pdo->rollBack();
                http_response_code(400);
                echo json_encode(["error" => $e->getMessage()]);
            }
        }
        break;
}