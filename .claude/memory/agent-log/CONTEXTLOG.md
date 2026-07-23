---
purpose: manual log of `/context` snapshots, for later evaluation/optimization of context usage
status: standalone — NOT referenced by INDEX.md, NOT auto-loaded by the session-start hook,
  NOT subject to validate.mjs caps/shape checks, NOT written to by checkpoint or any skill.
  Append entries manually (or on request) when a `/context` reading is worth keeping.
  User exports/prunes this file manually.
format: one `##` entry per snapshot, newest first
---

# Context Log

## 2026-07-23 — claude/ticket-execution-p2hsr6 — mode 4-continue-route

**Model:** claude-sonnet-5
**Tokens:** 143.2k / 967k (15%)

### Estimated usage by category

| Category | Tokens | Percentage |
|----------|--------|------------|
| System prompt | 10k | 1.0% |
| System tools | 15.9k | 1.6% |
| MCP tools | 10.1k | 1.0% |
| MCP tools (deferred) | 138k | 14.3% |
| System tools (deferred) | 19k | 2.0% |
| Memory files | 1.4k | 0.1% |
| Skills | 5.7k | 0.6% |
| Messages | 100.2k | 10.4% |
| Free space | 790.8k | 81.8% |
| Autocompact buffer | 33k | 3.4% |

