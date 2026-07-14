#!/usr/bin/env node
// Zero-dependency validator. HTML-centric checks are the swappable layer if a
// future project uses a framework; --memory mode is stack-agnostic.
//
// Usage:
//   node scripts/validate.mjs --src <file.html> [...more]   syntax/conflict/anchor/marker checks
//   node scripts/validate.mjs --memory                      lint .claude/memory/ against code
//   node scripts/validate.mjs --all                         both (all src/routes/*/index.html or ./index.html)
//
// Exit codes: 0 clean · 1 validation failures (all listed, not first-only) · 2 usage/IO error
import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import vm from 'node:vm';
import { scanSkills, alwaysOnFromGitignore, ACTIVE_DIR, STORE_DIR } from './lib/skill-meta.mjs';

const failures = [];
const fail = (file, line, rule, detail) => failures.push(`${file}:${line}: ${rule}: ${detail}`);
// warnings are non-fatal: printed, but exit stays 0 (used for smells, not errors)
const warnings = [];
const warn = (file, rule, detail) => warnings.push(`${file}: ${rule}: ${detail}`);

// ── HTML file checks ─────────────────────────────────────────────────────────
function checkHtml(file) {
  if (!existsSync(file)) { console.error(`IO: no such file: ${file}`); process.exit(2); }
  const text = readFileSync(file, 'utf8');
  const lines = text.split('\n');

  // 1. inline <script> blocks parse
  const re = /<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g;
  let m, idx = 0;
  while ((m = re.exec(text))) {
    idx++;
    try { new vm.Script(m[1]); }
    catch (e) {
      const line = text.slice(0, m.index).split('\n').length;
      fail(file, line, 'js-syntax', `inline script #${idx}: ${e.message}`);
    }
  }

  // 2. git conflict markers
  lines.forEach((l, i) => {
    if (/^(<{7}|={7}|>{7})( |$)/.test(l)) fail(file, i + 1, 'conflict-marker', l.slice(0, 40));
  });

  // 3. anchor uniqueness (per file)
  const seen = new Map();
  lines.forEach((l, i) => {
    for (const a of l.matchAll(/@(?:sec|css|js|end):[a-z0-9-]+/g)) {
      if (seen.has(a[0])) fail(file, i + 1, 'anchor-dup', `${a[0]} (first at line ${seen.get(a[0])})`);
      else seen.set(a[0], i + 1);
    }
  });

  // 3b. anchor naming convention: lowercase prefix, kebab-case name, ≤3 words
  lines.forEach((l, i) => {
    for (const a of l.matchAll(/@(sec|css|js|end):([A-Za-z0-9_-]+)/gi)) {
      if (a[1] !== a[1].toLowerCase())
        fail(file, i + 1, 'anchor-name', `prefix must be lowercase: @${a[1]}:${a[2]}`);
      if (!/^[a-z0-9]+(-[a-z0-9]+){0,2}$/.test(a[2]))
        fail(file, i + 1, 'anchor-name', `name must be kebab-case, ≤3 words: @${a[1]}:${a[2]}`);
    }
  });

  // 3c. every @end:name must pair with a @sec:name in the same file
  const secNames = new Set();
  for (const a of seen.keys()) if (a.startsWith('@sec:')) secNames.add(a.slice(5));
  for (const [a, line] of seen)
    if (a.startsWith('@end:') && !secNames.has(a.slice(5)))
      fail(file, line, 'end-orphan', `${a} has no matching @sec:${a.slice(5)}`);

  // 4. build markers resolve (relative to the file's directory)
  lines.forEach((l, i) => {
    for (const mk of l.matchAll(/@(asset|inline):([^\s"')>]+)/g)) {
      const p = resolve(dirname(file), mk[2]);
      if (!existsSync(p)) fail(file, i + 1, `marker-${mk[1]}`, `unresolved: ${mk[2]}`);
    }
  });
  return seen; // anchors found, for --memory cross-check reuse
}

// ── Memory lint (stack-agnostic) ─────────────────────────────────────────────
const CAPS = { 'INDEX.md': 60, route: 100, shared: 80, sessionLog: 40, spec: 120, glossary: 80 };
// semantic caps from checkpoint/references/map-format.md — line caps alone
// don't stop a cheap model from stuffing 20 decisions into a route map
const SEM = { globalGotchas: 8, decisions: 10, routeGotchas: 10 };

function lineCount(p) { return readFileSync(p, 'utf8').split('\n').filter(l => l.trim() !== '').length; }

// text of one `## Heading` block (up to the next `## ` or EOF); '' if absent
function mdBlock(text, heading) {
  const i = text.indexOf(heading);
  if (i === -1) return '';
  const rest = text.slice(i + heading.length);
  const j = rest.search(/^## /m);
  return j === -1 ? rest : rest.slice(0, j);
}
const bulletCount = t => t.split('\n').filter(l => /^- /.test(l.trim())).length;

// deepRoutes: null = verify every route's anchors against code (full/--deep);
// an array of route identifiers = only walk those routes' code (scoped run).
// Cheap shape/cap checks always run for ALL routes — those read only small .md.
function checkMemory(memDir = '.claude/memory', deepRoutes = null) {
  const indexPath = join(memDir, 'INDEX.md');
  if (!existsSync(indexPath)) { console.error(`IO: ${indexPath} missing — nothing to lint`); process.exit(2); }
  const index = readFileSync(indexPath, 'utf8');

  if (lineCount(indexPath) > CAPS['INDEX.md'])
    fail(indexPath, 0, 'cap', `>${CAPS['INDEX.md']} non-empty lines`);
  if (!/^state: (starter|in-progress)$/m.test(index))
    fail(indexPath, 0, 'shape', 'missing "state: starter|in-progress" line');
  for (const h of ['## Routes', '## Shared registries', '## Global gotchas'])
    if (!index.includes(h)) fail(indexPath, 0, 'shape', `missing heading "${h}"`);

  const gg = bulletCount(mdBlock(index, '## Global gotchas'));
  if (gg > SEM.globalGotchas)
    fail(indexPath, 0, 'cap-gotchas', `${gg} global gotchas (max ${SEM.globalGotchas})`);

  // shared registry: a row whose used-by lists only ONE route is a "shared by
  // default" smell — flag it (warning, not failure: transient during bootstrap)
  for (const l of mdBlock(index, '## Shared registries').split('\n')) {
    const c = l.split('|').map(s => s.trim());
    if (c.length >= 4 && c[1] && c[1] !== 'id' && !/^-+$/.test(c[1])) {
      const users = c[3].split(',').map(s => s.trim()).filter(Boolean);
      if (users.length === 1) warn(indexPath, 'shared-solo', `registry "${c[1]}" used by only ${users[0]} — not shared yet; keep it route-local until a 2nd route needs it`);
    }
  }

  // route table rows: | route | path | status | map | design | data-deps |
  const rows = [...index.matchAll(/^\|\s*(\/[^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|/gm)]
    .map(r => r.map(c => (c || '').trim()));
  // empty table is fine on a fresh scaffold — but real routes on disk must be registered
  if (!rows.length && existsSync('src/routes')) {
    const real = readdirSync('src/routes').filter(r => !r.startsWith('_') && !r.startsWith('.')
      && existsSync(join('src/routes', r, 'index.html')));
    if (real.length) fail(indexPath, 0, 'shape', `routes on disk but not in INDEX: ${real.join(', ')}`);
  }

  for (const [, route, path, , map] of rows) {
    if (map && map !== '—' && !map.startsWith('— ')) {
      const mapPath = join(memDir, map);
      if (!existsSync(mapPath)) { fail(indexPath, 0, 'map-missing', `${route} → ${map}`); continue; }
      if (lineCount(mapPath) > CAPS.route) fail(mapPath, 0, 'cap', `>${CAPS.route} non-empty lines`);
      const mapText = readFileSync(mapPath, 'utf8');
      // canonical route-map shape (F3) — checkpoint/references/map-format.md
      // §"Required section order". Enforced at build time so a wrong-shaped map
      // can't validate clean and get silently rewritten later at /checkpoint.
      if (!/^# \/\S/m.test(mapText)) fail(mapPath, 0, 'shape', 'missing "# /<route> — …" header line');
      if (!/^uses:/m.test(mapText)) fail(mapPath, 0, 'shape', 'missing "uses:" pointer line');
      for (const h of ['## Sections', '## Hot elements', '## Priorities', '## Recent decisions'])
        if (!mapText.includes(h)) fail(mapPath, 0, 'shape', `missing heading "${h}"`);
      const secBlock = mdBlock(mapText, '## Sections');
      if (secBlock && !/\|\s*section\s*\|\s*anchor/i.test(secBlock))
        fail(mapPath, 0, 'shape', 'Sections table needs a "| section | anchor(s) | gotcha |" header row');

      const dec = bulletCount(mdBlock(mapText, '## Recent decisions'));
      if (dec > SEM.decisions)
        fail(mapPath, 0, 'cap-decisions', `${dec} recent decisions (max ${SEM.decisions})`);
      // route gotchas = non-empty Sections gotcha cells + bullets in a Gotchas block
      let rg = bulletCount(mdBlock(mapText, '## Gotchas'));
      for (const l of mdBlock(mapText, '## Sections').split('\n')) {
        const c = l.split('|').map(s => s.trim());
        if (c.length >= 5 && c[3] && c[3] !== 'gotcha' && c[3] !== '—' && !/^-+$/.test(c[3])) rg++;
      }
      if (rg > SEM.routeGotchas)
        fail(mapPath, 0, 'cap-gotchas', `${rg} route gotchas (max ${SEM.routeGotchas})`);
      // every anchor named in the map must resolve in the route's code — this
      // is the expensive part (reads the route's source), so scope it: a scoped
      // run only walks routes in deepRoutes; shape/cap above already ran for all
      const codePath = path.trim();
      const isDeep = !deepRoutes || deepRoutes.some(id => codePath.includes(id));
      const anchors = [...new Set([...mapText.matchAll(/@(?:sec|css|js):[a-z0-9-]+/g)].map(a => a[0]))];
      if (anchors.length && isDeep) {
        let code = '';
        if (existsSync(codePath) && statSync(codePath).isFile()) code = readFileSync(codePath, 'utf8');
        else if (existsSync(codePath) && statSync(codePath).isDirectory()) {
          const walk = d => readdirSync(d).flatMap(f => {
            const p = join(d, f);
            return statSync(p).isDirectory() ? walk(p) : /\.(html|css|js|mjs)$/.test(f) ? [readFileSync(p, 'utf8')] : [];
          });
          code = walk(codePath).join('\n');
        } else { fail(mapPath, 0, 'path-missing', `route path not found: ${codePath}`); continue; }
        for (const a of anchors) if (!code.includes(a)) fail(mapPath, 0, 'anchor-dead', `${a} not found in ${codePath}`);
      }
    }
  }

  // shared file caps
  const sharedDir = join(memDir, 'shared');
  if (existsSync(sharedDir)) for (const f of readdirSync(sharedDir))
    if (f.endsWith('.md') && lineCount(join(sharedDir, f)) > CAPS.shared)
      fail(join(sharedDir, f), 0, 'cap', `>${CAPS.shared} non-empty lines`);

  // session log cap (optional file)
  const sessionLog = join(memDir, 'SESSION-LOG.md');
  if (existsSync(sessionLog) && lineCount(sessionLog) > CAPS.sessionLog)
    fail(sessionLog, 0, 'cap', `>${CAPS.sessionLog} non-empty lines`);

  // SPEC.md cap (optional file, written by the `spec` skill — free-form, no shape check)
  const specFile = join(memDir, 'SPEC.md');
  if (existsSync(specFile) && lineCount(specFile) > CAPS.spec)
    fail(specFile, 0, 'cap', `>${CAPS.spec} non-empty lines`);

  // CONTEXT.md cap (optional file, written by the `domain-modeling` skill — free-form, no shape check)
  const contextFile = join(memDir, 'CONTEXT.md');
  if (existsSync(contextFile) && lineCount(contextFile) > CAPS.glossary)
    fail(contextFile, 0, 'cap', `>${CAPS.glossary} non-empty lines`);
}

// ── Skill loadout lint (v3 model) ─────────────────────────────────────────────
// Metadata lives in each skill's SKILL.md frontmatter (name, description,
// optional group, optional exclusive-with); state = folder location.
// "Always-on" is defined solely by the .gitignore whitelist — no policy field,
// no generated index file.
function checkSkills() {
  const skills = scanSkills();

  // 1. frontmatter completeness (name + description on every skill)
  for (const s of skills) {
    const p = join(s.state === 'active' ? ACTIVE_DIR : STORE_DIR, s.dir, 'SKILL.md');
    if (s.error) { fail(p, 0, 'frontmatter', s.error); continue; }
    if (!s.description) fail(p, 0, 'description', 'missing description in frontmatter');
  }

  // (No dup-across-shelves check: activation copies store→active by design, so a
  //  loaded skill legitimately sits on both shelves; scanSkills shadows it to one.)

  // 2. every .gitignore-whitelisted always-on skill must actually be active
  const alwaysOn = alwaysOnFromGitignore();
  for (const name of alwaysOn) {
    const s = skills.find(x => x.name === name);
    if (!s) fail('skills', 0, 'always-on', `"${name}" is whitelisted in .gitignore but missing from .claude/skills/`);
    else if (s.state !== 'active') fail('skills', 0, 'always-on', `"${name}" is whitelisted in .gitignore but found ${s.state} — dormant means it never fires`);
  }

  // 3. a dormant skill should not ALSO be whitelisted as always-on (contradiction
  //    already covered by #2; this catches a store master left behind for a
  //    promoted skill, which is harmless but worth flagging as a smell)
  for (const s of skills) {
    if (s.state === 'dormant' && alwaysOn.includes(s.name))
      warn('skills', 'always-on-has-store-master', `"${s.name}" is always-on but still has a store master — fine, but redundant`);
  }

  // 4. exclusive-with symmetry (only checkable among installed skills)
  for (const s of skills) for (const peer of s.exclusive) {
    const p = skills.find(x => x.name === peer);
    if (p && !p.exclusive.includes(s.name))
      fail('skills', 0, 'exclusive-asym', `${s.name} lists exclusive-with ${peer}, but ${peer} does not reciprocate`);
  }

  // 5. LOCK.md (optional third-party pins): cap only
  const lock = '.claude/skills-store/LOCK.md';
  if (existsSync(lock) && lineCount(lock) > 60) fail(lock, 0, 'cap', '>60 non-empty lines');
}

// ── CLI ──────────────────────────────────────────────────────────────────────
// --routes a,b : scope the memory anchor-walk to these route ids (ship.sh passes
//                the changed set). Absent = deep-check every route (full audit).
const args = process.argv.slice(2);
if (!args.length) { console.error('usage: validate.mjs --src <file>... | --memory [--routes a,b] | --skills | --all'); process.exit(2); }
const routesArg = args.includes('--routes')
  ? (args[args.indexOf('--routes') + 1] || '').split(',').map(s => s.trim()).filter(Boolean)
  : null;

if (args.includes('--all')) {
  const targets = [];
  if (existsSync('src/routes')) for (const r of readdirSync('src/routes')) {
    const f = join('src/routes', r, 'index.html');
    if (existsSync(f)) targets.push(f);
  }
  if (!targets.length && existsSync('index.html')) targets.push('index.html');
  targets.forEach(checkHtml);
  if (existsSync('.claude/memory/INDEX.md')) checkMemory();   // --all = deep, no filter
  if (existsSync('.claude/skills')) checkSkills();
} else {
  if (args.includes('--src')) args.slice(args.indexOf('--src') + 1).filter(a => !a.startsWith('--')).forEach(checkHtml);
  if (args.includes('--memory')) checkMemory('.claude/memory', routesArg);
  if (args.includes('--skills')) checkSkills();
}

if (warnings.length) warnings.forEach(w => console.error(`warn: ${w}`));
if (failures.length) { failures.forEach(f => console.error(f)); process.exit(1); }
console.log(`validate: clean${warnings.length ? ` (${warnings.length} warning${warnings.length > 1 ? 's' : ''})` : ''}`);
