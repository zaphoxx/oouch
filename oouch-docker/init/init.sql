DROP DATABASE IF EXISTS Consumer;
CREATE DATABASE IF NOT EXISTS Consumer;
GRANT ALL PRIVILEGES ON Consumer.* TO 'qtc'@'%' IDENTIFIED BY 'clarabibi2019!';
GRANT ALL PRIVILEGES ON Consumer.* TO 'qtc'@'localhost' IDENTIFIED BY 'clarabibi2019!';
use Consumer;

CREATE TABLE token (
  id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  oouch_username VARCHAR(120),
  user_id INT
);
CREATE UNIQUE INDEX ix_token_oouch_username ON token(oouch_username);
CREATE UNIQUE INDEX ix_token_user_id ON token(user_id);

CREATE TABLE user (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(64),
    email VARCHAR(120),
    password_hash VARCHAR(128)
);
CREATE UNIQUE INDEX ix_user_username ON user(username);
CREATE UNIQUE INDEX ix_user_email ON user(email);


INSERT INTO user
  (username, email)
VALUES
  ('constantine', 'constantine@oouch.htb');
