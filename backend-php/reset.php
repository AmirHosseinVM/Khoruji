<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';

header('Content-Type: application/json; charset=utf-8');

$secret = $_GET['secret'] ?? '';
if (!hash_equals(ADMIN_SECRET, $secret)) {
    http_response_code(403);
    echo json_encode(['error' => 'forbidden']);
    exit;
}

$token = $_GET['token'] ?? '';
if ($token === '') {
    http_response_code(400);
    echo json_encode(['error' => 'token_required']);
    exit;
}

$realToken = preg_replace('/\.X\d+$/i', '', $token);

try {
    $conn = get_db();
    $del = $conn->prepare('DELETE FROM devices WHERE token = ?');
    $del->bind_param('s', $realToken);
    $del->execute();
    $removed = $del->affected_rows;
    $del->close();
    echo json_encode(['ok' => true, 'removed_devices' => $removed]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'db_error']);
}
