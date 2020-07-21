create database ~~~DBName~~~;
grant all privileges on ~~~DBName~~~.* to "~~~DBUser~~~"@"localhost" identified by "~~~DBPassword~~~";
flush privileges;
