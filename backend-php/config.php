<?php
// -----------------------------------------------------------------------
// OneSpeed API config
// -----------------------------------------------------------------------

// Real Pasargad-panel subscription base (never exposed to the app/client)
define('PANEL_SUB_BASE', 'https://sonati.dlmusicremix.ir/sub/');

// Shown in the app's telegram icon
define('TELEGRAM_CHANNEL', 'https://t.me/your_channel');

// Secret used by reset.php to unbind a device (change this!)
define('ADMIN_SECRET', 'change-this-to-a-long-random-string');

// ---- MySQL connection (mysqli, localhost, default port) ----
define('DB_HOST', 'localhost');
define('DB_NAME', 'yourcpaneluser_onespeed');
define('DB_USER', 'yourcpaneluser_onespeed');
define('DB_PASS', 'your-db-password');
