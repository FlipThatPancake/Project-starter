#!/usr/bin/env node
// Regression tests for validate.mjs and build.mjs. Zero dependencies.
// Each case copies a tests/fixtures/<name> dir to a temp dir, runs the script
// there as a child process, and asserts exit code + expected output strings.
//
//   node scripts/test-tooling.mjs
import { spawnSync } from 'node:child_process';
import { cpSync, rmSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const ROOT = join(fileURLToPath(import.meta.url), '..', '..');
const FIXTURES = join(ROOT, 'tests', 'fixtures');
let failed = 0;

function run(fixture, script, args, { exit, stderrHas = [], stdoutHas = [], after } = {}) {
  const tmp = mkdtempSync(join(tmpdir(), 'skill-test-'));
  try {
    cpSync(join(FIXTURES, fixture), tmp, { recursive: true });
    const r = spawnSync('node', [join(ROOT, 'scripts', script), ...args], {
      cwd: tmp, encoding: 'utf8',
    });
    const problems = [];
    if (r.status !== exit) problems.push(`exit ${r.status}, expected ${exit}`);
    for (const s of stderrHas)
      if (!r.stderr.includes(s)) problems.push(`stderr missing "${s}"`);
    for (const s of stdoutHas)
      if (!r.stdout.includes(s)) problems.push(`stdout missing "${s}"`);
    if (after) { const p = after(tmp); if (p) problems.push(p); }
    if (problems.length) {
      failed++;
      console.error(`FAIL ${fixture} [${script} ${args.join(' ')}]`);
      problems.forEach(p => console.error(`     ${p}`));
      if (r.stderr.trim()) console.error(`     stderr: ${r.stderr.trim().split('\n').join(' | ')}`);
    } else {
      console.log(`PASS ${fixture} [${script} ${args.join(' ')}]`);
    }
  } finally { rmSync(tmp, { recursive: true, force: true }); }
}

// validate --memory: known-good passes
run('good', 'validate.mjs', ['--memory'], { exit: 0 });

// validate --memory: semantic caps + dead anchor all reported
run('bad-memory', 'validate.mjs', ['--memory'], {
  exit: 1,
  stderrHas: ['cap-gotchas', 'cap-decisions', 'anchor-dead'],
});

// validate --src: naming convention + orphan @end
run('bad-html', 'validate.mjs', ['--src', 'bad.html'], {
  exit: 1,
  stderrHas: ['anchor-name', 'end-orphan'],
});

// validate --src: good html is clean (incl. balanced @end)
run('good', 'validate.mjs', ['--src', 'app.html'], { exit: 0 });

// build: markers resolve, output self-contained, anchors preserved
run('build-demo', 'build.mjs', ['demo'], {
  exit: 0,
  after: tmp => {
    const out = join(tmp, 'dist', 'demo.html');
    if (!existsSync(out)) return 'dist/demo.html not written';
    const text = readFileSync(out, 'utf8');
    if (!text.includes('color:tomato')) return 'inlined CSS missing';
    if (!text.includes('data:image/svg+xml;base64,')) return 'asset not base64-inlined';
    if (!text.includes('@sec:demo')) return 'navigation anchor stripped from dist';
    return null;
  },
});

// build: unresolved @asset fails and writes nothing
run('build-bad', 'build.mjs', ['demo'], {
  exit: 1,
  stderrHas: ['@asset unresolved'],
  after: tmp => existsSync(join(tmp, 'dist', 'demo.html')) ? 'partial dist written on failure' : null,
});

// scoped memory: full check catches the dead anchor
run('scoped-memory', 'validate.mjs', ['--memory'], {
  exit: 1,
  stderrHas: ['anchor-dead', '@sec:ghost'],
});

// scoped memory: --routes limited to a DIFFERENT route skips the dead-anchor
// walk (exit 0) but still emits the shared-solo warning (non-fatal)
run('scoped-memory', 'validate.mjs', ['--memory', '--routes', 'other'], {
  exit: 0,
  stderrHas: ['shared-solo', 'design-x'],
});

// scoped memory: --routes naming the affected route still catches it
run('scoped-memory', 'validate.mjs', ['--memory', '--routes', 'app'], {
  exit: 1,
  stderrHas: ['anchor-dead'],
});

// ── bash-layer tests (hooks, ship gate, skillctl, nudge) ─────────────────────
// Same philosophy as above: real child processes, temp dirs, assert exit codes.
// These exist because the enforcement layer is bash — bugs here (e.g. the 2026-07
// leading-slash route-lock bug) are invisible to the Node-only tests above.

// scope-guard + ship key their lock files on sha256 of `pwd` output (path + \n)
const hashOf = p => createHash('sha256').update(p + '\n').digest('hex').slice(0, 8);

function bashCase(name, fn) {
  try {
    const problem = fn();
    if (problem) { failed++; console.error(`FAIL ${name}\n     ${problem}`); }
    else console.log(`PASS ${name}`);
  } catch (e) { failed++; console.error(`FAIL ${name}\n     ${e.message}`); }
}

// -- scope-guard-hook.sh: pipe a synthetic PreToolUse payload, assert exit code.
// Posture: ADVISORY by default (out-of-scope → allow, exit 0), ENFORCING when the
// `enforce` flag file exists (out-of-scope → block, exit 2). `noJq` sets
// SCOPE_GUARD_NO_JQ=1 to force the jq-free fallback parser, so that path is
// regression-covered without PATH surgery. `rawPayload` sends a literal string
// instead of a well-formed object (for the fail-closed case).
function guard(cwd, filePath, { scope, route, enforce = false, tool = 'Edit', noJq = false, rawPayload } = {}) {
  const h = hashOf(cwd);
  const SC = `/tmp/claude-scope-${h}`, EN = `/tmp/claude-scope-enforce-${h}`, RT = `/tmp/claude-route-scope-${h}`;
  for (const f of [SC, EN, RT]) rmSync(f, { force: true });
  if (scope) writeFileSync(SC, scope.join('\n') + '\n');
  if (route) writeFileSync(RT, route + '\n');
  if (enforce) writeFileSync(EN, '');
  const input = rawPayload !== undefined ? rawPayload
    : JSON.stringify({ tool_name: tool, tool_input: { file_path: join(cwd, filePath) }, cwd });
  const r = spawnSync('bash', [join(ROOT, 'scripts', 'scope-guard-hook.sh')], {
    cwd, encoding: 'utf8', input,
    env: noJq ? { ...process.env, SCOPE_GUARD_NO_JQ: '1' } : process.env,
  });
  for (const f of [SC, EN, RT]) rmSync(f, { force: true });
  return r.status;
}

const gdir = mkdtempSync(join(tmpdir(), 'guard-'));
bashCase('scope-guard: no locks → allow', () =>
  guard(gdir, 'anything.txt') === 0 ? null : 'expected exit 0');
bashCase('scope-guard: declared scope permits its prefix', () =>
  guard(gdir, 'src/routes/app/index.html', { scope: ['src/routes/app/'] }) === 0 ? null : 'expected exit 0');
bashCase('scope-guard: advisory (default) ALLOWS outside declared scope', () =>
  guard(gdir, 'src/routes/other/x.html', { scope: ['src/routes/app/'] }) === 0 ? null : 'expected exit 0 (advisory allows + nudges)');
bashCase('scope-guard: enforcing BLOCKS outside declared scope', () =>
  guard(gdir, 'src/routes/other/x.html', { scope: ['src/routes/app/'], enforce: true }) === 2 ? null : 'expected exit 2');
bashCase('scope-guard: .claude/** always writable, even when enforcing', () =>
  guard(gdir, '.claude/skills-store/skill-storage/x/SKILL.md', { scope: ['src/routes/app/'], enforce: true }) === 0 ? null : 'expected exit 0');
bashCase('scope-guard: route lock in docs format "/app" allows in-route edit', () =>
  guard(gdir, 'src/routes/app/index.html', { route: '/app' }) === 0 ? null : 'expected exit 0 (leading-slash regression)');
bashCase('scope-guard: route lock advises (allows) other route by default', () =>
  guard(gdir, 'src/routes/other/x.html', { route: '/app' }) === 0 ? null : 'expected exit 0 (advisory)');
bashCase('scope-guard: route lock + enforce blocks other route', () =>
  guard(gdir, 'src/routes/other/x.html', { route: '/app', enforce: true }) === 2 ? null : 'expected exit 2');
bashCase('scope-guard: non-Edit/Write tools pass through', () =>
  guard(gdir, 'src/routes/other/x.html', { route: '/app', enforce: true, tool: 'Read' }) === 0 ? null : 'expected exit 0');
// jq-free fallback: advisory still allows, enforcing still blocks, and an
// unparseable guarded payload must fail CLOSED (exit 2) regardless of posture.
bashCase('scope-guard (no jq): fallback allows in-route edit', () =>
  guard(gdir, 'src/routes/app/index.html', { scope: ['src/routes/app/'], noJq: true }) === 0 ? null : 'expected exit 0');
bashCase('scope-guard (no jq): advisory allows out-of-scope edit', () =>
  guard(gdir, 'src/routes/other/x.html', { scope: ['src/routes/app/'], noJq: true }) === 0 ? null : 'expected exit 0');
bashCase('scope-guard (no jq): enforcing blocks out-of-scope edit', () =>
  guard(gdir, 'src/routes/other/x.html', { scope: ['src/routes/app/'], enforce: true, noJq: true }) === 2 ? null : 'expected exit 2');
bashCase('scope-guard (no jq): unparseable guarded payload fails closed', () =>
  // tool_name present as a key but not a plain quoted string → fallback can't
  // extract it → must block (exit 2), never silently allow
  guard(gdir, 'x', { scope: ['src/routes/app/'], noJq: true,
    rawPayload: '{"tool_name": 123, "tool_input": {"file_path": "x"}, "cwd": "y"}' }) === 2 ? null : 'expected exit 2 (fail-closed)');
rmSync(gdir, { recursive: true, force: true });

// -- ship.sh: cross-route commit gate (F4) + template build filter, in a temp git repo
const GITENV = { ...process.env, GIT_AUTHOR_NAME: 't', GIT_AUTHOR_EMAIL: 't@t.t',
  GIT_COMMITTER_NAME: 't', GIT_COMMITTER_EMAIL: 't@t.t' };
function makeRepo() {
  const repo = mkdtempSync(join(tmpdir(), 'ship-'));
  const put = (p, c) => { mkdirSync(join(repo, dirname(p)), { recursive: true }); writeFileSync(join(repo, p), c); };
  put('src/routes/app/index.html', '<html></html>\n');
  put('src/routes/other/index.html', '<html></html>\n');
  put('src/routes/_skeleton/index.html', '<html></html>\n');
  const git = (...a) => spawnSync('git', a, { cwd: repo, encoding: 'utf8', env: GITENV });
  git('init', '-q'); git('add', '-A'); git('commit', '-qm', 'base');
  return { repo, put, git };
}
function ship(repo, msg, extra = []) {
  return spawnSync('bash', [join(ROOT, 'scripts', 'ship.sh'), msg, '--no-push', '--no-validate', ...extra],
    { cwd: repo, encoding: 'utf8', env: GITENV });
}

{
  // Advisory posture (default): a route/scope lock is set, but NO enforce flag.
  const { repo, put } = makeRepo();
  const h = hashOf(repo);
  const RT = `/tmp/claude-route-scope-${h}`, EN = `/tmp/claude-scope-enforce-${h}`;
  rmSync(EN, { force: true });
  writeFileSync(RT, '/app\n');                       // docs format, leading slash
  put('src/routes/app/index.html', '<html>edit</html>\n');
  bashCase('ship: in-route commit passes under scope lock', () => {
    const r = ship(repo, 'in-route', ['--no-build']);
    return r.status === 0 ? null : `expected exit 0, got ${r.status} (leading-slash regression); stderr: ${r.stderr.trim()}`;
  });
  put('src/routes/other/index.html', '<html>edit</html>\n');
  bashCase('ship: cross-scope commit is advisory (proceeds) by default', () => {
    const r = ship(repo, 'cross-route', ['--no-build']);
    if (r.status !== 0) return `expected exit 0 (advisory), got ${r.status}; stderr: ${r.stderr.trim()}`;
    return r.stderr.includes('advisory') ? null : 'stderr missing advisory note';
  });
  rmSync(RT, { force: true });
  rmSync(repo, { recursive: true, force: true });
}
{
  // Enforcing posture: enforce flag present → cross-scope blocked unless overridden.
  const { repo, put } = makeRepo();
  const h = hashOf(repo);
  const RT = `/tmp/claude-route-scope-${h}`, EN = `/tmp/claude-scope-enforce-${h}`;
  writeFileSync(RT, '/app\n'); writeFileSync(EN, '');
  put('src/routes/other/index.html', '<html>edit</html>\n');
  bashCase('ship: enforcing cross-scope commit blocked without token', () => {
    const r = ship(repo, 'cross-route', ['--no-build']);
    if (r.status !== 2) return `expected exit 2, got ${r.status}`;
    return r.stderr.includes('scope violation') ? null : 'stderr missing "scope violation"';
  });
  bashCase('ship: enforcing @allow-cross-route in message overrides', () => {
    const r = ship(repo, 'cross-route @allow-cross-route', ['--no-build']);
    return r.status === 0 ? null : `expected exit 0, got ${r.status}; stderr: ${r.stderr.trim()}`;
  });
  rmSync(RT, { force: true }); rmSync(EN, { force: true });
  rmSync(repo, { recursive: true, force: true });
}
{
  const { repo, put } = makeRepo();                 // no route lock here
  put('src/routes/_skeleton/index.html', '<html>tweak</html>\n');
  bashCase('ship: _skeleton change never builds dist/_skeleton.html', () => {
    const r = ship(repo, 'skeleton tweak');         // build path enabled on purpose
    if (r.status !== 0) return `expected exit 0, got ${r.status}; stderr: ${r.stderr.trim()}`;
    return existsSync(join(repo, 'dist', '_skeleton.html')) ? 'dist/_skeleton.html was built' : null;
  });
  rmSync(repo, { recursive: true, force: true });
}

// -- skillctl.sh: list alias + load/unload round-trip against a temp store
{
  const repo = mkdtempSync(join(tmpdir(), 'skillctl-'));
  mkdirSync(join(repo, '.claude', 'skills'), { recursive: true });
  mkdirSync(join(repo, '.claude', 'skills-store', 'skill-storage', 'tskill'), { recursive: true });
  writeFileSync(join(repo, '.claude', 'skills-store', 'skill-storage', 'tskill', 'SKILL.md'),
    '---\nname: tskill\ndescription: test skill\ngroup: test\n---\nbody\n');
  spawnSync('git', ['init', '-q'], { cwd: repo, encoding: 'utf8', env: GITENV });
  const ctl = (...a) => spawnSync('bash', [join(ROOT, 'scripts', 'skillctl.sh'), ...a],
    { cwd: repo, encoding: 'utf8' });
  bashCase('skillctl: list works and shows dormant skill', () => {
    const r = ctl('list');
    if (r.status !== 0) return `expected exit 0, got ${r.status}`;
    return r.stdout.includes('tskill') ? null : 'stdout missing "tskill"';
  });
  bashCase('skillctl: load copies store→active (master kept)', () => {
    const r = ctl('load', 'tskill');
    if (r.status !== 0) return `expected exit 0, got ${r.status}`;
    if (!existsSync(join(repo, '.claude', 'skills', 'tskill', 'SKILL.md'))) return 'active copy missing';
    return existsSync(join(repo, '.claude', 'skills-store', 'skill-storage', 'tskill', 'SKILL.md')) ? null : 'store master lost';
  });
  bashCase('skillctl: unload removes active copy only', () => {
    const r = ctl('unload', 'tskill');
    if (r.status !== 0) return `expected exit 0, got ${r.status}`;
    if (existsSync(join(repo, '.claude', 'skills', 'tskill'))) return 'active copy still present';
    return existsSync(join(repo, '.claude', 'skills-store', 'skill-storage', 'tskill', 'SKILL.md')) ? null : 'store master lost';
  });
  rmSync(repo, { recursive: true, force: true });
}

// -- checkpoint-nudge.sh: suppressed on state: starter
{
  const repo = mkdtempSync(join(tmpdir(), 'nudge-'));
  mkdirSync(join(repo, '.claude', 'memory'), { recursive: true });
  writeFileSync(join(repo, '.claude', 'memory', 'INDEX.md'), 'state: starter\n');
  writeFileSync(join(repo, 'big.js'), 'x\n'.repeat(300));
  spawnSync('git', ['init', '-q'], { cwd: repo, encoding: 'utf8', env: GITENV });
  spawnSync('git', ['add', '-A'], { cwd: repo, encoding: 'utf8', env: GITENV });
  spawnSync('git', ['commit', '-qm', 'base'], { cwd: repo, encoding: 'utf8', env: GITENV });
  writeFileSync(join(repo, 'big.js'), 'y\n'.repeat(300));   // huge uncommitted diff
  bashCase('checkpoint-nudge: silent on state: starter', () => {
    const r = spawnSync('bash', [join(ROOT, 'scripts', 'checkpoint-nudge.sh')],
      { cwd: repo, encoding: 'utf8' });
    if (r.status !== 0) return `expected exit 0, got ${r.status}`;
    return r.stdout.trim() === '' ? null : `expected no output, got: ${r.stdout.trim()}`;
  });
  rmSync(repo, { recursive: true, force: true });
}

if (failed) { console.error(`\n${failed} test(s) failed`); process.exit(1); }
console.log('\ntest-tooling: all passing');
