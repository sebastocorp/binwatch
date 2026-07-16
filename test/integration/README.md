# Integration test: binwatch + MySQL 8.0 with mTLS

End-to-end environment to validate the whole flow with TLS/mTLS enabled:

```text
traffic (random INSERT/UPDATE/DELETE/SELECT, mTLS)
   └──> mysql:8.0 (require_secure_transport=ON, users REQUIRE X509)
           └──binlog──> binwatch (source.tls: ca + client cert)
                            └──> webhook (http echo, prints received events)
```

Both MySQL users (`binwatch` and `traffic`) are created with `REQUIRE X509`,
so connections are rejected unless the client presents a certificate signed
by the test CA — this proves the client certificate is actually being used,
not just the server one.

The server certificate includes `SAN: DNS:mysql`, so binwatch runs with full
verification (`insecureSkipVerify: false`).

## Usage

From the repository root:

```bash
make int-test-up      # generate certs, build image and start everything
make int-test-logs    # follow binwatch + webhook logs (events arriving)
make int-test-down    # tear down (volumes included)
```

Or manually:

```bash
cd test/integration
./certs/generate-certs.sh
docker compose up --build -d
docker compose logs -f binwatch webhook
```

## What to check

- `binwatch` logs show `start sync process` and `success adding event in pool`
  for the INSERTs/UPDATEs/DELETEs made by `traffic` (SELECTs must NOT appear:
  they don't produce binlog events).
- `webhook` logs print the JSON events rendered by the route template.
- To verify mTLS is enforced, try connecting without a client certificate:

  ```bash
  docker compose exec mysql mysql -h127.0.0.1 -ubinwatch -pbinwatch \
    --ssl-mode=REQUIRED -e 'SELECT 1'
  # ERROR 1045: Access denied (no X509 certificate presented)
  ```

## Files

| Path | Purpose |
|:-----|:--------|
| `docker-compose.yaml` | The four services described above |
| `certs/generate-certs.sh` | Creates CA + server + client certs (gitignored `*.pem`) |
| `mysql/init.sql` | Schema `testdb.users` + users with `REQUIRE X509` |
| `binwatch/config.yaml` | binwatch config with `source.tls` enabled |
| `traffic/traffic.sh` | Random DML/SELECT loop over mTLS |