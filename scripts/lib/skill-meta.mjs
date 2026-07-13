// Shared skill-metadata reader — single source of truth for validate.mjs's
// --skills checks and any script that needs to enumerate skills programmatically.
//
// The model (v3): a skill's metadata lives in its OWN SKILL.md frontmatter
// (name, description, optional group, optional exclusive-with). State
// (active/dormant) is derived from location. "Always-on" is defined solely by
// the .gitignore whitelist — there is no policy field and no generated index
// file; the session-start hook enumerates directories directly in bash.
import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

export const ACTIVE_DIR = '.claude/skills';
export const STORE_DIR = '.claude/skills-store/skill-storage';

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
    description: fm.description || '',
    group: fm.group || '',
    size: nonEmptyLineCount(text),
    exclusive,
    error: null,
  };
}

// Scan both shelves → sorted array of skill metadata.
// Activation COPIES store→active (the store keeps the master, so a gitignored
// active copy can never lose it), so a loaded skill exists on BOTH shelves.
// Active shadows dormant: a name present in .claude/skills/ is reported once,
// as active; its store master is the invisible backing copy.
// alwaysOnFromGitignore() — the "always-on" set is defined solely by the
// `!.claude/skills/<name>/` negation lines in .gitignore (v3 model). Returns
// an array of skill names.
export function alwaysOnFromGitignore(gitignorePath = '.gitignore') {
  if (!existsSync(gitignorePath)) return [];
  const text = readFileSync(gitignorePath, 'utf8');
  const names = [];
  for (const line of text.split('\n')) {
    const m = line.match(/^!\.claude\/skills\/([^/]+)\/?$/);
    if (m) names.push(m[1]);
  }
  return names;
}

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
  out.sort((a, b) => (a.group || '').localeCompare(b.group || '') || a.name.localeCompare(b.name));
  return out;
}
