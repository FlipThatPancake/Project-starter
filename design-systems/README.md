# design-systems/ — vendored design systems vault

This folder holds **complete, self-contained design systems** vendored from
elsewhere. Each subfolder is one system (tokens, components, motion, docs,
starter markup).

## Policy — READ-EXCLUDED BY DEFAULT

The agent must **never read, grep, open, or load** any file under
`design-systems/` as part of normal work. Nothing here is in the default
read-set for any session mode. It is inert reference material, not active
source.

The **only** permitted interaction:

> When the user **explicitly** decides to use a specific system, copy that
> one system's files into `src/shared/`. Nothing enters the active codebase
> until that opt-in happens.

Adding a system here does **not** activate it. Treat this folder like
`dist/` — off-limits unless the user directs otherwise.

## Contents

| System | Source |
|---|---|
| `midea-design-style-guide/` | Midea design style guide — fully self-contained: foundations/components/motion/page-structure docs, tokens.css, components.css, starter.html, and `assets/` (midea-logo.svg, loader.js). Copy the whole folder — nothing is left behind except the documented Google Fonts link. |
