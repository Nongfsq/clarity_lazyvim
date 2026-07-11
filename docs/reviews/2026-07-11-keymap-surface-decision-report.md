# Keymap Surface Decision Report

Date: 2026-07-11

Status: evidence-backed product-surface audit. This report makes no runtime
change and does not approve implementation by itself.

## Decision

Clarity should stop exposing the inherited LazyVim keymap set as if every
upstream utility were part of the product. The captured tracked-file lifecycle
contains 133 global normal-mode leader actions; a Lua buffer with `lua_ls` and
Gitsigns adds 20 buffer-local leader actions, for an effective union of 153
entries before which-key group metadata is excluded. The recommended target is
28 global leader actions plus seven normal-mode capability-scoped actions, with
no more than 35 actionable leader entries in the fullest reviewed Git+LSP
buffer. Visual selection search and formatting reuse the same action identities
without increasing normal-mode density.

That target is not achieved by hiding labels. Out-of-product mappings must be
explicitly disabled, retained aliases must converge on one named path, and every
Git observation entry must also remove mutation actions inside its picker or
tree. The last requirement corrects an important weakness in the proposed
observation-surface blueprint: the locked Snacks and Neo-tree Git interfaces are
not read-only merely because their opening leader key sounds observational.

## Scope And Terminology

This is a decision for every discoverable product shortcut observed in four
surfaces:

1. all 133 global normal-mode leader actions in a naturally opened tracked file;
2. all LSP and Gitsigns buffer-local leader actions in an attached Lua buffer;
3. Clarity/LazyVim-owned non-leader, insert, visual, operator, and terminal
   mappings relevant to editing, navigation, diagnostics, and review;
4. Neo-tree, Snacks picker, and ClarityStart buffer-local interfaces;
5. local controls inside retained Git picker/tree interfaces.

Neovim defaults, runtime mappings such as Matchit, `<Plug>` implementation
targets, and which-key prefix triggers are not Clarity product actions. They are
identified as upstream or metadata contracts instead of being counted as
promoted shortcuts. Component-internal controls outside the retained product
jobs remain upstream component contracts and are not advertised by Clarity.

Decision vocabulary:

| Decision | Meaning |
| --- | --- |
| **KEEP** | Keep the current product mapping and behavior. |
| **DYNAMIC** | Keep only when the relevant buffer capability is present. |
| **MERGE** | Remove this alias; preserve the named canonical action. |
| **REMOVE** | Remove from the default product mapping/menu surface. |
| **REBUILD** | Keep the user job, but replace or constrain the current unsafe/ambiguous handler before promotion. |
| **GATE** | Keep temporarily until a named behavior/parity test decides removal. |
| **UPSTREAM** | Preserve the native/upstream mapping without presenting it as a Clarity action. |
| **META** | Prefix or which-key metadata, not an actionable shortcut. |

## Source Selection

| Source | Role | Why it is authoritative here |
| --- | --- | --- |
| Natural runtime captures for `README.md` and `nvim/lua/config/keymaps.lua` | Primary runtime evidence | Captures effective maps after real startup, Git attachment, and `lua_ls` attachment rather than inferring only from source. |
| `nvim/lua/config/keymaps.lua` and `nvim/lua/plugins/{git,terminal,neo-tree}.lua` | Primary Clarity source | Defines Clarity-owned additions and ownership boundaries. |
| Locked LazyVim, Snacks, Gitsigns, and Neo-tree checkouts under the Neovim data root | Primary dependency source | Matches the locally resolved lock snapshot and exposes inherited and component-local behavior. |
| `docs/product/clarity-agent-era-review-console-pm.md` and the 2026-07-11 observation blueprint | Product/architecture context | Establishes review-first, observation-only Git, bilingual, and low-density requirements. |
| Owner workflow statement | Primary product evidence | Repository mutation is performed through Codex; Neovim needs only status, changes, history, branch topology, and provenance. |

No web search was used. Current upstream documentation cannot override the
behavior of the exact locked code executed by this repository, and the question
is a product-boundary decision rather than a survey of unpinned alternatives.

## Tool Plan

- Capture effective global and buffer maps through a naturally attached TUI.
- Compare a Markdown buffer with an attached Lua/LSP/Git buffer.
- Inspect the exact locked dependency sources for mapping ownership and hidden
  mutation paths.
- Cross-check repository code, product requirements, and prior architecture.
- Use independent leader, contextual, and counter-audit lanes; integrate only
  findings supported by reproducible source/runtime evidence.

## Agent Orchestration

Three temporary read-only review lanes were used. No `.codex/agents` or agent
configuration was changed.

| Lane | Responsibility | Integration rule |
| --- | --- | --- |
| Global leader inventory | Enumerate and decide every captured global leader action | Every key must receive one explicit decision and canonical destination. |
| Context inventory | Audit LSP, Gitsigns, structural, insert, and terminal mappings | Separate capability-scoped value from global menu density. |
| Counter-audit | Challenge deletion assumptions and inspect internal component controls | Any hidden mutation or lost core workflow overrides a superficial “keep” decision. |

## Evidence Summary

| Evidence ID | Observation | Result |
| --- | --- | ---: |
| E-001 | Natural tracked Markdown buffer: all captured map rows | 383 |
| E-002 | Natural tracked Lua buffer with `lua_ls`: all captured map rows | 453 |
| E-003 | Global normal-mode leader actions in both file lifecycles | 133 |
| E-004 | Buffer-local normal leader actions in tracked Markdown / Lua+LSP | 11 / 20 |
| E-005 | Effective global + Lua buffer-local normal leader union | 153 |
| E-006 | Proposed actionable global / fullest-context leader target | 28 / 35 |
| E-007 | Locked Snacks Git status/diff local controls | `<Tab>` stages/unstages; `<C-r>` restores/discards |
| E-008 | Locked Snacks Git log/file/line confirm | executes `git checkout`, including checkout of a historical file |
| E-009 | Locked Snacks branch picker controls | Enter checks out; `<C-a>` creates; `<C-x>` deletes |
| E-010 | Locked Neo-tree Git source controls | add, unstage, revert, commit, push, pull, commit-and-push |
| E-011 | Product-relevant non-picker mode+key entries | 261: keep 69, dynamic 50, remove 118, merge 5, upstream 19 |
| E-012 | Neo-tree local entries | 70: 58 normal, 6 visual, 6 select |
| E-013 | One naturally opened Snacks files picker | 134 local map rows across its windows/modes |
| E-014 | ClarityStart contextual entries | 20 |

