#Requires -Version 5.1
<#
.SYNOPSIS
    Сборка .erf из XML-выгрузки внешнего отчёта через платформу 1С.

.DESCRIPTION
    Вызывает конфигуратор в пакетном режиме:
    /LoadExternalDataProcessorOrReportFromFiles

    Нужна файловая или серверная база ERP УХ (в пустой базе сборка, как правило, падает
    из‑за ссылок на объекты конфигурации и БСП).

.PARAMETER V8Path
    Каталог bin платформы 1С (где лежит 1cv8.exe) или полный путь к 1cv8.exe.

.PARAMETER InfoBasePath
    Путь к файловой информационной базе ERP.

.PARAMETER InfoBaseServer
    Сервер 1С (для серверной базы).

.PARAMETER InfoBaseRef
    Имя базы на сервере.

.PARAMETER UserName
    Имя пользователя ИБ.

.PARAMETER Password
    Пароль пользователя ИБ.

.PARAMETER ReportName
    Имя внешнего отчёта (каталог и файл без расширения), например
    `нп_МестаИспользованияНоменклатуры` или `нп_МестаИспользованияКонтрагентов`.

.EXAMPLE
    .\build-external-report-erf.ps1 -V8Path "C:\Program Files\1cv8\8.3.24.1691\bin" -InfoBasePath "C:\Bases\ERP_UH" -ReportName "нп_МестаИспользованияНоменклатуры"
#>
[CmdletBinding(DefaultParameterSetName = 'FileIB')]
param(
    [Parameter(Mandatory = $true)]
    [string]$V8Path,

    [Parameter(Mandatory = $true, ParameterSetName = 'FileIB')]
    [string]$InfoBasePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'ServerIB')]
    [string]$InfoBaseServer,

    [Parameter(Mandatory = $true, ParameterSetName = 'ServerIB')]
    [string]$InfoBaseRef,

    [string]$UserName,
    [string]$Password,

    [string]$ReportName = 'нп_МестаИспользованияНоменклатуры'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ReportDir = Join-Path $RepoRoot "ExternalReports\$ReportName"
$SourceFile = Join-Path $ReportDir "$ReportName.xml"
$OutputFile = Join-Path $ReportDir "$ReportName.erf"
$LogFile = Join-Path $env:TEMP 'build-external-report-erf.log'

if (-not (Test-Path -LiteralPath $SourceFile)) {
    throw "Не найден корневой XML: $SourceFile"
}

$V8Exe = if ([System.IO.Path]::GetFileName($V8Path) -ieq '1cv8.exe') {
    $V8Path
} else {
    Join-Path $V8Path '1cv8.exe'
}

if (-not (Test-Path -LiteralPath $V8Exe)) {
    throw "Не найден 1cv8.exe: $V8Exe"
}

if ($PSCmdlet.ParameterSetName -eq 'FileIB') {
    $IbConnection = "File=""$InfoBasePath"""
} else {
    $IbConnection = "Srvr=""$InfoBaseServer"";Ref=""$InfoBaseRef"""
}

$Arguments = @(
    'DESIGNER',
    "/IBConnectionString $IbConnection",
    '/DisableStartupDialogs',
    "/Out ""$LogFile"""
)

if ($UserName) {
    $Arguments += "/N""$UserName"""
}
if ($Password) {
    $Arguments += "/P""$Password"""
}

$Arguments += @(
    '/LoadExternalDataProcessorOrReportFromFiles',
    """$SourceFile""",
    """$OutputFile"""
)

Write-Host "Сборка: $OutputFile"
Write-Host "Источник: $SourceFile"
Write-Host "База: $IbConnection"

& $V8Exe @Arguments
$ExitCode = $LASTEXITCODE

if (Test-Path -LiteralPath $LogFile) {
    Get-Content -LiteralPath $LogFile -Encoding UTF8 | ForEach-Object { Write-Host $_ }
}

if ($ExitCode -ne 0) {
    throw "1cv8 завершился с кодом $ExitCode. См. $LogFile"
}

if (-not (Test-Path -LiteralPath $OutputFile)) {
    throw "Файл не создан: $OutputFile"
}

$Size = (Get-Item -LiteralPath $OutputFile).Length
if ($Size -lt 32 * 1024) {
    Write-Warning "Размер .erf подозрительно мал ($Size байт). Проверьте открытие в конфигураторе."
}

Write-Host "Готово: $OutputFile ($Size байт)"
