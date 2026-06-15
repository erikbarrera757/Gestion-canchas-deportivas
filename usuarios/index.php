<?php
require_once '../config/cors.php';
require_once '../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Listar usuarios (opcionalmente filtrar por rol)
        $rol = $_GET['rol'] ?? null;
        if ($rol) {
            $stmt = $pdo->prepare("SELECT id, nombre, email, rol FROM usuarios WHERE rol = ? AND activo = 1 ORDER BY nombre ASC");
            $stmt->execute([$rol]);
        } else {
            $stmt = $pdo->query("SELECT id, nombre, email, rol FROM usuarios WHERE activo = 1 ORDER BY nombre ASC");
        }
        echo json_encode($stmt->fetchAll());
        break;

    case 'POST':
        $d        = json_decode(file_get_contents('php://input'), true);
        $nombre   = trim($d['nombre']   ?? '');
        $email    = trim($d['email']    ?? '');
        $password = trim($d['password'] ?? '');
        $rol      = trim($d['rol']      ?? 'cliente');

        if (empty($nombre) || empty($email) || empty($password)) {
            http_response_code(400);
            echo json_encode(['error' => 'nombre, email y password son requeridos']);
            break;
        }

        // Verificar email duplicado
        $check = $pdo->prepare("SELECT id FROM usuarios WHERE email = ?");
        $check->execute([$email]);
        if ($check->fetch()) {
            http_response_code(409);
            echo json_encode(['error' => 'El email ya está registrado']);
            break;
        }

        $hash = password_hash($password, PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("INSERT INTO usuarios (nombre, email, password, rol) VALUES (?, ?, ?, ?)");
        $stmt->execute([$nombre, $email, $hash, $rol]);
        $id = $pdo->lastInsertId();
        http_response_code(201);
        echo json_encode(['success' => true, 'id' => $id, 'nombre' => $nombre, 'rol' => $rol]);
        break;

    case 'PUT':
        $id = intval($_GET['id'] ?? 0);
        $d  = json_decode(file_get_contents('php://input'), true);
        if (!$id) { http_response_code(400); echo json_encode(['error' => 'ID requerido']); break; }

        $fields = []; $vals = [];
        if (isset($d['nombre']))  { $fields[] = 'nombre=?';  $vals[] = $d['nombre']; }
        if (isset($d['email']))   { $fields[] = 'email=?';   $vals[] = $d['email'];  }
        if (isset($d['rol']))     { $fields[] = 'rol=?';     $vals[] = $d['rol'];    }
        if (isset($d['activo']))  { $fields[] = 'activo=?';  $vals[] = $d['activo']; }

        if (empty($fields)) { http_response_code(400); echo json_encode(['error' => 'Sin datos']); break; }

        $vals[] = $id;
        $pdo->prepare("UPDATE usuarios SET ".implode(',',$fields)." WHERE id=?")->execute($vals);
        echo json_encode(['success' => true]);
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido']);
}
