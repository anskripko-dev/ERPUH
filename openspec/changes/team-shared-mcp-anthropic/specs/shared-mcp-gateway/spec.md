## Purpose

Даёт команде один сетевой MCP-вход в LAN: Streamable HTTP, авторизация и изоляция сессий без доступа к продуктивной базе 1С.

## ADDED Requirements

### Requirement: Shared Streamable HTTP endpoint
Система SHALL предоставлять MCP по Streamable HTTP в локальной сети, чтобы несколько клиентов Cursor подключались к одному хосту. Транспорт stdio MUST NOT быть единственным способом командного доступа.

#### Scenario: Second workstation uses the same host
- **WHEN** два пользователя в LAN открывают проект `ERPUH` в Cursor и MCP указывает на сетевой URL шлюза
- **THEN** оба получают рабочее MCP-подключение без запуска персональных серверов на `localhost`

#### Scenario: Localhost-only config is not the team contract
- **WHEN** в репозитории описан командный MCP
- **THEN** URL MUST быть адресом LAN-хоста (или плейсхолдером такого адреса), а не обязательным `http://localhost:...` как единственной схемой

### Requirement: Authentication on the LAN endpoint
Доступ к шлюзу MUST требовать секрет (токен, Basic или эквивалент на reverse proxy). Неаутентифицированный запрос MUST быть отклонён. Секреты MUST NOT храниться в git.

#### Scenario: Request without secret is rejected
- **WHEN** клиент вызывает MCP URL без действительного секрета
- **THEN** шлюз не выполняет инструменты и возвращает отказ в доступе

#### Scenario: Secrets stay out of the repository
- **WHEN** сотрудник клонирует `ERPUH`
- **THEN** в git нет паролей, токенов и строк подключения к ИБ

### Requirement: Session isolation
Разные клиентские сессии MUST не разделять активную информационную базу и состояние инструментов друг друга.

#### Scenario: Concurrent sessions stay independent
- **WHEN** аналитик работает с копией УХ, а тестировщик — с тестовой ИБ через тот же хост
- **THEN** запросы одного не переключают активную базу и не видят состояние сессии другого

### Requirement: Production information base is out of reach
Шлюз MUST NOT подключать продуктивную ИБ УХ. Инструменты чтения и изменения данных MUST работать только с явно разрешёнными копиями (тест / аналитическая копия).

#### Scenario: Production is not a selectable backend
- **WHEN** клиент запрашивает подключение или запрос к продуктивной ИБ
- **THEN** шлюз отказывает и не выполняет запрос к проду

#### Scenario: Copy databases are allowed
- **WHEN** администратор зарегистрировал тестовую или аналитическую копию как разрешённый бэкенд
- **THEN** профили, которым это разрешено, могут вызывать инструменты этой копии
