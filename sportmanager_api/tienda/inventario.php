<?php
require_once '../config/cors.php';
require_once '../config/db.php';

header("Content-Type: application/json; charset=UTF-8");

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // CU14: Consultar Stock (con o sin criterio de búsqueda)
        try {
            $criterio = $_GET['buscar'] ?? '';
            
            if (!empty($criterio)) {
                // Filtro predictivo por nombre
                $stmt = $pdo->prepare("SELECT *, (stock <= 3) AS alerta_critica FROM productos_snack WHERE nombre LIKE ? AND activo = 1");
                $stmt->execute(["%$criterio%"]);
            } else {
                // Listado general completo
                $stmt = $pdo->query("SELECT *, (stock <= 3) AS alerta_critica FROM productos_snack WHERE activo = 1");
            }
            
            $productos = $stmt->fetchAll();
            echo json_encode($productos);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["error" => "Error al consultar inventario: " . $e->getMessage()]);
        }
        break;

    case 'POST':
        // CU17: Reportar Mermas o Productos Vencidos
        $data = json_decode(file_get_contents("php://input"), true);
        
        $producto_id = $data['producto_id'] ?? null;
        $cantidad_baja = $data['cantidad_baja'] ?? null;
        $motivo = $data['motivo'] ?? null;

        // Validaciones estrictas de reglas de negocio
        if (!$producto_id || !$cantidad_baja || !$motivo) {
            http_response_code(400);
            echo json_encode(["error" => "Todos los campos (Producto, Cantidad y Motivo) son obligatorios."]);
            exit;
        }

        if ($cantidad_baja <= 0) {
            http_response_code(400);
            echo json_encode(["error" => "La cantidad de baja debe ser mayor a cero."]);
            exit;
        }

        try {
            // Iniciar transacción para asegurar consistencia atómica (Mecanismo ACUID/Persistencia de estados)
            $pdo->beginTransaction();

            // 1. Verificar si hay stock suficiente para realizar la baja
            $stmtCheck = $pdo->prepare("SELECT stock, nombre FROM productos_snack WHERE id = ?");
            $stmtCheck->execute([$producto_id]);
            $producto = $stmtCheck->fetch();

            if (!$producto) {
                throw new Exception("El producto seleccionado no existe.");
            }

            if ($producto['stock'] < $cantidad_baja) {
                // Extensión 3.a del informe: Cantidad de baja inconsistente
                throw new Exception("Inconsistencia: La cantidad ingresada (" . $cantidad_baja . ") supera al stock real (" . $producto['stock'] . ") de " . $producto['nombre']);
            }

            // 2. Insertar el registro de control de merma
            $stmtMerma = $pdo->prepare("INSERT INTO control_mermas (producto_id, cantidad_baja, motivo) VALUES (?, ?, ?)");
            $stmtMerma->execute([$producto_id, $cantidad_baja, $motivo]);

            // 3. Resta algebraica en la entidad del producto (RF-05)
            $stmtUpdate = $pdo->prepare("UPDATE productos_snack SET stock = stock - ? WHERE id = ?");
            $stmtUpdate->execute([$cantidad_baja, $producto_id]);

            // Confirmar cambios
            $pdo->commit();

            echo json_encode(["success" => true, "mensaje" => "Reporte de merma procesado. Stock depurado correctamente."]);

        } catch (Exception $e) {
            // Deshacer cambios ante cualquier error técnico o de negocio
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            http_response_code(400);
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;
}