![screenshot](screenshots/smokeping-01.png)

<div align="center">
    <h1>Cloudron SmokePing</h1>
    <p>A Cloudron community app packaging of <a href="https://oss.oetiker.ch/smokeping/">SmokePing</a> — latency logging, graphing, and alerting with RRDtool.</p>
</div>

<div align="center">

[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Cloudron community app](https://img.shields.io/badge/Cloudron-community%20app-3aa7e7.svg)](https://forum.cloudron.io/category/community-apps)

</div>

## About this package

This repository contains only the Cloudron packaging files for SmokePing. The SmokePing source is downloaded from [oetiker/SmokePing](https://github.com/oetiker/SmokePing) at image-build time, pinned to a known release via the `SMOKEPING_VERSION` build arg (kept current automatically by Renovate).

The upstream SmokePing project is the authoritative source for the daemon, probes, and web UI; this repo provides the Dockerfile, nginx config, supervisor unit files, default configuration, and the operator-facing glue needed to run cleanly on Cloudron.

- Upstream: [oetiker/SmokePing](https://github.com/oetiker/SmokePing) — GPL-2.0
- Packaging: [pronetivity/cloudron-smokeping](https://github.com/pronetivity/cloudron-smokeping) — GPL-2.0
- Container image: `ghcr.io/pronetivity/cloudron-smokeping` (public on GHCR; no registry credentials needed)

## Features

- ICMP, DNS, HTTP, SSH and 40+ other probe types — see [SmokePing probes](https://oss.oetiker.ch/smokeping/probe/index.en.html).
- ~80 default monitoring targets covering DNS resolvers, all 13 root servers, social networks, dev tools, and cloud providers.
- 10 pre-configured alert rules for packet loss, latency spikes, and flapping.
- HTTP basic auth with auto-generated credentials at `/app/data/htpasswd.txt`; overridable via `/app/data/.env`.
- Email alerts via the Cloudron `sendmail` addon. Surface-test with `/app/pkg/test-email.sh`.
- Split configuration files under `/app/data/config/` (General, Database, Alerts, Presentation, Probes, Targets). Deleting a file restores its default on next restart.
- Health check endpoint at `/healthz`.
- SVG graph format.

## Installing on a Cloudron

The catalog URL is:

```
https://raw.githubusercontent.com/pronetivity/cloudron-smokeping/master/CloudronVersions.json
```

### From the dashboard

1. Cloudron dashboard → **Settings → App Store → Add custom app**.
2. Paste the catalog URL above.
3. Click **Install** on SmokePing, pick a subdomain, confirm.

### From the CLI

```bash
cloudron install --server my.example.com \
                 --versions-url https://raw.githubusercontent.com/pronetivity/cloudron-smokeping/master/CloudronVersions.json \
                 --location smokeping.example.com
```

Either way, new versions appear in your Cloudron's update notifications automatically as they land in the catalog.

See [`PUBLISHING.md`](./PUBLISHING.md) for the other install paths (`--image`, server-side build) and the release workflow.

## First login

Right after install, retrieve the auto-generated basic-auth credentials via the [Web Terminal](https://docs.cloudron.io/apps/#web-terminal):

```bash
cat /app/data/htpasswd.txt
```

To set your own credentials instead, edit `/app/data/.env`:

```bash
SMOKEPING_ADMIN_USER=admin
SMOKEPING_ADMIN_PASS=your-password
```

Restart the app to apply.

## Configuration

All operator-facing knobs live in `/app/data/.env`. The two most important ones:

```bash
TZ=Europe/Berlin                                  # graph timestamps
SMOKEPING_ALERT_TO=admin@example.com,ops@example.com   # email alert recipients
SMOKEPING_OWNER=My Company                        # shown in the UI footer
```

Restart the app for changes to take effect. For deeper customization, edit the split config files under `/app/data/config/` (`General`, `Database`, `Alerts`, `Presentation`, `Probes`, `Targets`). Deleting any of them restores the bundled default on the next restart.

## Testing email delivery

```bash
/app/pkg/test-email.sh your@email.com
```

The test message includes the container hostname, the Cloudron app domain, and the Cloudron host so alert-delivery diagnostics are unambiguous.

## Development

Local container build (no Cloudron required):

```bash
docker build -t cloudron-smokeping:dev .
```

Test against a Cloudron, building on the server (no GHCR pull):

```bash
cloudron install --server my.example.com --location smokeping.example.com
cloudron update  --server my.example.com --app smokeping.example.com
```

## Releasing

`node scripts/release.js <patch | minor | major | X.Y.Z>` does the whole bump — `CloudronManifest.json`, `CHANGELOG.md`, the per-version `CHANGELOG` snippet, the commit, and the annotated tag. Push the commit and the tag and CI takes over: builds the image, pushes to GHCR, opens a GitHub Release, runs `cloudron versions add`, and commits the updated `CloudronVersions.json` back to `master`.

Full details in [`VERSIONING.md`](./VERSIONING.md) and [`PUBLISHING.md`](./PUBLISHING.md).

## Reporting bugs

For issues with the **Cloudron packaging** (install, config-defaults, nginx, supervisor, env handling, alerting glue), open an issue here: [pronetivity/cloudron-smokeping/issues](https://github.com/pronetivity/cloudron-smokeping/issues).

For issues with **SmokePing itself** (probes, RRD storage, the web UI), open an issue upstream: [oetiker/SmokePing/issues](https://github.com/oetiker/SmokePing/issues).

## License

GPL-2.0. See the upstream [SmokePing COPYING](https://github.com/oetiker/SmokePing/blob/master/COPYING) for the underlying daemon's license. Packaging contributions in this repository are © 2026 ProNetivity Inc., released under the same GPL-2.0 license.