The 453 Lua-buffer rows and the contextual rows are not one flat count of unique
user jobs. They include duplicated modes,
Neovim defaults, Matchit `<Plug>` targets, pairs, and prefix metadata. The audit
therefore counts actionable public leader entries separately while preserving
native editor behavior.

## Findings

### F-001 — The public leader surface is inherited, not curated

- **Evidence:** E-001 through E-005 and Appendix A.
- **Confidence:** high.
- **Finding:** 133 global leader actions advertise tabs, profiler, scratch,
  maintainer utilities, plugin management, GitHub workflows, redundant search
  paths, and 25 toggles beside core editing jobs.
- **Caveat:** map count alone is not proof of bad UX; the per-key job and
  duplication review supplies the decision.
- **Impact:** high. A product-specific menu cannot be learned while inherited
  compatibility is indistinguishable from the supported path.

### F-002 — Hiding a mapping is not deletion

- **Evidence:** effective runtime capture and locked LazyVim specifications.
- **Confidence:** high.
- **Finding:** removing a which-key label while leaving the mapping callable
  preserves collisions, documentation drift, and accidental execution.
- **Caveat:** native Neovim mappings are intentionally preserved; the rule
  applies to inherited product-incompatible plugin/LazyVim actions.
- **Impact:** high. Implementation needs explicit disable specifications and
  behavior tests, not presentation-only filtering.

### F-003 — Existing Git “view” interfaces contain write operations

- **Evidence:** E-007 through E-010; locked Snacks `config/sources.lua` and
  `actions.lua`; locked Neo-tree `defaults.lua`.
- **Confidence:** high.
- **Finding:** status, diff, log, branch, and Git-tree interfaces contain stage,
  restore, checkout, create/delete branch, commit, push, and pull controls.
- **Caveat:** blame and Gitsigns hunk preview/navigation are observational and
  can remain when their attached mutation mappings are disabled.
- **Impact:** critical. `<leader>gs`, `<leader>gd`, and `<leader>gl` are
  **REBUILD**, not direct **KEEP**. `<leader>ge` is removed. A read-only wrapper
  must override confirm and local keys, or a bounded Clarity renderer must
  replace the picker.

### F-004 — Context-specific code actions are valuable but should not be global

- **Evidence:** E-004, Appendix B, and attached `lua_ls` runtime.
- **Confidence:** high.
- **Finding:** rename, code action, document/workspace symbols, and hunk preview
  are useful only when an attached capability can perform them.
- **Caveat:** code actions may mutate the current file; that is allowed as a
  deliberate precision edit, unlike repository mutation. Their label must say
  what scope is affected.
- **Impact:** medium-high. Dynamic maps keep the global surface small without
  making capable buffers weaker.

### F-005 — Native keys should carry native jobs

- **Evidence:** runtime mappings for `K`, `gra`, `gri`, `grn`, `grr`, `grt`,
  `gO`, diagnostic bracket navigation, comments, search, and URI opening.
- **Confidence:** high.
- **Finding:** leader aliases for keyword help, line diagnostics, command/search
  history, registers, marks, jumps, and several LSP actions duplicate native or
  upstream paths.
- **Caveat:** native discoverability still needs concise Chinese/English help;
  it does not require duplicate product mappings.
- **Impact:** medium. Preserving native semantics reduces custom surface and
  improves portability.

### F-006 — A smaller catalog is the localization fix

- **Evidence:** current exact-English description translation, zero observed
  `ClarityLocaleChanged` events after a live locale change, and untranslated
  buffer-local maps.
- **Confidence:** high.
- **Finding:** every retained product action needs a stable ID and English/
  Chinese labels; buffer-local actions must use the same catalog. Translating
  arbitrary inherited descriptions cannot stay complete.
- **Caveat:** component-internal help may remain upstream English until a
  retained component receives a product adapter.
- **Impact:** high. The 35-action fullest-context target makes complete, testable bilingual
  presentation practical.

### F-007 — Neo-tree and picker controls are the largest hidden surface

- **Evidence:** E-012 and E-013.
- **Confidence:** high for the observed macOS lifecycle; medium for keyboard
  reachability on every terminal/OS.
- **Finding:** Neo-tree exposes 70 local mode+key entries and one ordinary
  Snacks files picker exposes 134. These controls are absent from a global
  leader count but dominate what users encounter after opening a core tool.
- **Caveat:** mode duplicates and mouse aliases are not separate user jobs, and
  some controls are capability-dependent.
- **Impact:** high. Neo-tree needs a curated mapping profile with a target of
  20–24 visible actions; each core picker needs at most 20 contextual actions.

### F-008 — File mutation needs an explicit decision separate from Git mutation

- **Evidence:** Neo-tree defaults include create directory/file, rename, delete,
  trash, copy, move, cut, paste, and LSP-aware rename paths.
- **Confidence:** high on the implementation; medium on the final product policy.
- **Finding:** Git mutation is explicitly out of scope. Filesystem mutation is
  related but not identical: new file and small structural changes can still be
  precision editing.
- **Caveat:** the owner has not yet stated as explicitly that every file create,
  rename, copy, move, and delete must be agent-only.
