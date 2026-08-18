## Purpose

Фиксирует командное рабочее место: Cursor с моделью Anthropic (Claude), общие правила репозитория и MCP, независимое от ещё не выбранной EDT.

## ADDED Requirements

### Requirement: Anthropic model is the team agent
Командным агентом MUST быть модель Anthropic (Claude) в Cursor. Конфигурация рабочего места SHALL быть совместима с Streamable HTTP MCP, который использует Cursor для удалённых серверов.

#### Scenario: Cursor with Claude can call shared MCP
- **WHEN** сотрудник открывает `ERPUH` в Cursor на Claude и MCP-профили настроены на LAN URL
- **THEN** агент видит инструменты профилей и может их вызывать

#### Scenario: Stdio-only desktop setup is not required
- **WHEN** новый сотрудник подключается к командному контуру
- **THEN** ему не нужно поднимать Claude Desktop и локальный stdio MCP как обязательный путь

### Requirement: Project files define shared agent context
Репозиторий SHALL содержать проектный `.cursor/mcp.json` (URL профилей без секретов), правила `.cursor/rules/` и `AGENTS.md`. Агент MUST следовать этим правилам (префиксы `нп_`/`тн_`, OpenSpec, стандарты BSL) независимо от MCP.

#### Scenario: Clone gives the connection template
- **WHEN** сотрудник клонирует `ERPUH` и получает LAN-секреты отдельно
- **THEN** Cursor подхватывает список MCP из проектного `mcp.json`

#### Scenario: Rules apply even if MCP is down
- **WHEN** шлюз недоступен, а разработчик просит написать модуль расширения НП
- **THEN** агент всё равно соблюдает правила репозитория (префиксы, области модулей, процесс OpenSpec)

### Requirement: EDT is an optional adapter
Рабочее место MUST NOT требовать конкретную поставку или версию 1C:EDT для разработки, аналитики, тестов и инструкций через агента. Плагин EDT-MCP MAY быть добавлен позже, после выбора EDT, как дополнительный адаптер, не ломая файловый контур.

#### Scenario: Work proceeds before EDT is chosen
- **WHEN** EDT ещё не выбран
- **THEN** агент выполняет задачи по выгрузке конфигурации, правилам репозитория и MCP-профилям, не блокируясь на отсутствии EDT

#### Scenario: Later EDT plugin is additive
- **WHEN** команда позже подключает EDT-MCP выбранной EDT
- **THEN** существующие HTTP-профили `dev` / `analytics` / `test` / `docs` продолжают работать

### Requirement: Personal credentials stay on the workstation
Ключи Anthropic/Cursor и токены MCP MUST храниться в пользовательской конфигурации Cursor или переменных окружения рабочей станции, не в git и не в общем `mcp.json` репозитория.

#### Scenario: Project mcp.json has no API keys
- **WHEN** проверяется `.cursor/mcp.json` в git
- **THEN** в нём нет ключей Anthropic, паролей ИБ и токенов шлюза
