## Purpose

Фиксирует командные рабочие места на уже предоплаченных Claude и GPT: общий HTTP MCP и правила репозитория, без обязательного Cursor и без выбранной EDT.

## ADDED Requirements

### Requirement: Prepaid Claude and GPT are the team agents
Командными агентами MUST быть предоплаченные модели Claude и GPT. Cursor MUST NOT быть обязательным клиентом контура. Подключение MCP SHALL идти по тем же Streamable HTTP URL профилей из любого поддержанного клиента.

#### Scenario: Claude Desktop calls shared MCP
- **WHEN** сотрудник настраивает Claude Desktop на LAN URL профиля и токен
- **THEN** Claude видит инструменты профиля и может их вызывать

#### Scenario: ChatGPT calls the same MCP
- **WHEN** сотрудник добавляет тот же LAN URL как MCP connector в предоплаченном ChatGPT (или Copilot, если это их GPT)
- **THEN** GPT видит те же инструменты профиля

#### Scenario: Cursor is not required
- **WHEN** новый сотрудник подключается к командному контуру
- **THEN** ему не нужна подписка Cursor: достаточно предоплаченного Claude или GPT и сниппета из репозитория

### Requirement: Canonical catalog is client-agnostic
Репозиторий SHALL хранить канонический список профилей и URL (без секретов). Сниппеты Claude Desktop, ChatGPT/Copilot и при необходимости Claude Code MUST ссылаться на этот список. Файлы `.cursor/` MUST NOT быть единственным источником списка серверов.

#### Scenario: Clone gives connection templates for paid clients
- **WHEN** сотрудник клонирует `ERPUH` и отдельно получает токен шлюза
- **THEN** он может собрать конфиг Claude Desktop или ChatGPT из каталога репозитория

#### Scenario: Cursor export is optional
- **WHEN** кто-то лично использует Cursor
- **THEN** зеркало каталога MAY существовать в `.cursor/mcp.json`, но команда не обязана его поддерживать как основной путь

### Requirement: Shared policy files work without Cursor
Агент MUST получать правила (префиксы `нп_`/`тн_`, OpenSpec, стандарты BSL) из клиент-агностичных файлов репозитория (`AGENTS.md`, OpenSpec, при необходимости `CLAUDE.md`). Правила MUST применяться и когда MCP недоступен.

#### Scenario: Rules apply even if MCP is down
- **WHEN** шлюз недоступен, а разработчик просит написать модуль расширения НП в Claude или GPT
- **THEN** агент всё равно соблюдает правила репозитория, если они поданы в проект/проектное знание клиента

#### Scenario: Claude Desktop does not depend on Cursor skills
- **WHEN** пользователь работает в Claude Desktop
- **THEN** контракт поведения доступен без `.cursor/skills` и `.cursor/commands`

### Requirement: EDT is an optional adapter
Рабочее место MUST NOT требовать конкретную поставку или версию 1C:EDT. Плагин EDT-MCP MAY быть добавлен позже, после выбора EDT, не ломая HTTP-профили.

#### Scenario: Work proceeds before EDT is chosen
- **WHEN** EDT ещё не выбран
- **THEN** агент на Claude или GPT выполняет задачи по выгрузке конфигурации, правилам репозитория и MCP-профилям

#### Scenario: Later EDT plugin is additive
- **WHEN** команда позже подключает EDT-MCP выбранной EDT
- **THEN** профили `dev` / `analytics` / `test` / `docs` продолжают работать

### Requirement: Personal credentials stay on the workstation
Ключи и сессии Claude/GPT и токены MCP MUST храниться в конфиге клиента на рабочей станции, не в git и не в каноническом каталоге URL.

#### Scenario: Catalog in git has no secrets
- **WHEN** проверяется канонический каталог MCP и сниппеты в git
- **THEN** в них нет ключей Claude/GPT, паролей ИБ, токенов шлюза и учётных данных Cursor
