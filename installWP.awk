/^.*define\( *'DB_NAME'/ {
  printf("define('DB_NAME', '~~~DBName~~~');\n");
  next
}

/^.*define\( *'DB_USER'/ {
  printf("define('DB_USER', '~~~DBUser~~~');\n");
  next
}

/^.*define\( *'DB_PASSWORD'/ {
  printf("define('DB_PASSWORD', '~~~DBPassword~~~');\n");
  next
}

/^.*define\( *'DB_HOST'/ {
  printf("define('DB_HOST', 'localhost');\n");
  next
}

/^.*define\( *'AUTH_KEY'/ {
  printf("define('AUTH_KEY',         '~~~authKey~~~');\n");
  next
}

/^.*define\( *'SECURE_AUTH_KEY'/ {
  printf("define('SECURE_AUTH_KEY',  '~~~secureAuthKey~~~');\n");
  next
}

/^.*define\( *'LOGGED_IN_KEY'/ {
  printf("define('LOGGED_IN_KEY',    '~~~loggedInKey~~~');\n");
  next
}

/^.*define\( *'NONCE_KEY'/ {
  printf("define('NONCE_KEY',        '~~~nonCEKey~~~');\n");
  next
}

/^.*define\( *'AUTH_SALT'/ {
  printf("define('AUTH_SALT',        '~~~authSalt~~~');\n");
  next
}

/^.*define\( *'SECURE_AUTH_SALT'/ {
  printf("define('SECURE_AUTH_SALT', '~~~secureAuthSalt~~~');\n");
  next
}

/^.*define\( *'LOGGED_IN_SALT'/ {
  printf("define('LOGGED_IN_SALT',   '~~~loggedInSalt~~~');\n");
  next
}

/^.*define\( *'NONCE_SALT'/ {
  printf("define('NONCE_SALT',       '~~~nonCESalt~~~');\n");
  next
}

1
