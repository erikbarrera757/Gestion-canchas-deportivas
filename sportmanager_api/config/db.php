<?php
// config/db.php — Conexión a MySQL de XAMPP
date_default_timezone_set('America/La_Paz');
$host     = '127.0.0.1';
$dbname   = 'sportmanager_db';
$username = 'root';
$password = ''; // En XAMPP por defecto no tiene contraseña

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Error de conexión a la base de datos: ' . $e->getMessage()]);
    exit;
}
