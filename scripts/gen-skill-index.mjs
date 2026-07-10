#!/usr/bin/env node
// Regenerate .claude/skills-store/INDEX.md from every skill's SKILL.md frontmatter.
// Run after any add / remove / load / unload / policy change. `validate.mjs --skills`
// fails if INDEX.md is stale, so this is the one command that keeps it honest.
import { writeFileSync } from 'node:fs';
import { scanSkills, renderIndex, INDEX_PATH } from './lib/skill-meta.mjs';

const skills = scanSkills();
const bad = skills.filter(s => s.error || !s.policy || !s.category);
if (bad.length) {
  for (const s of bad) console.error(`gen-skill-index: ${s.name}: ${s.error || 'missing policy/category in frontmatter'}`);
  process.exit(1);
}
writeFileSync(INDEX_PATH, renderIndex(skills));
console.log(`gen-skill-index: wrote ${INDEX_PATH} (${skills.length} skills)`);
