# Project Context

## Configuration

- Name: `УправлениеХолдингомERP`
- Synonym: 1С:ERP. Управление холдингом
- Vendor: Фирма "1С"
- Version: 3.2.8.25
- CompatibilityMode: 8.3.27
- Form mode: managed
- Script variant: Russian

## EDT projects (`C:\EDTProjects\uh_np`)

| EDT project | Type | Metadata name | Name prefix |
|-------------|------|---------------|-------------|
| `uhnp` | Main configuration | `УправлениеХолдингомERP` | — |
| `uhnp.НП` | Extension (Customization) | `НП` | `нп_` (legacy-объекты могут быть с `РасшНП_`) |
| `uhnp.ТН` | Extension (AddOn) | `ТН` | `тн_` |

Code paths (EDT):

- Main: `C:\EDTProjects\uh_np\uhnp\src\`
- Extension НП: `C:\EDTProjects\uh_np\uhnp.НП\src\`
- Extension ТН: `C:\EDTProjects\uh_np\uhnp.ТН\src\`

## Reference projects

- **БСП / SSL** (patterns, module structure, API style): `C:\Projects\SSL`
- **1C development standards**: `C:\Projects\Instructions\стандарты-разработки-1с.md`
- Other instructions in `C:\Projects\Instructions\` (СКД, внешние обработки, и т.д.) as needed

## This workspace (`C:\Projects\ERPUH`)

- OpenSpec planning home: specs, changes, Cursor commands/skills
- Does **not** contain the full UH configuration dump — code lives under `C:\EDTProjects\uh_np`

## Notes for AI Agents

- Prefer targeted searches in `uh_np` over full-tree scans (configuration is large).
- Follow 1C standards from `Instructions\стандарты-разработки-1с.md`.
- Prefer BSP patterns from SSL when choosing structure, naming, regions, and API style.
- Synonyms of native НП metadata objects end with `(НП)` (as in `нп_КонтрольПроведенияПоДО`). Forms, attributes, enum values and DCS field captions do not.
- Every task starts with an OpenSpec change (`/opsx-propose` → `/opsx-apply` → `/opsx-archive`).
- Customization: prefer extensions (`uhnp.НП`, `uhnp.ТН`) over editing the main config when the change belongs to an extension; respect name prefixes `РасшНП_` / `тн_`.
- New agent chats do not see prior conversation history — rely on this file and `.cursor/rules/`.
