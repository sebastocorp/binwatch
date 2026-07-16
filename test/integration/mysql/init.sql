-- Schema and users for the binwatch integration test.
-- Both users REQUIRE X509: connections without a valid client certificate
-- signed by the CA are rejected, which proves mTLS end to end.

CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    email VARCHAR(128) NOT NULL,
    score INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Replication user for binwatch
CREATE USER 'binwatch'@'%' IDENTIFIED BY 'binwatch' REQUIRE X509;
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'binwatch'@'%';
GRANT SELECT ON testdb.* TO 'binwatch'@'%';

-- DML user for the traffic generator
CREATE USER 'traffic'@'%' IDENTIFIED BY 'traffic' REQUIRE X509;
GRANT SELECT, INSERT, UPDATE, DELETE ON testdb.* TO 'traffic'@'%';

FLUSH PRIVILEGES;