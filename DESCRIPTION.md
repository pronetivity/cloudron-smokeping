SmokePing is a latency logging and graphing and alerting system. It consists of a daemon process which organizes the latency measurements and a web interface which presents the graphs.

### Features

- **Multi-Protocol Monitoring** — ICMP, DNS, HTTP, SSH, and 40+ probe types
- **RRDtool Graphs** — SVG graphs showing latency distribution, packet loss, and trends
- **Alerting** — 10 pre-defined alert rules for loss, latency spikes, and flapping
- **Charts** — Default landing page shows top packet loss across all targets

### Cloudron Extras

- ~80 pre-configured targets: DNS resolvers, all 13 root servers, social networks, dev tools, cloud providers
- Email alerts via Cloudron mail, HTTP basic auth with auto-generated credentials
- All settings configurable via `/app/data/.env` — no config file editing required
- Split config files under `/app/data/config/` for advanced customization
