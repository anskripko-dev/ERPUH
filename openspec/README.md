# OpenSpec — ERP УХ

Spec-driven development for customized 1С:ERP. Управление холдингом.

## Layout

```
openspec/
├── config.yaml
├── project.md          # project context for agents
├── specs/              # current behavior (source of truth)
└── changes/            # active change proposals
    └── archive/        # completed changes
```

## Slash commands (Cursor)

- `/opsx-propose` — create a change (proposal, specs, design, tasks)
- `/opsx-apply` — implement tasks from an active change
- `/opsx-archive` — archive a completed change
- `/opsx-explore` — explore without writing code
- `/opsx-sync` — sync delta specs into main specs

Reload the Cursor window after setup so commands appear.

## Workflow

```
/opsx-propose <idea>  →  /opsx-apply  →  /opsx-archive
```

Code is edited in EDT projects under `C:\EDTProjects\uh_np`.