- **Impact:** high. These keys are **GATE**, not silently retained and not
  deleted by inference. The PM must name whether precision edit includes file
  structure changes before implementation.

## Appendix A — Every Global Normal Leader Action

The canonical target in the “Destination” column names the only path that should
remain. Visual-mode duplicates inherit the same decision.

### Root, tabs, and buffers

| Key | Current action | Decision | Destination / reason |
| --- | --- | --- | --- |
| `<leader><space>` | Find Files | MERGE | `<leader>ff` |
| `<leader>,` | Buffers | MERGE | `<leader>fb` |
| `<leader>-` | Split below | KEEP | Core window layout |
| `<leader>.` | Toggle scratch | REMOVE | Non-core scratch workflow |
| `<leader>/` | Grep root | MERGE | `<leader>fw` |
| `<leader>:` | Command history | REMOVE | Native `q:` |
| `<leader><Tab><Tab>` | New tab | REMOVE | Remove full promoted tab workflow |
| `<leader><Tab>[` | Previous tab | REMOVE | Same |
| `<leader><Tab>]` | Next tab | REMOVE | Same |
| `<leader><Tab>d` | Close tab | REMOVE | Same |
| `<leader><Tab>f` | First tab | REMOVE | Same |
| `<leader><Tab>l` | Last tab | REMOVE | Same |
| `<leader><Tab>o` | Close other tabs | REMOVE | Same |
| `<leader>?` | Buffer keymaps | KEEP | Context-local key discovery; distinct from the global catalog |
| `<leader>E` | Explorer at cwd | KEEP | Explicit cwd inspection |
| `<leader>K` | Keywordprg | REMOVE | Native `K`/LSP hover |
| `<leader>L` | LazyVim changelog | REMOVE | Maintainer surface |
| `<leader>S` | Select scratch | REMOVE | Scratch workflow removed |
| `<leader>\`` | Other buffer | MERGE | `<leader>fb` |
| `<leader>bD` | Delete buffer and window | MERGE | `<leader>bd` plus explicit window action |
| `<leader>bb` | Other buffer | MERGE | `<leader>fb` |
| `<leader>bd` | Delete buffer | KEEP | Core buffer lifecycle |
| `<leader>be` | Buffer explorer | MERGE | `<leader>e` |
| `<leader>bi` | Delete invisible buffers | REMOVE | Bulk maintenance |
| `<leader>bo` | Delete other buffers | REMOVE | Bulk maintenance |

### Code and diagnostics

| Key | Current action | Decision | Destination / reason |
| --- | --- | --- | --- |
| `<leader>cF` | Format injected languages | REMOVE | Specialist formatting path |
| `<leader>cd` | Line diagnostics | REMOVE | Native `<C-w>d`, `[d`, `]d` |
| `<leader>cf` | Format | KEEP | Deliberate current-buffer formatting |
| `<leader>cm` | Mason | REMOVE | Agent/toolchain maintenance |
| `<leader>cz` | Toggle current fold | KEEP | Core review/readability action |
| `<leader>dph` | Profiler highlights | REMOVE | Maintainer/developer utility |
| `<leader>dpp` | Profiler | REMOVE | Same |
| `<leader>dps` | Profiler scratch | REMOVE | Same |

### Explorer, files, search roots, and terminal aliases

| Key | Current action | Decision | Destination / reason |
| --- | --- | --- | --- |
| `<leader>e` | Explorer at project root | KEEP | Canonical project tree |
| `<leader>fB` | All buffers | MERGE | `<leader>fb` |
| `<leader>fE` | Explorer at cwd | MERGE | `<leader>E` |
| `<leader>fF` | Files at cwd | MERGE | `<leader>ff`; picker can change root explicitly |
| `<leader>fR` | Recent at cwd | MERGE | `<leader>fr` |
| `<leader>fT` | Terminal at cwd | MERGE | `<leader>tf` |
| `<leader>fb` | Buffers | KEEP | Canonical open-buffer navigation |
| `<leader>fc` | Find config | REMOVE | Maintainer surface |
| `<leader>fe` | Explorer at root | MERGE | `<leader>e` |
| `<leader>ff` | Find files | KEEP | Canonical file navigation |
| `<leader>fg` | Git files | MERGE | `<leader>ff` |
| `<leader>fn` | New file | KEEP | Small deliberate edit workflow |
| `<leader>fp` | Projects | REMOVE | Multi-project launcher outside core |
| `<leader>fr` | Recent files | KEEP | Review resumption |
| `<leader>ft` | Terminal at root | MERGE | `<leader>tf` |
| `<leader>fw` | Search text | KEEP | Canonical project text search |

### Git

| Key | Current action | Decision | Destination / reason |
| --- | --- | --- | --- |
| `<leader>gB` | Browse/open remote | REMOVE | Forge/browser workflow outside core |
| `<leader>gD` | Diff against origin | MERGE | Rebuilt `<leader>gd` with explicit base |
| `<leader>gG` | Lazygit at cwd | REMOVE | Mutation-heavy external client |
| `<leader>gI` | All GitHub issues | REMOVE | Agent/forge workflow |
| `<leader>gL` | Log at cwd | MERGE | Rebuilt `<leader>gl` |
| `<leader>gP` | All GitHub PRs | REMOVE | Agent/forge workflow |
| `<leader>gS` | Stash | REMOVE | Repository mutation |
| `<leader>gY` | Copy remote URL | REMOVE | Forge/browser utility |
| `<leader>gb` | Blame line | REBUILD | Current `git_log_line` confirm can checkout a file; use Gitsigns/readonly provenance |
| `<leader>gd` | Diff hunks | REBUILD | Preserve diff job; remove stage/restore local keys |
| `<leader>ge` | Git explorer | REMOVE | Neo-tree source exposes mutation and source switching |
| `<leader>gf` | Current-file history | MERGE | Rebuilt `<leader>gl`, scoped to current file |
| `<leader>gg` | Lazygit at root | REMOVE | Mutation-heavy external client |
| `<leader>gi` | Open GitHub issues | REMOVE | Agent/forge workflow |
| `<leader>gl` | Git log | REBUILD | Preserve history; Enter must inspect, never checkout |
| `<leader>gp` | Open GitHub PRs | REMOVE | Agent/forge workflow |
| `<leader>gs` | Git status | REBUILD | Preserve status; remove stage/restore local keys |

