# Publishing

How releases of `pronetivity/cloudron-smokeping` are cut, built, and shipped to a Cloudron.

For the version-bump mechanics (SemVer rules, changelog format, release script), see [VERSIONING.md](./VERSIONING.md). This document covers the *publishing* steps that happen *after* a release is tagged.

## Where things are published

| Artifact | Location |
|---|---|
| Source | `pronetivity/cloudron-smokeping` on GitHub |
| Container image | `ghcr.io/pronetivity/cloudron-smokeping` on GHCR |
| Image tags | `:vX.Y.Z` (every release tag), `:latest` (latest release tag), `:edge` (every `main` push) |
| App id | `org.smokeping.cloudronapp` (Cloudron-side identity; immutable per install) |
| Community-app catalog | `CloudronVersions.json` at the repo root, served via `https://raw.githubusercontent.com/pronetivity/cloudron-smokeping/master/CloudronVersions.json` |

The image registry comes from `${{ github.repository_owner }}` in the workflow, so wherever the repo is hosted is where the image is pushed. No literal organization name is hard-coded in the build.

## End-to-end release flow

1. **Add notes**. While work is in flight, append entries under `## [Unreleased]` in `CHANGELOG.md`.
2. **Cut the release**. `node scripts/release.js patch | minor | major | X.Y.Z` — this bumps `CloudronManifest.json#version`, renames `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD`, regenerates `./CHANGELOG`, commits everything as `vX.Y.Z`, and creates the annotated tag. See [VERSIONING.md](./VERSIONING.md#cutting-a-release).
3. **Push**. `git push origin master && git push origin vX.Y.Z`.
4. **CI builds + publishes + catalogs**. The `Build Cloudron image` workflow (`.github/workflows/cloudron-image.yml`) fires on the tag push and does five things automatically:
   - builds the `Dockerfile` and pushes `ghcr.io/pronetivity/cloudron-smokeping:vX.Y.Z` + `:latest` to GHCR;
   - extracts the matching `## [X.Y.Z]` section from `CHANGELOG.md`;
   - creates a GitHub Release named `vX.Y.Z` with that section as the body, plus a "Cloudron install" snippet and the image digest. Tags containing a `-` (e.g. `v2.9.0-1`) are flagged as pre-releases automatically;
   - installs the Cloudron CLI and runs `cloudron versions add --state published` to insert the new version into `CloudronVersions.json`;
   - commits the updated `CloudronVersions.json` back to `main` as `chore: catalogs vX.Y.Z in CloudronVersions.json [skip ci]`.

   Watch the run at `https://github.com/pronetivity/cloudron-smokeping/actions`. The Release shows up at `https://github.com/pronetivity/cloudron-smokeping/releases`.
5. **Verify image** (optional). `docker pull ghcr.io/pronetivity/cloudron-smokeping:vX.Y.Z` from any machine. The image is public by default once the GitHub package visibility is set to public — go to the package settings on GitHub and switch it once after the first publish.

## Community-app catalog (`CloudronVersions.json`)

Cloudron treats this file as the source-of-truth feed for the community app. Users add the raw URL (see the [Where things are published](#where-things-are-published) table) under **Settings → App Store → Add custom app** in their dashboard, or pass `--versions-url <url>` to `cloudron install`. Every entry under `versions` becomes an installable version; new entries trigger update notifications on existing installs.

### File shape (managed automatically)

```json
{
  "stable": true,
  "versions": {
    "2.9.0": {
      "manifest": { ... full CloudronManifest.json ... },
      "creationDate": "...",
      "ts": "...",
      "publishState": "published"
    }
  }
}
```

Do not edit this by hand — `cloudron versions add` (invoked by CI) writes it and embeds the manifest content from disk. The `changelog` field of the manifest is filled from the `./CHANGELOG` file, which `scripts/release.js` regenerates from the `## [X.Y.Z]` section of `CHANGELOG.md` during the release commit.

### Manual catalog (only if CI is unavailable)

```bash
git checkout vX.Y.Z
# Record the image so `cloudron versions add` picks it up.
node -e "const fs=require('fs'),p=require('path'),h=p.join(process.env.HOME,'.cloudron.json');let c={};try{c=JSON.parse(fs.readFileSync(h))}catch(_){};c.apps=c.apps||{};c.apps[process.cwd()]={repository:'ghcr.io/pronetivity/cloudron-smokeping',dockerImage:'ghcr.io/pronetivity/cloudron-smokeping:vX.Y.Z'};fs.writeFileSync(h,JSON.stringify(c,null,4))"
cloudron versions add --state published
git add CloudronVersions.json
git commit -m "chore: catalogs vX.Y.Z in CloudronVersions.json"
git push origin master
```

### Revoking or updating a published version

A bad release can be pulled with `cloudron versions revoke` (latest only). Users who haven't picked it up yet won't see it; users who already installed it are unaffected. Bump and ship a fix instead of editing a published entry — `cloudron versions update --version X.Y.Z --state published|testing` is for state changes only, not for changing the manifest or image of a version users may already have.

## Installing on a Cloudron

Three paths. The `--versions-url` path is what end users follow once the catalog is published; the others are for developers/testers.

### A) `--versions-url` (end-user path; community-app catalog)

```bash
cloudron install --server my.example.com \
                 --versions-url https://raw.githubusercontent.com/pronetivity/cloudron-smokeping/master/CloudronVersions.json \
                 --location smokeping.example.com
```

Or from the dashboard: **Settings → App Store → Add custom app** and paste the same URL. Cloudron then surfaces every entry in `CloudronVersions.json` as an installable version and notifies the user about updates automatically.

### B) `--image` (developer path; pin a specific GHCR image)

```bash
cloudron install --server my.example.com \
                 --image  ghcr.io/pronetivity/cloudron-smokeping:vX.Y.Z \
                 --location smokeping.example.com
```

Update an existing install:

```bash
cloudron update  --server my.example.com \
                 --app    smokeping.example.com \
                 --image  ghcr.io/pronetivity/cloudron-smokeping:vX.Y.Z
```

For a private GHCR image, configure the registry credentials on the Cloudron once: `cloudron registry add ghcr.io ...`.

### C) Server-side build (no registry needed; for testing uncommitted changes)

Run from the repo root, which contains `CloudronManifest.json` and `Dockerfile`:

```bash
cloudron install --server my.example.com --location smokeping.example.com
cloudron update  --server my.example.com --app smokeping.example.com
```

The CLI uploads the working tree, the Cloudron server runs `docker build`, then deploys. Slower than `--image`, and the resulting install does not appear in any catalog.

## Announcing the app to the community

After the first version is in `CloudronVersions.json` and at least one screenshot is in `mediaLinks`:

1. Confirm a clean machine can `docker pull ghcr.io/pronetivity/cloudron-smokeping:vX.Y.Z` (image visibility is public) and a fresh Cloudron can install via path A above.
2. Post in the Cloudron forum's [Community Apps thread](https://forum.cloudron.io/topic/15172/community-apps) with:
   - the `CloudronVersions.json` URL (path A install line),
   - the repo URL,
   - a one-line description of what's new.

Subsequent releases happen via the automated catalog flow; the forum announcement is a one-time bootstrap.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Invalid CloudronManifest.json: must NOT have additional properties` | Manifest contains a field not in the Cloudron schema. Validate locally with `node --input-type=module -e "import mf from '@cloudron/manifest-format'; console.log(mf.default.parse(JSON.parse(require('fs').readFileSync('CloudronManifest.json'))))"`. |
| `Version latest not found` in the Add Community App dialog | `CloudronVersions.json` has an empty `versions` map. Either CI hasn't run yet for any tag, or all entries were revoked. |
| GH Action push step fails with `403 / denied` | The repo's GitHub Actions need `packages: write` permission and the package may need to be set public in the package settings UI after the first publish. |
| `cloudron install` complains about Dockerfile / manifest not found | Run from the repo root. Both files must be at the same directory as the working dir. |
| Image builds locally but install hangs at `Building image` on the server | Check `cloudron logs --server <host> --app <location>` and `cloudron logs --build` for the build output. |
