#!/bin/bash
# Random DML/SELECT traffic generator against the integration MySQL, always
# over mTLS. Weights: 40% INSERT, 25% UPDATE, 15% DELETE, 20% SELECT.
set -u

MYSQL=(mysql -h mysql -utraffic -ptraffic
  --ssl-ca=/certs/ca.pem
  --ssl-cert=/certs/client-cert.pem
  --ssl-key=/certs/client-key.pem
  --ssl-mode=VERIFY_IDENTITY
  testdb)

run() {
  "${MYSQL[@]}" -e "$1" 2>&1 | grep -v "Using a password"
}

echo "traffic generator started (mTLS, VERIFY_IDENTITY)"

i=0
while true; do
  i=$((i + 1))
  dice=$((RANDOM % 100))

  if [ "$dice" -lt 40 ]; then
    name="user-$RANDOM"
    run "INSERT INTO users (name, email, score) VALUES ('$name', '$name@example.com', $((RANDOM % 1000)));"
    echo "[$i] INSERT $name"
  elif [ "$dice" -lt 65 ]; then
    run "UPDATE users SET score = $((RANDOM % 1000)) ORDER BY RAND() LIMIT 1;"
    echo "[$i] UPDATE random row"
  elif [ "$dice" -lt 80 ]; then
    run "DELETE FROM users ORDER BY RAND() LIMIT 1;"
    echo "[$i] DELETE random row"
  else
    count=$(run "SELECT COUNT(*) FROM users;" | tail -1)
    echo "[$i] SELECT count=$count"
  fi

  sleep "$((RANDOM % 3 + 1))"
done