The target adds one new `<leader>gt` branch-graph action. It is **REBUILD** from
the outset: use bounded read-only `git log --graph --decorate --oneline --all`
with argv execution and no checkout/create/delete controls. Do not expose the
locked Snacks branch picker unchanged.

### Help, lifecycle, search, and lists

| Key | Current action | Decision | Destination / reason |
| --- | --- | --- | --- |
| `<leader>hh` | Clarity start/help | KEEP | One human recovery/help hub |
| `<leader>l` | Lazy | REMOVE | Dependency maintenance belongs to agents |
| `<leader>n` | Notification history | MERGE | Clarity Health/log view |
| `<leader>qq` | Quit all | KEEP | Explicit application exit |
| `<leader>s"` | Registers | REMOVE | Native registers |
| `<leader>s/` | Search history | REMOVE | Native `q/` |
| `<leader>sB` | Grep open buffers | MERGE | `<leader>fw` with scope/filter |
| `<leader>sC` | Commands | REMOVE | Native `:` |
| `<leader>sD` | Buffer diagnostics | MERGE | `<leader>sd` with scope |
| `<leader>sG` | Grep cwd | MERGE | `<leader>fw` |
| `<leader>sH` | Highlights | REMOVE | Maintainer utility |
| `<leader>sM` | Man pages | REMOVE | Specialist lookup; shell/native help remains |
| `<leader>sR` | Resume picker | REMOVE | Hidden picker state is not a core job |
| `<leader>sW` | Word/selection at cwd | MERGE | Mode-aware `<leader>fw` |
| `<leader>sa` | Autocmds | REMOVE | Maintainer utility |
| `<leader>sb` | Buffer lines | REMOVE | `/` or canonical text search |
| `<leader>sc` | Command history | REMOVE | Native `q:` |
| `<leader>sd` | Diagnostics | KEEP | Canonical problem review |
| `<leader>sg` | Grep root | MERGE | `<leader>fw` |
| `<leader>sh` | Help pages | REMOVE | `<leader>hh` plus native help |
| `<leader>si` | Icons | REMOVE | Maintainer utility |
| `<leader>sj` | Jumps | REMOVE | Native `<C-o>`/`<C-i>` |
| `<leader>sk` | Keymaps | KEEP | Discoverability/audit |
| `<leader>sl` | Location list | REMOVE | One promoted problem-list model |
| `<leader>sm` | Marks | REMOVE | Native marks |
| `<leader>sn` | Noice group | REMOVE | Presentation adapter is not a product namespace |
| `<leader>sna` | All Noice messages | REMOVE | Clarity Health/log |
| `<leader>snd` | Dismiss Noice messages | REMOVE | Same |
| `<leader>snh` | Noice history | REMOVE | Same |
| `<leader>snl` | Last Noice message | REMOVE | Same |
| `<leader>snt` | Noice picker | REMOVE | Same |
| `<leader>sp` | Plugin specs | REMOVE | Maintainer utility |
| `<leader>sq` | Quickfix list | MERGE | `<leader>xq` |
| `<leader>su` | Undotree | REMOVE | Specialist history UI; native undo remains |
| `<leader>sw` | Search word/selection | MERGE | Normal mode folds into mode-aware `<leader>fw`; visual selection remains dynamic |

### Terminal, toggles, windows, and problem list

| Key | Current action | Decision | Destination / reason |
| --- | --- | --- | --- |
| `<leader>tf` | Floating terminal | KEEP | Canonical bounded shell escape hatch |
| `<leader>uA` | Tabline | REMOVE | Presentation tuning |
| `<leader>uC` | Colorschemes | REMOVE | Theme is product policy |
| `<leader>uD` | Dimming | REMOVE | Presentation tuning |
| `<leader>uF` | Buffer autoformat | DYNAMIC | Register only in ordinary editable buffers as local recovery |
| `<leader>uG` | Git signs | REMOVE | Review signs are product policy |
| `<leader>uI` | Inspect tree | REMOVE | Maintainer utility |
| `<leader>uL` | Relative numbers | REMOVE | Conflicts with absolute-line-number contract |
| `<leader>uS` | Smooth scroll | REMOVE | Presentation tuning |
| `<leader>uT` | Tree-sitter highlight | REMOVE | Recovery belongs in Health |
| `<leader>uZ` | Zoom | REMOVE | Duplicate window presentation path |
| `<leader>ua` | Animations | REMOVE | Presentation tuning |
| `<leader>ub` | Dark background | REMOVE | Theme is product policy |
| `<leader>uc` | Conceal level | REMOVE | Specialist presentation tuning |
| `<leader>ud` | Diagnostics | REMOVE | Diagnostics are a trustworthy default; recovery moves to Health |
| `<leader>uf` | Global autoformat | REMOVE | Must not override project policy globally |
| `<leader>ug` | Indent guides | REMOVE | Presentation policy |
| `<leader>uh` | Inlay hints | DYNAMIC | Contextual readability control only when LSP supports it |
| `<leader>ui` | Inspect position | REMOVE | Maintainer utility |
| `<leader>ul` | Line numbers | REMOVE | Absolute numbers remain a stable product contract |
| `<leader>un` | Dismiss notifications | REMOVE | Clarity Health/log owns recovery |
| `<leader>up` | Mini pairs | REMOVE | Internal edit policy, behavior-tested rather than menu-tuned |
| `<leader>ur` | Redraw/clear/update | REMOVE | Native `<C-l>`/`<Esc>` |
| `<leader>us` | Spelling | REMOVE | Non-core specialist toggle |
| `<leader>uw` | Wrap | KEEP | Core readability action |
| `<leader>uz` | Zen mode | REMOVE | Presentation mode |
| `<leader>wd` | Delete window | KEEP | Core window lifecycle |
| `<leader>wm` | Zoom window | KEEP | Single reversible low-vision/small-screen layout aid |
| `<leader>wo` | Keep current window | KEEP | Core layout cleanup |
| `<leader>xl` | Location list | REMOVE | One promoted problem-list model |
| `<leader>xq` | Quickfix list | KEEP | Canonical shared result list |
| `<leader>|` | Split right | KEEP | Core window layout |

