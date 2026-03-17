# SmokePing Cloudron Package

Cloudron packaging for [SmokePing](https://oss.oetiker.ch/smokeping/) — a latency logging, graphing, and alerting system.

## Overview

This repo contains only the Cloudron packaging files. SmokePing source is downloaded from [oetiker/SmokePing](https://github.com/oetiker/SmokePing) at build time.

## Features

- ICMP, DNS, and HTTP probe types pre-configured
- ~80 default monitoring targets (DNS resolvers, root servers, social networks, dev tools, cloud providers)
- 10 alert rules for loss, latency, spikes, and flapping
- HTTP basic auth with auto-generated credentials
- Email alerts via Cloudron's mail system
- All settings configurable via `/app/data/.env`
- Split config files with auto-restore on deletion

## Building

```bash
cloudron build
cloudron install
```

## Configuration

After install, edit `/app/data/.env` via the [Web Terminal](https://docs.cloudron.io/apps/#web-terminal):

```bash
TZ=Europe/Berlin
SMOKEPING_ALERT_TO=admin@example.com
SMOKEPING_OWNER=My Company
```

Restart the app for changes to take effect.

For advanced configuration, edit the split config files in `/app/data/config/`.

## Testing Email

```bash
/app/pkg/test-email.sh your@email.com
```

## Source

- **SmokePing**: https://github.com/oetiker/SmokePing
- **License**: GPL-2.0 (SmokePing upstream)
- **Packager**: [ProNetivity Inc.](https://pronetivity.ph)