> Note: "(deferred)" rows are the cost *if* those tool schemas were pulled in via
> ToolSearch — they are not currently occupying context. Real usage this
> snapshot = 143.2k/967k (15%), driven mostly by Messages (100.2k, this
> session's file reads/edits/tool output) and the System prompt + System
> tools baseline (~26k).

### MCP Tools (loaded/deferred-cost breakdown, per tool)

| Tool | Server | Tokens |
|------|--------|--------|
| mcp__Adobe_for_creativity__adobe_mandatory_init | Adobe_for_creativity | 994 |
| mcp__Adobe_for_creativity__animate_design | Adobe_for_creativity | 642 |
| mcp__Adobe_for_creativity__asset_add_file | Adobe_for_creativity | 372 |
| mcp__Adobe_for_creativity__asset_add_file_check_status | Adobe_for_creativity | 218 |
| mcp__Adobe_for_creativity__asset_copy_assets | Adobe_for_creativity | 307 |
| mcp__Adobe_for_creativity__asset_create_folders | Adobe_for_creativity | 636 |
| mcp__Adobe_for_creativity__asset_finalize_file_upload | Adobe_for_creativity | 372 |
| mcp__Adobe_for_creativity__asset_get_presigned_urls | Adobe_for_creativity | 794 |
| mcp__Adobe_for_creativity__asset_initialize_file_upload | Adobe_for_creativity | 571 |
| mcp__Adobe_for_creativity__asset_inline_preview | Adobe_for_creativity | 628 |
| mcp__Adobe_for_creativity__asset_invite_collaborators | Adobe_for_creativity | 1.8k |
| mcp__Adobe_for_creativity__asset_license_and_download_stock | Adobe_for_creativity | 315 |
| mcp__Adobe_for_creativity__asset_list_collaborators | Adobe_for_creativity | 667 |
| mcp__Adobe_for_creativity__asset_migrate_guest_storage | Adobe_for_creativity | 327 |
| mcp__Adobe_for_creativity__asset_preview_file | Adobe_for_creativity | 604 |
| mcp__Adobe_for_creativity__asset_search | Adobe_for_creativity | 2.2k |
| mcp__Adobe_for_creativity__asset_share_link | Adobe_for_creativity | 866 |
| mcp__Adobe_for_creativity__boards_add_items_to_board | Adobe_for_creativity | 2k |
| mcp__Adobe_for_creativity__boards_create_new_board | Adobe_for_creativity | 612 |
| mcp__Adobe_for_creativity__change_background_color | Adobe_for_creativity | 749 |
| mcp__Adobe_for_creativity__convert_pdf_to_indd | Adobe_for_creativity | 658 |
| mcp__Adobe_for_creativity__create_firefly_board | Adobe_for_creativity | 1.2k |
| mcp__Adobe_for_creativity__create_visual_design_express_skill | Adobe_for_creativity | 952 |
| mcp__Adobe_for_creativity__document_convert_pdf | Adobe_for_creativity | 439 |
| mcp__Adobe_for_creativity__document_merge_data_layout | Adobe_for_creativity | 892 |
| mcp__Adobe_for_creativity__document_merge_data_vector | Adobe_for_creativity | 1.2k |
| mcp__Adobe_for_creativity__document_render_layout | Adobe_for_creativity | 778 |
| mcp__Adobe_for_creativity__document_render_vector | Adobe_for_creativity | 1.1k |
| mcp__Adobe_for_creativity__export_html_to_express | Adobe_for_creativity | 1.5k |
| mcp__Adobe_for_creativity__export_idml | Adobe_for_creativity | 607 |
| mcp__Adobe_for_creativity__fill_text | Adobe_for_creativity | 903 |
| mcp__Adobe_for_creativity__find_fonts | Adobe_for_creativity | 552 |
| mcp__Adobe_for_creativity__font_recommend | Adobe_for_creativity | 662 |
| mcp__Adobe_for_creativity__generate_indd_mapping_prompt | Adobe_for_creativity | 1.6k |
| mcp__Adobe_for_creativity__get_account_type | Adobe_for_creativity | 212 |
| mcp__Adobe_for_creativity__get_fontkit_embed_url | Adobe_for_creativity | 536 |
| mcp__Adobe_for_creativity__html_export_readiness_skill | Adobe_for_creativity | 160 |
| mcp__Adobe_for_creativity__image_add_grain | Adobe_for_creativity | 735 |
| mcp__Adobe_for_creativity__image_add_noise | Adobe_for_creativity | 836 |
| mcp__Adobe_for_creativity__image_adjust_brightness_and_contrast | Adobe_for_creativity | 1.2k |
| mcp__Adobe_for_creativity__image_adjust_color_temperature | Adobe_for_creativity | 1.5k |
| mcp__Adobe_for_creativity__image_adjust_dark_portions | Adobe_for_creativity | 1.2k |
| mcp__Adobe_for_creativity__image_adjust_exposure | Adobe_for_creativity | 2.3k |
| mcp__Adobe_for_creativity__image_adjust_highlights | Adobe_for_creativity | 1.1k |
| mcp__Adobe_for_creativity__image_adjust_hsl | Adobe_for_creativity | 1.7k |
| mcp__Adobe_for_creativity__image_adjust_light_portions | Adobe_for_creativity | 1.1k |
| mcp__Adobe_for_creativity__image_adjust_single_color_saturation | Adobe_for_creativity | 1.4k |
| mcp__Adobe_for_creativity__image_adjust_vibrance_and_saturation | Adobe_for_creativity | 1.1k |
| mcp__Adobe_for_creativity__image_apply_adjustments | Adobe_for_creativity | 4.6k |
| mcp__Adobe_for_creativity__image_apply_auto_tone | Adobe_for_creativity | 485 |
| mcp__Adobe_for_creativity__image_apply_color_overlay | Adobe_for_creativity | 1.5k |
| mcp__Adobe_for_creativity__image_apply_gaussian_blur | Adobe_for_creativity | 1.2k |
| mcp__Adobe_for_creativity__image_apply_glitch_effect | Adobe_for_creativity | 732 |
| mcp__Adobe_for_creativity__image_apply_halftone | Adobe_for_creativity | 846 |
| mcp__Adobe_for_creativity__image_apply_lens_blur | Adobe_for_creativity | 748 |
| mcp__Adobe_for_creativity__image_apply_monochromatic_tint | Adobe_for_creativity | 844 |
| mcp__Adobe_for_creativity__image_apply_preset | Adobe_for_creativity | 1.3k |
| mcp__Adobe_for_creativity__image_auto_straighten | Adobe_for_creativity | 443 |
| mcp__Adobe_for_creativity__image_crop_and_resize | Adobe_for_creativity | 3.1k |
| mcp__Adobe_for_creativity__image_crop_to_bounds | Adobe_for_creativity | 1.7k |
| mcp__Adobe_for_creativity__image_fill_area | Adobe_for_creativity | 1.5k |
| mcp__Adobe_for_creativity__image_generative_expand | Adobe_for_creativity | 999 |
| mcp__Adobe_for_creativity__image_invert_selection | Adobe_for_creativity | 335 |
| mcp__Adobe_for_creativity__image_list_presets | Adobe_for_creativity | 144 |
| mcp__Adobe_for_creativity__image_remove_background | Adobe_for_creativity | 1.2k |
| mcp__Adobe_for_creativity__image_select_by_prompt | Adobe_for_creativity | 1.9k |
| mcp__Adobe_for_creativity__image_select_subject | Adobe_for_creativity | 1.5k |
| mcp__Adobe_for_creativity__image_vectorize | Adobe_for_creativity | 373 |
| mcp__Adobe_for_creativity__import-claude-design-from-url | Adobe_for_creativity | 1.1k |
| mcp__Adobe_for_creativity__media_enhance_speech | Adobe_for_creativity | 139 |
| mcp__Adobe_for_creativity__media_summarize | Adobe_for_creativity | 126 |
| mcp__Adobe_for_creativity__prepare_indd_merge_template | Adobe_for_creativity | 1.1k |
| mcp__Adobe_for_creativity__search_design | Adobe_for_creativity | 1.3k |
| mcp__Adobe_for_creativity__video_create_quick_cut | Adobe_for_creativity | 387 |
| mcp__Adobe_for_creativity__video_metadata | Adobe_for_creativity | 133 |
| mcp__Adobe_for_creativity__video_render | Adobe_for_creativity | 1k |
| mcp__Adobe_for_creativity__video_render_frame | Adobe_for_creativity | 1.4k |
| mcp__Adobe_for_creativity__video_resize | Adobe_for_creativity | 232 |
| mcp__Claude_Code_Remote__add_repo | Claude_Code_Remote | 983 |
| mcp__Claude_Code_Remote__create_trigger | Claude_Code_Remote | 1.5k |
| mcp__Claude_Code_Remote__delete_trigger | Claude_Code_Remote | 273 |
| mcp__Claude_Code_Remote__fire_trigger | Claude_Code_Remote | 405 |
| mcp__Claude_Code_Remote__list_environments | Claude_Code_Remote | 160 |
| mcp__Claude_Code_Remote__list_repos | Claude_Code_Remote | 300 |
| mcp__Claude_Code_Remote__list_triggers | Claude_Code_Remote | 408 |
| mcp__Claude_Code_Remote__register_repo_root | Claude_Code_Remote | 349 |
| mcp__Claude_Code_Remote__send_later | Claude_Code_Remote | 498 |
| mcp__Claude_Code_Remote__subscribe_pr_activity | Claude_Code_Remote | 356 |
| mcp__Claude_Code_Remote__unsubscribe_pr_activity | Claude_Code_Remote | 243 |
| mcp__Claude_Code_Remote__update_trigger | Claude_Code_Remote | 1.2k |
| mcp__Figma__add_code_connect_map | Figma | 1k |
| mcp__Figma__create_new_file | Figma | 871 |
| mcp__Figma__download_assets | Figma | 1.1k |
| mcp__Figma__export_video | Figma | 1.5k |
| mcp__Figma__generate_diagram | Figma | 1.3k |
| mcp__Figma__get_code_connect_map | Figma | 650 |
| mcp__Figma__get_code_connect_suggestions | Figma | 686 |
| mcp__Figma__get_context_for_code_connect | Figma | 654 |
| mcp__Figma__get_design_context | Figma | 1.6k |
| mcp__Figma__get_figjam | Figma | 642 |
| mcp__Figma__get_figma_skill | Figma | 479 |
| mcp__Figma__get_libraries | Figma | 457 |
| mcp__Figma__get_metadata | Figma | 1.2k |
| mcp__Figma__get_motion_context | Figma | 906 |
| mcp__Figma__get_screenshot | Figma | 1.5k |
| mcp__Figma__get_shader_effect | Figma | 318 |
| mcp__Figma__get_shader_fill | Figma | 316 |
| mcp__Figma__get_variable_defs | Figma | 661 |
| mcp__Figma__list_file_components_for_code_connect | Figma | 640 |
| mcp__Figma__list_shader_effects | Figma | 258 |
| mcp__Figma__list_shader_fills | Figma | 253 |
| mcp__Figma__read_skill_uri | Figma | 506 |
| mcp__Figma__search_design_system | Figma | 563 |
| mcp__Figma__send_code_connect_mappings | Figma | 1.3k |
| mcp__Figma__upload_assets | Figma | 900 |
| mcp__Figma__use_figma | Figma | 1.3k |
| mcp__Figma__whoami | Figma | 171 |
| mcp__Firecrawl__firecrawl_agent | Firecrawl | 996 |
| mcp__Firecrawl__firecrawl_agent_status | Firecrawl | 451 |
| mcp__Firecrawl__firecrawl_check_crawl_status | Firecrawl | 210 |
| mcp__Firecrawl__firecrawl_crawl | Firecrawl | 1.7k |
| mcp__Firecrawl__firecrawl_extract | Firecrawl | 795 |
| mcp__Firecrawl__firecrawl_feedback | Firecrawl | 1.2k |
| mcp__Firecrawl__firecrawl_interact | Firecrawl | 1.7k |
| mcp__Firecrawl__firecrawl_interact_stop | Firecrawl | 213 |
| mcp__Firecrawl__firecrawl_map | Firecrawl | 768 |
| mcp__Firecrawl__firecrawl_monitor_check | Firecrawl | 1.1k |
| mcp__Firecrawl__firecrawl_monitor_checks | Firecrawl | 273 |
| mcp__Firecrawl__firecrawl_monitor_create | Firecrawl | 1.2k |
| mcp__Firecrawl__firecrawl_monitor_delete | Firecrawl | 174 |
| mcp__Firecrawl__firecrawl_monitor_get | Firecrawl | 153 |
| mcp__Firecrawl__firecrawl_monitor_list | Firecrawl | 202 |
| mcp__Firecrawl__firecrawl_monitor_run | Firecrawl | 179 |
| mcp__Firecrawl__firecrawl_monitor_update | Firecrawl | 280 |
| mcp__Firecrawl__firecrawl_parse | Firecrawl | 1.4k |
| mcp__Firecrawl__firecrawl_research_inspect_paper | Firecrawl | 193 |
| mcp__Firecrawl__firecrawl_research_read_paper | Firecrawl | 289 |
| mcp__Firecrawl__firecrawl_research_related_papers | Firecrawl | 462 |
| mcp__Firecrawl__firecrawl_research_search_github | Firecrawl | 191 |
| mcp__Firecrawl__firecrawl_research_search_papers | Firecrawl | 419 |
| mcp__Firecrawl__firecrawl_scrape | Firecrawl | 1.7k |
| mcp__Firecrawl__firecrawl_search | Firecrawl | 2k |
| mcp__Firecrawl__firecrawl_search_feedback | Firecrawl | 1.2k |
| mcp__github__actions_get | github | 474 |
| mcp__github__actions_list | github | 1.1k |
| mcp__github__actions_run_trigger | github | 465 |
| mcp__github__add_comment_to_pending_review | github | 609 |
| mcp__github__add_issue_comment | github | 492 |
| mcp__github__add_reply_to_pull_request_comment | github | 460 |
| mcp__github__create_branch | github | 196 |
| mcp__github__create_or_update_file | github | 474 |
| mcp__github__create_pull_request | github | 353 |
| mcp__github__create_repository | github | 266 |
| mcp__github__delete_file | github | 229 |
| mcp__github__disable_pr_auto_merge | github | 177 |
| mcp__github__enable_pr_auto_merge | github | 319 |
| mcp__github__fork_repository | github | 171 |
| mcp__github__get_check_run | github | 659 |
| mcp__github__get_commit | github | 419 |
| mcp__github__get_file_contents | github | 286 |
| mcp__github__get_job_logs | github | 471 |
| mcp__github__get_label | github | 166 |
| mcp__github__get_latest_release | github | 134 |
| mcp__github__get_me | github | 106 |
| mcp__github__get_release_by_tag | github | 169 |
| mcp__github__get_tag | github | 158 |
| mcp__github__get_team_members | github | 160 |
| mcp__github__get_teams | github | 128 |
| mcp__github__issue_read | github | 498 |
| mcp__github__issue_write | github | 1.1k |
| mcp__github__list_branches | github | 212 |
| mcp__github__list_commits | github | 541 |
| mcp__github__list_issue_fields | github | 302 |
| mcp__github__list_issue_types | github | 232 |
| mcp__github__list_issues | github | 764 |
| mcp__github__list_pull_requests | github | 422 |
| mcp__github__list_releases | github | 212 |
| mcp__github__list_repository_collaborators | github | 402 |
| mcp__github__list_tags | github | 210 |
| mcp__github__merge_pull_request | github | 266 |
| mcp__github__pull_request_read | github | 966 |
| mcp__github__pull_request_review_write | github | 865 |
| mcp__github__push_files | github | 330 |
| mcp__github__request_copilot_review | github | 210 |
| mcp__github__resolve_review_thread | github | 228 |
| mcp__github__run_secret_scanning | github | 509 |
| mcp__github__search_code | github | 465 |
| mcp__github__search_commits | github | 588 |
| mcp__github__search_issues | github | 471 |
| mcp__github__search_pull_requests | github | 484 |
| mcp__github__search_repositories | github | 451 |
| mcp__github__search_users | github | 346 |
| mcp__github__sub_issue_write | github | 617 |
| mcp__github__subscribe_pr_activity | github | 351 |
| mcp__github__unresolve_review_thread | github | 217 |
| mcp__github__unsubscribe_pr_activity | github | 239 |
| mcp__github__update_pull_request | github | 403 |
| mcp__github__update_pull_request_branch | github | 223 |
| mcp__GuruFocus__gurufocus_get_economic_list | GuruFocus | 465 |
| mcp__GuruFocus__gurufocus_get_etf_list | GuruFocus | 438 |
| mcp__GuruFocus__gurufocus_get_gurus_list | GuruFocus | 493 |
| mcp__GuruFocus__gurufocus_get_industry_list | GuruFocus | 296 |
| mcp__GuruFocus__gurufocus_get_mutual_fund_list | GuruFocus | 563 |
| mcp__GuruFocus__gurufocus_list_routes | GuruFocus | 81 |

### Memory Files

| Type | Path | Tokens |
|------|------|--------|
| Project | /home/user/m2.0-interactive/CLAUDE.md | 1.4k |

### Skills

| Skill | Source | Tokens |
|-------|--------|--------|
| alpha-vantage-market-data | User | ~160 |
| canvas-design | User | ~100 |
| deep-research | User | ~90 |
| docx | User | ~280 |
| finnhub-market-data | User | ~200 |
| firecrawl | User | ~110 |
| fmp-fundamentals | User | ~220 |
| karpathy-llm-wiki | User | ~90 |
| learn | User | ~330 |
| mcp-builder | User | ~100 |
| morning | User | ~120 |
| pdf | User | ~150 |
| pptx | User | ~250 |
| secedgar-filings | User | ~180 |
| startup-hook-skill | User | ~90 |
| skill-creator | User | ~110 |
| stock-analysis | User | ~200 |
| whale-rock-tracker | User | ~160 |
| xlsx | User | ~320 |
| yahoo-finance-research | User | ~180 |
| checkpoint | Project | ~80 |
| domain-modeling | Project | ~90 |
| grill-me | Project | ~50 |
| project-memory | Project | ~130 |
| ship-now | Project | ~130 |
| spec | Project | ~90 |
| skills | Project | ~40 |
| dataviz | Built-in | ~380 |
| artifact-design | Built-in | ~20 |
| artifact-capabilities | Built-in | ~140 |
| update-config | Built-in | ~240 |
| keybindings-help | Built-in | ~80 |
| simplify | Built-in | ~60 |
| fewer-permission-prompts | Built-in | ~60 |
| loop | Built-in | ~110 |
| claude-api | Built-in | ~360 |
| run | Built-in | ~120 |
| init | Built-in | ~20 |
| review | Built-in | ~30 |
| security-review | Built-in | ~30 |

**Observation:** the bulk of "deferred" potential cost (138k) comes from 4 MCP
servers not used this session (Adobe_for_creativity ~80 tools, Figma ~25,
Firecrawl ~25, GuruFocus 6) — none touched during this /oven ticket-execution
work. If connector sprawl becomes a real (not just potential) cost concern,
disconnecting unused servers is the lever, not context-management changes here.
