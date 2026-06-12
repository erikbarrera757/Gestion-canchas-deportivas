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

$stmt = $pdo->prepare(
    "SELECT id, nombre, email, rol FROM usuarios
     WHERE email = ? AND password = MD5(?) AND activo = 1
     LIMIT 1"
);
$stmt->execute([$email, $password]);
$user = $stmt->fetch();

if ($user) {
    http_response_code(200);
    echo json_encode(['success' => true, 'user' => $user]);
} else {
    http_response_code(401);
    echo json_encode(['success' => false, 'error' => 'Correo o contraseña incorrectos']);
}
