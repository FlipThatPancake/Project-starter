#!/usr/bin/env node
// Zero-dependency route builder: src/routes/<route>/index.html → dist/<route>.html
// (self-contained single file). This script is the HTML-specific swappable layer;
// replace it if a future project uses a framework build.
//
//   node scripts/build.mjs <route> [...routes] | --all
//
// Markers (resolved relative to the SOURCE file's directory):
//   @asset:assets/foo.png        anywhere in an attribute/url() — replaced in-place
//                                with a base64 data: URI (MIME from extension)
//   <!-- @inline:../shared/x.css -->  whole comment replaced by file contents,
//                                wrapped in <style>/<script> by extension (.css/.js),
//                                inserted raw for anything else (.html, .svg)
//
// Navigation anchors (@sec:/@css:/@js:) are PRESERVED in dist: ~20 bytes each and
// they keep the built artifact grep-able when debugging production output.
// Deterministic: same input bytes → same output bytes. Missing file → exit 1,
// nothing written (never a partial dist).
import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve, extname } from 'node:path';

const MIME = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif',
  '.webp': 'image/webp', '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
  '.woff': 'font/woff', '.woff2': 'font/woff2', '.ttf': 'font/ttf' };

function buildRoute(route) {
  const srcFile = join('src/routes', route, 'index.html');
  if (!existsSync(srcFile)) { console.error(`build: no such route source: ${srcFile}`); process.exit(1); }
  const srcDir = dirname(srcFile);
  const text = readFileSync(srcFile, 'utf8');
  const errors = [];

  // Pass 1: @inline comments
  let out = text.replace(/[ \t]*<!--\s*@inline:([^\s]+?)\s*-->/g, (whole, rel) => {
    const p = resolve(srcDir, rel);
    if (!existsSync(p)) { errors.push(`@inline unresolved: ${rel}`); return whole; }
    const body = readFileSync(p, 'utf8');
    const ext = extname(p);
    if (ext === '.css') return `<style>\n${body}\n</style>`;
    if (ext === '.js' || ext === '.mjs') return `<script>\n${body}\n</script>`;
    return body;
  });

  // Pass 2: @asset tokens (in src="", url(), etc.)
  out = out.replace(/@asset:([^\s"')>]+)/g, (whole, rel) => {
    const p = resolve(srcDir, rel);
    if (!existsSync(p)) { errors.push(`@asset unresolved: ${rel}`); return whole; }
    const mime = MIME[extname(p).toLowerCase()];
    if (!mime) { errors.push(`@asset unknown extension: ${rel}`); return whole; }
    return `data:${mime};base64,${readFileSync(p).toString('base64')}`;
  });

  if (errors.length) { errors.forEach(e => console.error(`build[${route}]: ${e}`)); process.exit(1); }
  mkdirSync('dist', { recursive: true });
  writeFileSync(join('dist', `${route}.html`), out);
  console.log(`build: dist/${route}.html (${out.length} bytes)`);
}

const args = process.argv.slice(2);
if (!args.length) { console.error('usage: build.mjs <route>... | --all'); process.exit(2); }
const routes = args.includes('--all')
  ? (existsSync('src/routes') ? readdirSync('src/routes')
      // skip templates (_skeleton), dotfiles (.gitkeep), and non-route entries
      .filter(r => !r.startsWith('_') && !r.startsWith('.')
        && existsSync(join('src/routes', r, 'index.html'))) : [])
  : args;
if (!routes.length) { console.error('build: no routes found under src/routes/'); process.exit(2); }
routes.forEach(buildRoute);
