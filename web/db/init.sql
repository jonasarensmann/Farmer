DEFINE TABLE users SCHEMAFULL
  PERMISSIONS
    FOR select, update, delete WHERE id = $auth.id

DEFINE FIELD name ON users TYPE string;
DEFINE FIELD pass ON users TYPE string;

DEFINE INDEX name ON users COLUMNS name UNIQUE;

DEFINE SCOPE users SESSION 24h
	SIGNUP ( CREATE users SET name = $name, pass = crypto::argon2::generate($pass) )
	SIGNIN ( SELECT * FROM users WHERE name = $name AND crypto::argon2::compare(pass, $pass) )
;

DEFINE TABLE crops SCHEMAFULL
  PERMISSIONS
    FOR update, delete WHERE user_id = $auth.id
    FOR select WHERE true;

DEFINE FIELD user ON crops TYPE record<users> DEFAULT $auth.id;
DEFINE FIELD name ON crops TYPE string;
DEFINE FIELD dependencies ON crops TYPE option<array<record<crops>>>;
DEFINE FIELD version ON crops TYPE string DEFAULT "Not Specified";
DEFINE FIELD license ON crops TYPE string DEFAULT "Not Specified";
DEFINE FIELD description ON crops TYPE string DEFAULT "No Description";

USE NS farmer DB main;
DEFINE USER view ON DATABASE PASSWORD 'view' ROLES VIEWER;