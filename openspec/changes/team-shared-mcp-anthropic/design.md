## Context

Сейчас в `ERPUH` один MCP: `1c-syntax-checker-mcp` на `http://localhost:8002/mcp`. Это удобно одному разработчику и непригодно команде. Код УХ живёт вне git (`C:\EDTProjects\uh_np`), планирование — в этом репозитории.

Оплата: **Cursor не оплачивается**; есть предоплаченные **Claude и GPT**. Конкретная EDT не выбрана. Контур строится вокруг HTTP MCP и этих двух моделей.

См. `proposal.md` (зачем) и specs `shared-mcp-gateway`, `mcp-work-profiles`, `prepaid-agent-workspace`.

## Goals / Non-Goals

**Goals:**

- Один LAN-хост Streamable HTTP, к которому подключаются Claude Desktop, ChatGPT и при необходимости Claude Code / Copilot
- Четыре профиля с разным allowlist инструментов
- Командные агенты — предоплаченные Claude и GPT, без счёта Cursor
- Контекст кода из файловой выгрузки `uhnp` / расширений, пока EDT нет
- Прод вне MCP; секреты вне git

**Non-Goals:**

- Командная подписка Cursor и обязательный `.cursor/mcp.json` как единственный конфиг
- Выбор, закупка и установка конкретной EDT
- Обязательный EDT-MCP / CodePilot1C в первой поставке
- Подключение продуктивной ИБ «хотя бы read-only»
- Замена OpenSpec-процесса MCP-инструментами
- Обязательный Docker-комбайн как единственная реализация шлюза

## Decisions

### 1. Клиенты — предоплаченные Claude и GPT, не Cursor

**Решение:** командный контур не зависит от Cursor.

| Оплачено | Клиент первой поставки | Как подключает MCP |
|---|---|---|
| Claude | Claude Desktop (основной UI) | remote URL в `claude_desktop_config.json` |
| Claude (если это API, не сайт) | Claude Code | проектный `.mcp.json` с теми же URL |
| GPT | ChatGPT (коннекторы / developer MCP) | тот же LAN URL как custom MCP connector |
| GPT (если это Copilot) | VS Code + Copilot Chat | MCP servers в user settings, те же URL |

**Почему:** шлюз HTTP один, клиенты разные. Cursor-правила и скиллы есть в репозитории исторически, но их не видит Claude Desktop/ChatGPT — канон политики: `AGENTS.md` + `openspec/` + короткий `CLAUDE.md`.

**Отклонено:** «команда сидит в Cursor на Claude» — Cursor не оплачен. **Отклонено ранее** «не делать Claude Desktop основным» — это как раз клиент предоплаченного Claude.

`.cursor/mcp.json` MAY остаться зеркалом каталога для тех, кто пользуется Cursor лично; MUST NOT быть источником истины.

### 2. Транспорт — Streamable HTTP на LAN, не stdio

**Решение:** шлюз слушает `http://<srv-mcp.lan>:<port>/mcp/...`. Reverse proxy с токеном. В git — URL профилей; токен — в конфиге клиента на рабочей станции (Claude Desktop / ChatGPT / env).

**Почему:** stdio в Claude Desktop не шарится между людьми и не подключается из ChatGPT. HTTP — общий знаменатель Claude Desktop, ChatGPT connectors, Claude Code, Copilot.

**Отклонено:** по копии MCP на каждом ПК.

### 3. Канон в репозитории — каталог URL, плюс сниппеты клиентов

**Решение:** файл вроде `mcp/catalog.json` (или эквивалент в `docs/mcp/`) со списком профилей и LAN URL-плейсхолдерами. Рядом сниппеты:

- Claude Desktop `mcpServers` с `"url"`
- ChatGPT: инструкция «добавить connector на URL профиля»
- опционально Claude Code `.mcp.json`
- опционально зеркало `.cursor/mcp.json`

**Почему:** четыре клиента не должны расходиться списком серверов вручную.

### 4. Сначала четыре URL профилей, не один «комбайн»

**Решение:** `1c-dev`, `1c-analytics`, `1c-test`, `1c-docs`. На рабочем месте подключают только нужные. Схлопывание в один gateway — фаза 2.

