#!/usr/bin/env node
// Regression tests for validate.mjs and build.mjs. Zero dependencies.
// Each case copies a tests/fixtures/<name> dir to a temp dir, runs the script
// there as a child process, and asserts exit code + expected output strings.
//
//   node scripts/test-tooling.mjs
import { spawnSync } from 'node:child_process';
import { cpSync, rmSync, mkdtempSync, readFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

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

if (failed) { console.error(`\n${failed} test(s) failed`); process.exit(1); }
console.log('\ntest-tooling: all passing');
