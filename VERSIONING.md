# Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) and maintains a [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) `CHANGELOG.md`.

## Version scheme

`MAJOR.MINOR.PATCH`:

- **PATCH** — backwards-compatible packaging fixes (`Fixed`, `Security`, small `Changed`).
- **MINOR** — new packaging features or visible behavior changes (`Added`, `Changed`, `Deprecated`).
- **MAJOR** — breaking changes to the manifest id, persistent layout under `/app/data/`, or required Cloudron platform version.

The version tracks the packaging itself, not the upstream SmokePing version (the upstream version is pinned inside the `Dockerfile` via the `SMOKEPING_VERSION` build arg, kept current by Renovate). It happens to start aligned at `2.9.0` because that was the upstream release this packaging shipped against; future packaging-only fixes bump the patch component independently.

## Single source of truth

`CloudronManifest.json#version` is the source. The per-version `./CHANGELOG` snippet (referenced by the manifest as `file://CHANGELOG`) is regenerated from the matching `## [X.Y.Z]` section of `CHANGELOG.md` on every release — never edit it by hand.

`scripts/release.js` does the bookkeeping in one shot.

Tags use the form `vMAJOR.MINOR.PATCH` (e.g. `v2.9.0`).

## Day-to-day: as work lands

Every user-visible change picks up an entry under the `## [Unreleased]` section of `CHANGELOG.md`, in the appropriate category (`Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security`). Internal refactors and chores do not need an entry.

## Cutting a release

```
node scripts/release.js patch        # 2.9.0 -> 2.9.1
node scripts/release.js minor        # 2.9.0 -> 2.10.0
node scripts/release.js major        # 2.9.0 -> 3.0.0
node scripts/release.js 2.9.5        # exact bump
```

What the script does:

1. Bumps `CloudronManifest.json#version`.
2. Renames `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` in `CHANGELOG.md`, seeds a fresh `[Unreleased]` above it, and rewrites the compare links at the bottom.
3. Regenerates `./CHANGELOG` from the new `[X.Y.Z]` section.
4. Stages the three files, commits as `vX.Y.Z`, and creates the annotated tag.

Then push:

```
git push origin master && git push origin vX.Y.Z
```

The GitHub Actions workflow takes over from there — see [PUBLISHING.md](./PUBLISHING.md).

## When to also bump SMOKEPING_VERSION

A new upstream SmokePing release (e.g. 2.10.0) means:

1. Update the `SMOKEPING_VERSION` build arg in `Dockerfile` (Renovate may PR this automatically).
2. Test locally (`cloudron build && cloudron install`).
3. Cut a packaging version that reflects the upstream bump:
   - Upstream major or minor change → packaging minor bump (e.g. `2.9.x` → `2.10.0`).
   - Upstream patch with no packaging-side change → packaging patch bump (e.g. `2.9.0` → `2.9.1`).

The packaging version and the upstream SmokePing version are independent — Renovate-driven `SMOKEPING_VERSION` bumps still need a manual `scripts/release.js` to ship.