**Почему:** и Claude, и GPT хуже выбирают инструмент из списка на 40+ tools. Профили режут риск «провести документ» из ChatGPT аналитика.

**Отклонено:** один MCP со всеми tools.

### 5. EDT — опциональный адаптер после выбора продукта

**Решение:** канон кода — файловая выгрузка (EDT `src/` или `DumpConfigToFiles`). EDT-MCP — позже, отдельным change.

**Отклонено:** ждать EDT, чтобы подключить агента.

### 6. Живые данные — только копии, разные ИБ для analytics и test

| Профиль | Бэкенд |
|---|---|
| `dev` | выгрузка + BSL checker + справка платформы |
| `analytics` | HTTP-сервис на **аналитической копии** УХ, read-only |
| `test` | отдельная тестовая ИБ + runner |
| `docs` | метаданные выгрузки + `openspec/` + `AGENTS.md` + `Instructions` |

Прод не регистрируется. `execute_code` / проведение — не в `analytics` и `docs`.

### 7. Фазы внедрения

**Фаза A (без 1С-кластера):** вынести syntax-checker на `srv-mcp`; каталог URL + сниппеты Claude Desktop и ChatGPT; `AGENTS.md` / `CLAUDE.md`.

**Фаза B:** HTTP-сервис на копии УХ → `analytics`.

**Фаза C:** тестовая ИБ + runner.

**Фаза D (после выбора EDT):** опционально EDT-MCP.

Ориентиры: [Untru/1c-mcp](https://github.com/Untru/1c-mcp); [onec-mcp-universal](https://github.com/voregnev/onec-mcp-universal) — кандидат реализации, не контракт.

### 8. Слой политики в git, клиент-агностичный

**Решение:** MCP — факты. Как писать BSL, префиксы `нп_`/`тн_`, процесс OpenSpec — `AGENTS.md`, `openspec/`, `CLAUDE.md`. `.cursor/rules` не единственная копия правил.

**Почему:** Claude Desktop и ChatGPT не читают Cursor skills. Новый чат не помнит прошлую сессию.

## Risks / Trade-offs

- [Открытый MCP в LAN] → Mitigation: reverse proxy + токен, ACL по IP, не в интернет
- [Разные клиенты по-разному умеют remote MCP] → Mitigation: канон HTTP; в runbook — проверенные клиенты (Claude Desktop, ChatGPT); fallback Claude Code / Copilot
- [Слишком много tools] → Mitigation: профили
- [Выгрузка устарела] → Mitigation: расписание обновления дампа
- [Одна копия для аналитики и тестов] → Mitigation: разные ИБ с фазы C
- [ПДн в копии] → Mitigation: обезличивание / маскировка; `docs` не берёт живые документы
- [Токен в git] → Mitigation: только конфиг клиента на ПК
- [Кто-то всё равно сидит в неоплаченном Cursor] → Mitigation: зеркало каталога опционально; поддержка и runbook — про Claude/GPT
- [Предоплата Claude = сайт, а GPT = API, или наоборот] → Mitigation: оба пути описаны в таблице клиентов; шлюз не меняется

## Migration Plan

1. Зафиксировать hostname `srv-mcp` (runbook, не секреты)
2. Перенести syntax-checker на шлюз + auth
3. Опубликовать `mcp/catalog.json` и сниппеты Claude Desktop / ChatGPT
4. Обновить `AGENTS.md` / `CLAUDE.md`: агенты = предоплаченные Claude и GPT; Cursor не обязателен; EDT не обязателен; прод вне MCP
5. Фаза B/C — копия и тестовая ИБ
6. После выбора EDT — отдельный change на EDT-MCP
7. Откат: выключить шлюз; клиенты теряют общие tools, локальный localhost остаётся личным

## Open Questions

- Имя хоста и кто администрирует `srv-mcp` (Windows-служба vs Linux Docker) — не меняет spec
- Предоплата Claude: claude.ai / Desktop или API (Claude Code) — влияет на сниппет клиента, не на шлюз
- Предоплата GPT: ChatGPT, Copilot или API — то же
- Конкретный пакет HTTP-сервиса 1С на фазе B под УХ 3.2.8.25
