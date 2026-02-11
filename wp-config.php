<?php
// ** MySQL settings ** //
define('DB_NAME', getenv('WORDPRESS_DB_NAME'));
define('DB_USER', getenv('WORDPRESS_DB_USER'));
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD'));
define('DB_HOST', getenv('WORDPRESS_DB_HOST'));
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// ** Authentication Unique Keys and Salts ** //
define('AUTH_KEY',         'Si1k)y:G}*o0S0YJU;VSN5*}e9T1{ {/59Yxqoxi,i(!OL-Ag,I[!(:d^YLI^aX+');
define('SECURE_AUTH_KEY',  'bQfMt[j!+Qq64E|*`E*A#||G V-z-[z69O~Q,4IUuT$3CZoB*TX_`rw+s-N(T+x+');
define('LOGGED_IN_KEY',    '{2HMWDd$QIY0jqHD-j[b2tJPLqI9,+&;fWRv~9SG@yVjB82+&(|]nFbO@:6Cq}Nv');
define('NONCE_KEY',        'Q?+Z@nks#maGL/.2cS67l<-o9&a|DUR;gC}hJ<~#R<gV ]Zpudyg6:6++`E,S#G+');
define('AUTH_SALT',        '4#o0FJ~61$HB|Q49YFVlgM{|HW.wIxjqWS)Z+* +CEAELpT(Pm,*cl?b%mln1@[Q');
define('SECURE_AUTH_SALT', '-=^U?=Pquw.JgE$8|=m7Ww^F^jrD!-k`vPQJub~Q|?+ua4F-en2lz=v^a6OC]gmy');
define('LOGGED_IN_SALT',   'q]A]/R(&OVD&d.hEBD7Kp~BIq[ZK{Ypc_Upv i2z$rf294r 2@&2O.P;K8iWv6QD');
define('NONCE_SALT',       'p+#{kc28p *gr&MoLj=+*OwszZA7rcH3|N*[A1FI+Qr)3JE=5VIrtGA@0?=7|D*/');

// ** WordPress Database Table prefix ** //
$table_prefix = 'wp_';

// ** WordPress URLs ** //
define('WP_HOME', 'https://wordpress-production-2b8e.up.railway.app');
define('WP_SITEURL', 'https://wordpress-production-2b8e.up.railway.app');

// ** Forcer HTTPS derrière le proxy Railway ** //
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// ** Debug mode (désactiver en prod) ** //
define('WP_DEBUG', false);

// ** Absolute path to the WordPress directory ** //
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
