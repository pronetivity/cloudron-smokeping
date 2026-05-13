#!/usr/bin/env node
'use strict';

// One-command release for this Cloudron community app. CloudronManifest.json
// is the source of truth for the version. This script:
//   1. validates the version arg,
//   2. bumps CloudronManifest.json#version,
//   3. renames CHANGELOG.md's [Unreleased] heading to [X.Y.Z] - YYYY-MM-DD,
//      seeds a fresh [Unreleased] above it, appends the compare link,
//   4. regenerates the per-version ./CHANGELOG snippet that the manifest's
//      `changelog: "file://CHANGELOG"` field references at publish time,
//   5. stages the three files,
//   6. creates the release commit ("vX.Y.Z") and the annotated tag.
//
// You still push manually: `git push origin main && git push origin vX.Y.Z`.

const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const repoRoot = path.resolve(__dirname, '..');
const manifestPath = path.join(repoRoot, 'CloudronManifest.json');
const changelogPath = path.join(repoRoot, 'CHANGELOG.md');
const snippetPath = path.join(repoRoot, 'CHANGELOG');

function git(args) {
  execFileSync('git', args, { cwd: repoRoot, stdio: 'inherit' });
}

const arg = process.argv[2];
if (!arg) {
  console.error('usage: scripts/release.js <X.Y.Z | patch | minor | major>');
  process.exit(1);
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const current = manifest.version;

function bumpKind(kind, cur) {
  const [maj, min, pat] = cur.split('.').map(Number);
  if (kind === 'patch') return `${maj}.${min}.${pat + 1}`;
  if (kind === 'minor') return `${maj}.${min + 1}.0`;
  if (kind === 'major') return `${maj + 1}.0.0`;
  return null;
}

const next = ['patch', 'minor', 'major'].includes(arg) ? bumpKind(arg, current) : arg;
if (!/^[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?$/.test(next)) {
  console.error(`invalid version "${next}"`);
  process.exit(1);
}
if (next === current) {
  console.error(`already at ${current}`);
  process.exit(1);
}

console.log(`releasing ${current} -> ${next}`);

// 1. Manifest version bump.
manifest.version = next;
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
console.log(`  CloudronManifest.json -> ${next}`);

// 2. CHANGELOG.md rename.
const today = new Date().toISOString().slice(0, 10);
let changelog = fs.readFileSync(changelogPath, 'utf8');

const unreleasedHeading = '## [Unreleased]';
if (!changelog.includes(unreleasedHeading)) {
  console.error(`CHANGELOG.md has no "${unreleasedHeading}" section to rename.`);
  process.exit(1);
}
if (changelog.includes(`## [${next}]`)) {
  console.error(`CHANGELOG.md already has a [${next}] section.`);
  process.exit(1);
}

changelog = changelog.replace(
  unreleasedHeading,
  `${unreleasedHeading}\n\n## [${next}] - ${today}`
);

// Update compare links at the bottom.
const repoUrl = 'https://github.com/pronetivity/cloudron-smokeping';
const unreleasedLink = new RegExp(`^\\[Unreleased\\]: ${repoUrl}/compare/v[^\\s]+\\.\\.\\.HEAD$`, 'm');
const newUnreleasedLink = `[Unreleased]: ${repoUrl}/compare/v${next}...HEAD`;
const newVersionLink = `[${next}]: ${repoUrl}/compare/v${current}...v${next}`;

if (unreleasedLink.test(changelog)) {
  changelog = changelog.replace(unreleasedLink, `${newUnreleasedLink}\n${newVersionLink}`);
} else {
  changelog = changelog.replace(/\n+$/, '') + `\n\n${newUnreleasedLink}\n${newVersionLink}\n`;
}

fs.writeFileSync(changelogPath, changelog);
console.log(`  CHANGELOG.md  -> [Unreleased] renamed to [${next}] - ${today}`);

// 3. Regenerate ./CHANGELOG snippet for the new version section.
const lines = changelog.split('\n');
const startIdx = lines.findIndex((l) => l.startsWith(`## [${next}]`));
const slice = [`[${next}]`];
for (let i = startIdx + 1; i < lines.length; i++) {
  if (lines[i].startsWith('## [')) break;
  slice.push(lines[i]);
}
while (slice.length > 1 && slice[1].trim() === '') slice.splice(1, 1);
while (slice[slice.length - 1].trim() === '') slice.pop();
fs.writeFileSync(snippetPath, slice.join('\n') + '\n');
console.log(`  CHANGELOG     <- per-version snippet for ${next}`);

// 4. Stage, commit, tag (no shell interpolation; args are arrays).
git(['add', 'CloudronManifest.json', 'CHANGELOG.md', 'CHANGELOG']);
git(['commit', '-m', `v${next}`]);
git(['tag', '-a', `v${next}`, '-m', `v${next}`]);

console.log(`\nReady. Next: git push origin main && git push origin v${next}`);