### Visual-mode leader duplicates

| Key | Decision | Reason |
| --- | --- | --- |
| `<leader>cF` | REMOVE | Same as normal mode |
| `<leader>cf` | KEEP | Format deliberate selection |
| `<leader>gB` | REMOVE | Forge/browser workflow |
| `<leader>gY` | REMOVE | Forge/browser utility |
| `<leader>sW` | MERGE | Visual `<leader>sw` |
| `<leader>sw` | DYNAMIC | Search selected text |

## Appendix B — Every Contextual Leader Action

The `<leader>` row installed by which-key is **META**, not an action.

| Key | Context action | Decision | Destination / reason |
| --- | --- | --- | --- |
| `<leader>cA` | Source action | REMOVE | Low-frequency specialist LSP operation |
| `<leader>cC` | Refresh/display codelens | REMOVE | Specialist LSP operation |
| `<leader>cR` | Rename file | REMOVE | Broad file/workspace mutation belongs to agent workflow |
| `<leader>ca` | Code action | DYNAMIC | Deliberate local precision edit |
| `<leader>cc` | Run codelens | REMOVE | Specialist LSP operation |
| `<leader>cl` | LSP info | MERGE | Clarity Health capability view |
| `<leader>cr` | Rename symbol | DYNAMIC | Deliberate semantic precision edit |
| `<leader>ghB` | Blame buffer | REMOVE | Line provenance is sufficient |
| `<leader>ghD` | Diff against previous revision | REMOVE | Rebuilt global diff action owns scope/base |
| `<leader>ghR` | Reset buffer | REMOVE | Destructive repository mutation |
| `<leader>ghS` | Stage buffer | REMOVE | Repository mutation |
| `<leader>ghb` | Blame line | MERGE | Global `<leader>gb` |
| `<leader>ghd` | Diff file | MERGE | Rebuilt global `<leader>gd` |
| `<leader>ghp` | Preview hunk | DYNAMIC | Read-only local review |
| `<leader>ghr` | Reset hunk | REMOVE | Destructive repository mutation |
| `<leader>ghs` | Stage hunk | REMOVE | Repository mutation |
| `<leader>ghu` | Undo stage | REMOVE | Repository mutation |
| `<leader>sS` | Workspace symbols | DYNAMIC | Cross-file structural navigation |
| `<leader>ss` | Document symbols | DYNAMIC | Current-file structural navigation |

Visual-mode `<leader>ca` remains **DYNAMIC**. Visual `<leader>cc`,
`<leader>ghr`, and `<leader>ghs` inherit **REMOVE**.

## Appendix C — Non-Leader And Editing Contracts

### Global normal-mode product mappings

