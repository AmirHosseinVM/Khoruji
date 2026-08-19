<?php
require_once __DIR__ . '/config.php';

// throw exceptions on mysqli errors instead of silently returning false,
// so the try/catch blocks in sub.php / reset.php keep working the same way
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

function get_db(): mysqli {
    static $conn = null;
    if ($conn !== null) return $conn;

    $conn = mysqli_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    $conn->set_charset('utf8mb4');
    return $conn;
}

/*
Run this ONCE in phpMyAdmin before going live:

CREATE TABLE IF NOT EXISTS devices (
  token       VARCHAR(191)      NOT NULL,
  device_id   VARCHAR(191)      NOT NULL,
  first_seen  INT UNSIGNED      NOT NULL,
  last_seen   INT UNSIGNED      NOT NULL,
  PRIMARY KEY (token, device_id),
  INDEX idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
*/
