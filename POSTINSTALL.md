Your SmokePing instance is ready!

### Login Credentials

HTTP Basic Auth credentials were generated on first install. View them via the [Web Terminal](https://docs.cloudron.io/apps/#web-terminal):

```
cat /app/data/htpasswd.txt
```

You can also set custom credentials in `/app/data/.env`:

```
SMOKEPING_ADMIN_USER=admin
SMOKEPING_ADMIN_PASS=your-password
```

### Configuration

All settings are configurable via `/app/data/.env` — see the file for available variables.

For advanced customization, edit the split config files in `/app/data/config/`. Deleting a config file restores its default on next restart.

### Test Email Delivery

```
/app/pkg/test-email.sh your@email.com
```