| Key(s) | Current job | Decision | Reason |
| --- | --- | --- | --- |
| `<C-/>`, `<C-_>` | Terminal / encoded alias | MERGE | `<leader>tf`; retain only terminal-local escape/navigation controls |
| `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | Move across windows | KEEP | Fast, accessibility-friendly window navigation |
| `<C-Up>`, `<C-Down>`, `<C-Left>`, `<C-Right>` | Resize windows | REMOVE | Terminal portability is poor; one zoom plus window commands cover the core job |
| `<C-s>` | Save | KEEP | GUI-editor migrant affordance |
| `<Up>`, `<Down>`, `j`, `k` | Move by display line under wrap | KEEP | Required wrap + absolute-line-number behavior |
| `<Esc>` | Clear search highlight | KEEP | Calm recovery |
| `<M-j>`, `<M-k>` | Move line/selection | REMOVE | Terminal Option/Alt portability is poor; native edits remain |
| `H`, `L` | Previous/next buffer | REMOVE | Restore valuable native window-top/bottom motions |
| `[b`, `]b` | Previous/next buffer | KEEP | One bracket-consistent direct buffer pair |
| `[d`, `]d` | Previous/next diagnostic | KEEP | Canonical diagnostic navigation |
| `[e`, `]e`, `[w`, `]w` | Previous/next error/warning | REMOVE | Duplicate severity-specific paths |
| `[D`, `]D` | First/last diagnostic | REMOVE | Low-frequency endpoint aliases |
| `[q`, `]q` | Previous/next quickfix | KEEP | Canonical result navigation |
| `[l`, `]l` | Previous/next location list | REMOVE | Location-list public surface removed |
| `gc`, `gcc` | Comment selection/line | KEEP | Core precision edit |
| `gcO`, `gco` | Add empty comment above/below | REMOVE | Low-frequency comment aliases |
| `n`, `N` | Next/previous search result | UPSTREAM | Preserve search behavior |
| `gO` | Document symbols | UPSTREAM | Native LSP navigation; do not duplicate globally |
| `gra`, `gri`, `grn`, `grr`, `grt`, `grx` | Native LSP action family | UPSTREAM | Preserve Neovim capability contract |
| `gx` | Open path/URI | UPSTREAM | Native explicit external-open behavior |
| `<C-w>d`, `<C-w><C-d>` | Diagnostics under cursor | UPSTREAM | Native diagnostic inspection |

Neovim 0.12 bracket families for argument, buffer, location, quickfix, tag, and
preview-list navigation (`[a`/`]a`, `[A`/`]A`, `[B`/`]B`, `[L`/`]L`,
`[Q`/`]Q`, `[T`/`]T`, `[t`/`]t`, and their control-key variants) remain
**UPSTREAM**. Clarity neither advertises nor disables them.

### Attached LSP, Git, and structure mappings

| Key(s) | Current job | Decision | Reason |
| --- | --- | --- | --- |
| `K`, `gd`, `gr` | Hover, definition, references | DYNAMIC | Core semantic review when supported |
| `gI`, `gy`, `gD` | Implementation/type/declaration aliases | MERGE | Native `gri`/`grt` and the primary definition path |
| `gK` | Signature help | REMOVE | Insert `<C-k>` owns this job while editing |
| `[[`, `]]` | Previous/next reference | DYNAMIC | Semantic review navigation |
| `<M-p>`, `<M-n>` | Previous/next reference | REMOVE | Duplicate of `[[`/`]]` |
| `[h`, `]h` | Previous/next hunk | DYNAMIC | Read-only change navigation |
| `[H`, `]H` | First/last hunk | REMOVE | Low-frequency endpoint aliases |
| `[c`, `]c`, `[f`, `]f` | Previous/next class/function start | DYNAMIC | Structural review navigation |
| `[C`, `]C`, `[F`, `]F` | Previous/next class/function end | REMOVE | Excess structural variants |
| `[a`, `]a`, `[A`, `]A` | Parameter start/end navigation | REMOVE | Specialist density; symbols/references cover core jobs |
| `an`, `in` | Outer/inner syntax node textobject | UPSTREAM | Preserve Neovim selection-range fallback, do not re-own |
| `[n`, `]n`, `[N`, `]N` | Node/sibling visual selection | KEEP | Structural review expansion/navigation |
| `ih` | Gitsigns hunk textobject | REMOVE | Specialist selection surface; hunk preview/navigation remain |
| `\\r` | Run Lua | REMOVE | Maintainer/code-execution surface |

### Insert and terminal mappings

| Key(s) | Current job | Decision | Reason |
| --- | --- | --- | --- |
| Insert `<C-k>` | Signature help | DYNAMIC | Contextual editing assistance |
| Insert `<Tab>`, `<S-Tab>` | Native snippet jump fallback | GATE | Retain until friendly-snippets/completion A/B test proves parity |
| Pair keys, `<BS>`, `<CR>` | mini.pairs insertion behavior | GATE | Keep only while real edit fixtures show no unwanted mutation |
| Terminal `<Esc>` | Leave terminal insert mode | KEEP | Required recovery |
| Terminal `<C-h/j/k/l>` | Window navigation | KEEP | Same navigation model as editor windows |
| Terminal `<C-w>` | Native window prefix | KEEP | Escape hatch for window commands |

## Appendix D — Neo-tree Local Profile

The observed Neo-tree buffer has 70 mode+key entries. The table lists every
resolved public key or same-action key family; visual/select duplication is
shown together.

| Key(s) | Current job | Decision |
| --- | --- | --- |
| `<CR>`, `<2-LeftMouse>` | Open/toggle | KEEP; canonical open action |
| `<Esc>`, `q` | Cancel/close | KEEP; one per relevant mode |
| `<BS>`, `.`, `C`, `z` | Parent, set root, close node/all | KEEP |
| `/`, `<C-x>`, `H` | Find/filter, clear filter, hidden files | KEEP; capability-aware |
| `P`, `<C-b>`, `<C-f>` | Preview and scroll | KEEP |
| `R`, `[g`, `]g`, `i`, `?` | Refresh, changed-file navigation, details, help | KEEP |
| `Y` | Copy displayed path | KEEP; observation/export, not file mutation |
| `l` | Focus preview/open alias | MERGE into `<CR>`/`P` |
| `<C-s>` | Quick jump | REMOVE; conflicts with global save semantics |
| `<Tab>`, `<C-;>` and visual/select `<Tab>`, `T`, `U`, `d`, `x`, `y` | Multi-selection/clipboard operation | REMOVE from curated profile |
| `<space>` | Toggle node alias | MERGE into `<CR>` |
| `S`, `s`, `t`, `w` | Split/vsplit/tab/window-picker opening | REMOVE except one split path supplied by the global window model |
| `e` | Auto-expand width | REMOVE; presentation tuning |
| `<`, `>` | Previous/next source | REMOVE; otherwise Git mutation source remains reachable |
| `#`, `D`, `f` | Alternate finder/filter paths | REMOVE; keep `/` |
| `o`, `oc`, `od`, `og`, `om`, `on`, `os`, `ot` | Help/sort submenu | REMOVE; one stable product ordering |
| `O` when supplied by an extension | External/system open | REMOVE from default product surface |
| `a`, `A`, `b`, `r` | Create file/dir, basename/full rename | GATE on filesystem-mutation policy |
| `d`, `T`, `u`, `U` | Delete, trash, undo/restore trash | GATE; destructive recovery test required if retained |
| `y`, `x`, `p`, `<C-r>`, `c`, `m` | Copy/cut/paste/clear/copy-to/move | GATE on filesystem-mutation policy |
| Git source `A`, `gu`, `gU`, `ga`, `gt`, `gr`, `gc`, `gp`, `gl`, `gg` | Git write operations | REMOVE unconditionally |

The fuzzy-filter popup should keep arrows or `j`/`k`, one cancel, confirm, and
clear/keep-filter outcomes. Its duplicate `<C-n>/<C-p>`, shifted Enter, and
control-Enter paths should be collapsed by mode rather than copied into the
product catalog.

