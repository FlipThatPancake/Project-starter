// Shared skill-metadata reader + index renderer.
// Single source of truth for BOTH gen-skill-index.mjs (writes INDEX.md) and
// validate.mjs (checks INDEX.md is in sync) so the two can never diverge.
//
// The model (design proposal v2 §B3/B4): a skill's metadata lives in its OWN
// SKILL.md frontmatter (policy, category, optional exclusive-with). State
// (active/dormant) is derived from location. `size` is computed here (SKILL.md
// non-empty line count), never hand-stored. There is no central CATALOG table.
import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

export const ACTIVE_DIR = '.claude/skills';
export const STORE_DIR = '.claude/skills-store/skill-storage';
export const INDEX_PATH = '.claude/skills-store/INDEX.md';
export const POLICIES = ['pinned', 'ride-along', 'menu', 'manual'];
export const PINNED_BASELINE = ['skill-manager', 'project-memory', 'checkpoint'];

// Parse the leading `---\n...\n---` YAML-ish frontmatter (flat keys only).
export function parseFrontmatter(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return null;
  const fm = {};
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-z][a-z0-9-]*):\s*(.*)$/i);
    if (kv) fm[kv[1].toLowerCase()] = kv[2].trim();
  }
  return fm;
}

function nonEmptyLineCount(text) {
  return text.split('\n').filter(l => l.trim() !== '').length;
}

// Read one skill dir → metadata object, or { name, error } on trouble.
export function readSkillMeta(shelf, dir) {
  const p = join(shelf, dir, 'SKILL.md');
  if (!existsSync(p)) return { name: dir, error: 'no SKILL.md' };
  const text = readFileSync(p, 'utf8');
  const fm = parseFrontmatter(text);
  if (!fm) return { name: dir, error: 'no frontmatter' };
  const exclusive = (fm['exclusive-with'] || '')
    .replace(/^\[|\]$/g, '').split(',').map(s => s.trim()).filter(Boolean);
  return {
    name: fm.name || dir,
    dir,
    state: shelf === ACTIVE_DIR ? 'active' : 'dormant',
    category: fm.category || '',
    policy: fm.policy || '',
    size: nonEmptyLineCount(text),
    exclusive,
    error: null,
  };
}

// Scan both shelves → sorted array of skill metadata.
// Activation COPIES store→active (the store keeps the master so a gitignored active
// copy can never lose it), so a loaded skill exists on BOTH shelves. Active shadows
// dormant: a name present in .claude/skills/ is reported once, as active; its store
// master is the invisible backing copy. So the index shows each skill exactly once.
export function scanSkills() {
  const out = [];
  const seen = new Set();
  for (const shelf of [ACTIVE_DIR, STORE_DIR]) {
    if (!existsSync(shelf)) continue;
    for (const dir of readdirSync(shelf)) {
      if (!statSync(join(shelf, dir)).isDirectory()) continue;
      if (seen.has(dir)) continue;          // active already covered this name
      seen.add(dir);
      out.push(readSkillMeta(shelf, dir));
    }
  }
  out.sort((a, b) => (a.category || '').localeCompare(b.category || '') || a.name.localeCompare(b.name));
  return out;
}

// Render the generated INDEX.md — the ONLY browse surface (hook prints it cheaply).
export function renderIndex(skills) {
  const lines = [];
  lines.push('# SKILL INDEX — GENERATED, do not hand-edit. Run `node scripts/gen-skill-index.mjs`.');
  lines.push('Metadata lives in each skill\'s SKILL.md frontmatter; state = folder location.');
  lines.push('active = in .claude/skills/ (in context) · dormant = in skills-store/ (zero tokens until loaded).');
  lines.push('');
  lines.push('| skill | state | category | policy | size | exclusive-with |');
  lines.push('|---|---|---|---|---|---|');
  for (const s of skills) {
    const ex = s.exclusive && s.exclusive.length ? s.exclusive.join(', ') : '—';
    lines.push(`| ${s.name} | ${s.state} | ${s.category || '?'} | ${s.policy || '?'} | ${s.size} | ${ex} |`);
  }
  lines.push('');
  return lines.join('\n');
}
