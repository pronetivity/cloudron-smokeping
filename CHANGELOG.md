# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).
See [VERSIONING.md](./VERSIONING.md) for the release workflow.

Change categories: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## [Unreleased]

## [2.9.1] - 2026-05-13

### Fixed
- CI workflow now fires on `v*` tag pushes. The previous `paths:` filter on the `push:` trigger silently swallowed tag events when the tagged commit was already reachable on `master`. Branch push triggers run unconditionally now; PR triggers keep their path filter.

## [2.9.0] - 2026-05-13

### Added
- Initial Cloudron packaging of SmokePing 2.9.0.
- Nginx with FastCGI and HTTP basic auth. Credentials are auto-generated on first install at `/app/data/htpasswd.txt` and can be overridden via `SMOKEPING_ADMIN_USER` / `SMOKEPING_ADMIN_PASS` in `/app/data/.env`.
- Email alerts via the Cloudron `sendmail` addon, surface-tested via the bundled `test-email.sh` helper.
- Split configuration files under `/app/data/config/` (`General`, `Database`, `Alerts`, `Presentation`, `Probes`, `Targets`); deleting a file restores its default on next restart.
- Health check endpoint at `/healthz`.
- SVG graph format support.
- ~80 pre-configured probe targets covering DNS resolvers, all 13 root servers, social networks, dev tools, and cloud providers.
- Cloudron community-app metadata: `iconUrl`, `mediaLinks`, `packagerName`, `packagerUrl`, `upstreamLicense` (GPL-2.0).
- `scripts/release.js` one-command release tool that bumps `CloudronManifest.json#version`, rewrites `CHANGELOG.md`, regenerates the per-version `./CHANGELOG` snippet, commits, and tags.
- `.github/workflows/cloudron-image.yml` — on `v*` tag push, builds the Cloudron image, pushes `ghcr.io/<owner>/cloudron-smokeping:vX.Y.Z` + `:latest`, creates a GitHub Release with the matching changelog body, runs `cloudron versions add`, and commits the updated `CloudronVersions.json` back to `main`.
- `VERSIONING.md` and `PUBLISHING.md` documenting the release and community-app catalog flows.

[Unreleased]: https://github.com/pronetivity/cloudron-smokeping/compare/v2.9.1...HEAD
[2.9.1]: https://github.com/pronetivity/cloudron-smokeping/compare/v2.9.0...v2.9.1
[2.9.0]: https://github.com/pronetivity/cloudron-smokeping/releases/tag/v2.9.0