## Appendix E — Snacks Picker Local Profile

A naturally opened files picker produced 134 map rows: one layout map, 43 input
normal, 40 input insert, 44 list normal, two list visual, and four preview maps.
The following decision covers every configured key in the locked default
profile; a key appearing in input and list inherits the same decision unless a
mode-specific exception is stated.

| Keys | Current job family | Decision |
| --- | --- | --- |
| `<CR>`, `<2-LeftMouse>` | Confirm | KEEP |
| `<Esc>`, `q`, input `<C-c>` | Cancel | MERGE by mode: one keyboard cancel plus mouse-independent escape |
| `/`, list `i` | Move focus between input/list | KEEP |
| `j`, `k`, `<Down>`, `<Up>`, `<C-j>`, `<C-k>`, `<C-n>`, `<C-p>` | List navigation aliases | MERGE: normal keeps `j/k` + arrows; insert keeps arrows + `<C-n>/<C-p>` |
| `gg`, `G` | List top/bottom | KEEP |
| `<C-d>`, `<C-u>`, `zb`, `zt`, `zz` | List scrolling/position aliases | MERGE into one page pair plus top/bottom |
| `<C-Up>`, `<C-Down>` | Query history | KEEP |
| `<C-b>`, `<C-f>`, `<a-p>` | Preview scroll/toggle | KEEP |
| `<a-h>`, `<a-i>`, `<a-r>`, `<C-g>` toggle-live | Hidden/ignored/regex/live | DYNAMIC by source capability |
| `?` | Context help | KEEP and localize from the action catalog |
| `<Tab>`, `<S-Tab>`, `<C-a>` | Select next/previous/all | REMOVE from single-result core pickers |
| `<C-q>` | Export to quickfix | REMOVE from default picker profile |
| `<S-CR>`, `<C-s>`, `<C-v>`, `<C-t>` | Window picker/split/vsplit/tab | REMOVE; confirm opens in the active review window |
| `<a-d>`, `<a-f>`, `<a-m>`, `<a-w>` | Inspect/follow/maximize/cycle window | REMOVE maintainer/expert surface |
| `<C-w>H`, `<C-w>J`, `<C-w>K`, `<C-w>L>` | Move picker layout | REMOVE presentation tuning |
| `<C-r>#`, `<C-r>%`, `<C-r><C-a>`, `<C-r><C-f>`, `<C-r><C-l>`, `<C-r><C-p>`, `<C-r><C-w>` | Insert register/context values | REMOVE specialist input aliases |
| list `<C-g>` | Print path | REMOVE; selected-path export belongs to an explicit action if needed |
| input `<C-w>` | Delete word | UPSTREAM editing behavior |
| preview `<Esc>`, `q`, `i`, `<a-w>` | Cancel/focus/cycle | Keep cancel + focus; remove cycle-window alias |

Source-specific picker opts must override this base profile. In particular, Git
status/diff/log controls are governed by Appendix G and may not reintroduce a
removed mutation action.

## Appendix F — Start, Dashboard, And Command Surfaces

### ClarityStart local keys

| Keys | Job | Decision |
| --- | --- | --- |
| `q`, `<Esc>`, `<C-d>`, `<C-u>` | Close/scroll | KEEP |
| `f`, `w`, `e`, `b`, `t`, `k`, `l` | Files, text, tree, buffers, terminal, keymaps, language | KEEP; content migrates to Health overview |
| `a`, `v`, `c`, `s` | Audit, Validate, Clipboard, Sync | REMOVE from peer action list; merge recovery into Health |
| Markdown `[[`, `]]`, `gO` across inherited modes | Native document navigation | UPSTREAM; do not re-register |

### Dashboard keys

| Key | Job | Decision |
| --- | --- | --- |
| `f`, `g`, `r` | File, text, recent | KEEP |
| `n`, `q` | New file, quit | KEEP; basic and accessible, not maintainer noise |
| `h` | Health | ADD and localize |
| `p`, `c`, `x`, `l` | Projects, config, extras, Lazy | REMOVE |
| `s` | Restore session | REMOVE/absence-test while persistence is disabled |

The dashboard budget is at most six visible actions, not four: removing New
File and Quit would reduce accessibility without meaningfully reducing
maintenance.

### Clarity commands

| Command | Decision |
| --- | --- |
| `ClarityHealth` | KEEP and become the real unified human entry |
| `ClarityLanguage` | KEEP and refresh live surfaces |
| `ClarityStart` | One-release compatibility alias; overview moves into Health |
| `ClarityAudit` | One-release compatibility; preserve machine/JSON contract |
| `ClarityValidate` | Demote from human product surface; retain only meaningful machine contract |
| `ClarityClipboard` | One-release compatibility; recovery moves into Health |
| `ClaritySync` | Remove promotion, then delete after necessary recovery migration |
| `ClarityLog` | Do not hard-delete; move path/export/events into Health and machine interface first |

Health needs one Messages view for native/Noice history and a distinct Clarity
diagnostic-events view. `ClarityLog` does not currently contain all Neovim or
plugin messages and is not an equivalent replacement by itself.

## Appendix G — Git Component-Local Controls

These controls are part of the shortcut audit even though they appear only after
opening a picker or tree.

