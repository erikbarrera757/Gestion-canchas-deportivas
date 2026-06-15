<?php
require_once '../config/cors.php';
require_once '../config/db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);
$email    = trim($data['email']    ?? '');
$password = trim($data['password'] ?? '');

if (empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['error' => 'Email y contraseña son requeridos']);
    exit;
}

// 1. Seleccionamos el usuario por su email y traemos la contraseña encriptada (password)
$stmt = $pdo->prepare(
    "SELECT id, nombre, email, password, rol FROM usuarios 
     WHERE email = ? AND activo = 1 
     LIMIT 1"
);
$stmt->execute([$email]);
$user = $stmt->fetch();

// 2. Si el usuario existe, verificamos el hash con password_verify
if ($user && password_verify($password, $user['password'])) {
    
    // Quitamos el hash de la contraseña del objeto antes de enviarlo por seguridad
    unset($user['password']);

    http_response_code(200);
    echo json_encode(['success' => true, 'user' => $user]);
} else {
    // Si no existe o la contraseña no coincide, lanzamos el error 401
    http_response_code(401);
    echo json_encode(['success' => false, 'error' => 'Correo o contraseña incorrectos']);
}