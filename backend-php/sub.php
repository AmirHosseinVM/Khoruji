<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';

header('Content-Type: application/json; charset=utf-8');

function fail(string $error, int $status = 400, array $extra = []): void {
    http_response_code($status);
    echo json_encode(array_merge(['error' => $error], $extra), JSON_UNESCAPED_UNICODE);
    exit;
}

$rawToken = $_GET['token'] ?? '';
if ($rawToken === '') fail('token_required', 400);

$deviceId = $_SERVER['HTTP_X_DEVICE_ID'] ?? '';
if ($deviceId === '') fail('device_id_required', 400);

// ---- parse the .X<n> device-tier suffix ----
$maxDevices = 1;
$realToken = $rawToken;
if (preg_match('/\.X(\d+)$/i', $rawToken, $m)) {
    $maxDevices = (int) $m[1];
    $realToken = substr($rawToken, 0, -strlen($m[0]));
}

// ---- device-lock enforcement (mysqli) ----
try {
    $conn = get_db();
    $now = time();

    $stmt = $conn->prepare('SELECT device_id FROM devices WHERE token = ?');
    $stmt->bind_param('s', $realToken);
    $stmt->execute();
    $result = $stmt->get_result();
    $existing = [];
    while ($row = $result->fetch_assoc()) $existing[] = $row['device_id'];
    $stmt->close();

    $known = in_array($deviceId, $existing, true);

    if ($known) {
        $upd = $conn->prepare('UPDATE devices SET last_seen = ? WHERE token = ? AND device_id = ?');
        $upd->bind_param('iss', $now, $realToken, $deviceId);
        $upd->execute();
        $upd->close();
    } else {
        if (count($existing) >= $maxDevices) {
            fail('device_limit_reached', 403, ['limit' => $maxDevices, 'active' => count($existing)]);
        }
        $ins = $conn->prepare('INSERT INTO devices (token, device_id, first_seen, last_seen) VALUES (?, ?, ?, ?)');
        $ins->bind_param('ssii', $realToken, $deviceId, $now, $now);
        $ins->execute();
        $ins->close();
    }
} catch (Throwable $e) {
    fail('db_error', 500);
}

// ---- fetch the real subscription server-side; the client never sees this domain ----
$ch = curl_init(PANEL_SUB_BASE . $realToken);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 10,
    CURLOPT_HTTPHEADER => ['Accept: application/json'],
]);
$body = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlErr = curl_error($ch);
curl_close($ch);

if ($body === false || $httpCode !== 200) {
    fail('upstream_failed', 502, ['detail' => $curlErr ?: "http_$httpCode"]);
}

echo $body;