| Interface | Local key/action | Decision |
| --- | --- | --- |
| Snacks `git_status` | `<Tab>` stage/unstage | REMOVE before `<leader>gs` can ship |
| Snacks `git_status` | `<C-r>` restore/discard | REMOVE before `<leader>gs` can ship |
| Snacks `git_diff` | `<Tab>` stage/unstage | REMOVE before `<leader>gd` can ship |
| Snacks `git_diff` | `<C-r>` restore/discard | REMOVE before `<leader>gd` can ship |
| Snacks `git_log`, `git_log_file`, `git_log_line` | Enter/confirm checkout | REBUILD as inspect/open-diff only |
| Snacks `git_branches` | Enter checkout | REMOVE from observation UI |
| Snacks `git_branches` | `<C-a>` create/checkout branch | REMOVE |
| Snacks `git_branches` | `<C-x>` delete branch | REMOVE |
| Neo-tree Git source | `A`, `ga`, `gu`, `gt` stage/unstage | REMOVE |
| Neo-tree Git source | `gr` revert | REMOVE |
| Neo-tree Git source | `gU` undo commit | REMOVE |
| Neo-tree Git source | `gc`, `gp`, `gl`, `gg` commit/push/pull/combinations | REMOVE |
| Neo-tree source switching | `<`, `>` can reach Git source | REBUILD/disable Git source, not only `<leader>ge` |

Acceptance must assert both mapping absence and repository immutability after
every retained Git UI interaction fixture. A label such as “status” or “log” is
not evidence of read-only behavior.

## Target Manifest

Proposed global leader actions after implementation:

```text
-  |  E  e  ?  bd  cf  cz  fb  ff  fn  fr  fw
gb*  gd*  gl*  gs*  gt*  hh  qq  sd  sk  tf
uw  wd  wm  wo  xq
```

`*` means the job is retained but the current Git handler must be rebuilt as a
zero-mutation interface. Normal-mode capability-scoped additions are `uF`,
`uh`, `ca`, `cr`, `ghp`, `ss`, and `sS`. This produces 28 global actions and at
most 35 actionable leader entries in the reviewed full context. Visual
`cf`/`sw` reuse formatting and search action identities. Which-key group labels
and prefix triggers do not count as actions.

Every manifest item must have:

- a stable action ID;
- English and Chinese labels;
- allowed modes and scopes;
- an explicit mutability class;
- a behavior test, not only a mapping-existence assertion;
- one canonical help entry and no undocumented promoted alias.

## Evaluation

| Dimension | Score | Basis |
| --- | ---: | --- |
| Evidence quality | 24 / 25 | Natural runtime captures plus exact locked source inspection |
| Source fit | 19 / 20 | Repository, runtime, locked dependencies, and owner workflow align |
| Reasoning and counter-evidence | 20 / 20 | Hidden Git mutation changed the initial keep decision |
| Decision usefulness | 19 / 20 | Every public leader and relevant contextual family has a destination |
| Reproducibility | 9 / 10 | Commands and evidence paths are supplied; capture harness was temporary |
| Caveat discipline | 5 / 5 | Does not claim release, cross-platform, or implementation evidence |
| **Total** | **96 / 100** | Decision-quality score, not product release score |

The remaining four points require implementation-bound behavior evidence from
the new action catalog, zero-mutation Git adapters, bilingual live refresh, and
the full platform/release gates. This report does not raise the product itself
to 96.

## What This Does Not Prove

- It does not prove that the proposed keys have been implemented or removed.
- It does not prove Windows, WSL, Linux, or clean-archive behavior.
- It does not certify every upstream component-internal navigation key; it
  audits the internal controls of retained Git jobs because they cross the
  product's mutation boundary.
- It does not prove that friendly-snippets, mini.pairs, LSP provisioning, Noice,
  or Lush can be removed; those remain named behavior gates.
- It does not accept or explain the unrelated local `lazy-lock.json` drift.

## Recommendation

Approve the corrected observation-surface blueprint, then create a PM/PLAN+TASK
for one atomic interaction-surface migration:

1. materialize the stable bilingual action catalog and explicit disable list;
2. implement the 28-action global manifest and seven normal-mode dynamic actions;
3. rebuild Git status/diff/log/graph as zero-mutation interfaces and disable the
   Neo-tree Git source path;
4. update help/dashboard/which-key from the catalog;
5. add natural lifecycle, bilingual refresh, collision, and repository-
   immutability behavior tests;
6. run the existing clean-archive release gate without changing its scoring or
   platform claims.

Do not combine this interaction migration with lockfile upgrades or dependency
removal. Those transactions need separate evidence and rollback.

## Evidence Index

| ID | Evidence location |
| --- | --- |
| E-001–E-005 | Temporary natural-runtime JSON captures produced from the current `main` worktree; summarized in this report before cleanup |
| E-007–E-009 | `$XDG_DATA_HOME/nvim/lazy/snacks.nvim/lua/snacks/picker/config/sources.lua` and `actions.lua` |
| E-010 | `$XDG_DATA_HOME/nvim/lazy/neo-tree.nvim/lua/neo-tree/defaults.lua` |
| Clarity mappings | `nvim/lua/config/keymaps.lua`, `nvim/lua/plugins/git.lua`, `nvim/lua/plugins/terminal.lua` |
| Product boundary | `docs/product/clarity-agent-era-review-console-pm.md` |
| Architecture context | `docs/architecture/2026-07-11-agent-era-observation-surface-blueprint.md` |

## Reproduction

Inspect the declared and inherited keymap sources:

```sh
rg -n "vim\.keymap\.set|keys =|<leader>|on_attach" \
  nvim/lua/config nvim/lua/plugins \
  "$HOME/.local/share/nvim/lazy/LazyVim/lua/lazyvim" \
  "$HOME/.local/share/nvim/lazy/gitsigns.nvim"
```

Inspect hidden Git mutation controls in the exact local locked sources:

```sh
rg -n "git_stage|git_restore|git_checkout|git_branch_add|git_branch_del" \
  "$HOME/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker"

rg -n "git_add|git_unstage|git_revert|git_commit|git_push|git_pull" \
  "$HOME/.local/share/nvim/lazy/neo-tree.nvim/lua/neo-tree"
```

Verify the repository documentation patch without touching runtime state:

```sh
git diff --check
rg -n "Keymap Surface Decision Report|28 global|zero-mutation" \
  docs docs/DOCUMENT_INDEX.md
```
