# Build DO posting-control CFE (ASCII-only script; Cyrillic via .NET / char codes)
$ErrorActionPreference = 'Stop'
$ibcmd = 'C:\Program Files\1cv8\8.3.27.2214\bin\ibcmd.exe'
if (-not (Test-Path $ibcmd)) { throw "ibcmd not found: $ibcmd" }

$utf8 = New-Object System.Text.UTF8Encoding $false
function U([int[]]$codes) { -join ($codes | ForEach-Object { [char]$_ }) }

$pkg = Get-ChildItem 'c:\Projects\ERPUH\Extensions' -Directory |
	Where-Object { Test-Path (Join-Path $_.FullName 'configurator\Configuration.xml') } |
	Select-Object -First 1
if ($null -eq $pkg) { throw 'Extension package not found under Extensions' }

$extSrc = Join-Path $pkg.FullName 'configurator'
[xml]$extCfg = Get-Content -LiteralPath (Join-Path $extSrc 'Configuration.xml') -Encoding UTF8
$extName = $extCfg.MetaDataObject.Configuration.Properties.Name
$cfe = Join-Path $pkg.FullName ($extName + '.cfe')

$build = Join-Path 'c:\Projects\ERPUH\.tmp' 'erpuh-np-do-cfe-build'
$stub = Join-Path $build 'stub'
$ib = Join-Path $build 'ib'
$log = Join-Path $build 'build.log'

if (Test-Path $build) { Remove-Item $build -Recurse -Force }
New-Item -ItemType Directory -Path $stub, (Join-Path $stub 'Languages'), (Join-Path $stub 'Catalogs'), (Join-Path $stub 'CommonModules'), (Join-Path $stub 'CommonPictures') | Out-Null

$langRu = U @(0x0420,0x0443,0x0441,0x0441,0x043A,0x0438,0x0439)
$orgName = U @(0x041E,0x0440,0x0433,0x0430,0x043D,0x0438,0x0437,0x0430,0x0446,0x0438,0x0438)
$modName = U @(0x041C,0x043E,0x0434,0x0438,0x0444,0x0438,0x043A,0x0430,0x0446,0x0438,0x044F,0x041A,0x043E,0x043D,0x0444,0x0438,0x0433,0x0443,0x0440,0x0430,0x0446,0x0438,0x0438,0x041F,0x0435,0x0440,0x0435,0x043E,0x043F,0x0440,0x0435,0x0434,0x0435,0x043B,0x044F,0x0435,0x043C,0x044B,0x0439)
$usersName = U @(0x041F,0x043E,0x043B,0x044C,0x0437,0x043E,0x0432,0x0430,0x0442,0x0435,0x043B,0x0438) # Пользователи
$groupsName = U @(0x0413,0x0440,0x0443,0x043F,0x043F,0x044B,0x041F,0x043E,0x043B,0x044C,0x0437,0x043E,0x0432,0x0430,0x0442,0x0435,0x043B,0x0435,0x0439) # ГруппыПользователей
# КартинкаКонтрольЗаголовок16
$picName = U @(0x041A,0x0430,0x0440,0x0442,0x0438,0x043A,0x0430,0x041A,0x043E,0x043D,0x0442,0x0440,0x043E,0x043B,0x044C,0x0417,0x0430,0x0433,0x043E,0x043B,0x043E,0x0432,0x043E,0x043A,0x0031,0x0036)
$picMainUuid = '9eb40799-52b8-4105-a7eb-b98fef344b74'
$prefix = U @(0x043D,0x043F,0x005F)

function Add-AdoptedCatalogToStub([string]$CatalogName) {
	$catSrc = Join-Path $extSrc ("Catalogs\$CatalogName.xml")
	if (-not (Test-Path -LiteralPath $catSrc)) { return }
	[xml]$catXml = Get-Content -LiteralPath $catSrc -Encoding UTF8
	$extUuid = $catXml.MetaDataObject.Catalog.Properties.ExtendedConfigurationObject
	if ([string]::IsNullOrWhiteSpace($extUuid)) {
		$extUuid = $catXml.MetaDataObject.Catalog.GetAttribute('uuid')
	}
	$body = @"
<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:app="http://v8.1c.ru/8.2/managed-application/core" xmlns:cfg="http://v8.1c.ru/8.1/data/enterprise/current-config" xmlns:cmi="http://v8.1c.ru/8.2/managed-application/cmi" xmlns:ent="http://v8.1c.ru/8.1/data/enterprise" xmlns:lf="http://v8.1c.ru/8.2/managed-application/logform" xmlns:style="http://v8.1c.ru/8.1/data/ui/style" xmlns:sys="http://v8.1c.ru/8.1/data/ui/fonts/system" xmlns:v8="http://v8.1c.ru/8.1/data/core" xmlns:v8ui="http://v8.1c.ru/8.1/data/ui" xmlns:web="http://v8.1c.ru/8.1/data/ui/colors/web" xmlns:win="http://v8.1c.ru/8.1/data/ui/colors/windows" xmlns:xen="http://v8.1c.ru/8.3/xcf/enums" xmlns:xpr="http://v8.1c.ru/8.3/xcf/predef" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.20">
	<Catalog uuid="$extUuid">
		<Properties>
			<Name>$CatalogName</Name>
			<Synonym><v8:item><v8:lang>ru</v8:lang><v8:content>$CatalogName</v8:content></v8:item></Synonym>
			<Comment/>
		</Properties>
		<ChildObjects/>
	</Catalog>
</MetaDataObject>
"@
	[System.IO.File]::WriteAllText((Join-Path $stub "Catalogs\$CatalogName.xml"), $body, $utf8)
}

# Catalog Организации — as before (full dump strip)
$orgSrc = Join-Path $extSrc ("Catalogs\$orgName.xml")
$orgText = [System.IO.File]::ReadAllText($orgSrc, $utf8)
$orgText = $orgText -replace '<ObjectBelonging>Adopted</ObjectBelonging>\s*', ''
$orgText = $orgText -replace '<ExtendedConfigurationObject>[^<]+</ExtendedConfigurationObject>\s*', ''
[System.IO.File]::WriteAllText((Join-Path $stub "Catalogs\$orgName.xml"), $orgText, $utf8)
Add-AdoptedCatalogToStub $usersName
Add-AdoptedCatalogToStub $groupsName

# Common picture for subsystem icon (main UUID = ExtendedConfigurationObject of adopted picture)
$picBody = @"
<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:app="http://v8.1c.ru/8.2/managed-application/core" xmlns:cfg="http://v8.1c.ru/8.1/data/enterprise/current-config" xmlns:cmi="http://v8.1c.ru/8.2/managed-application/cmi" xmlns:ent="http://v8.1c.ru/8.1/data/enterprise" xmlns:lf="http://v8.1c.ru/8.2/managed-application/logform" xmlns:style="http://v8.1c.ru/8.1/data/ui/style" xmlns:sys="http://v8.1c.ru/8.1/data/ui/fonts/system" xmlns:v8="http://v8.1c.ru/8.1/data/core" xmlns:v8ui="http://v8.1c.ru/8.1/data/ui" xmlns:web="http://v8.1c.ru/8.1/data/ui/colors/web" xmlns:win="http://v8.1c.ru/8.1/data/ui/colors/windows" xmlns:xen="http://v8.1c.ru/8.3/xcf/enums" xmlns:xpr="http://v8.1c.ru/8.3/xcf/predef" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.20">
	<CommonPicture uuid="$picMainUuid">
		<Properties>
			<Name>$picName</Name>
			<Synonym><v8:item><v8:lang>ru</v8:lang><v8:content>$picName</v8:content></v8:item></Synonym>
			<Comment/>
			<AvailabilityForChoice>true</AvailabilityForChoice>
			<AvailabilityForAppearance>true</AvailabilityForAppearance>
		</Properties>
	</CommonPicture>
</MetaDataObject>
"@
[System.IO.File]::WriteAllText((Join-Path $stub "CommonPictures\$picName.xml"), $picBody, $utf8)

# Language: use ExtendedConfigurationObject UUID from extension language as main UUID
$langSrc = Join-Path $extSrc ("Languages\$langRu.xml")
[xml]$langXml = Get-Content -LiteralPath $langSrc -Encoding UTF8
$langExtUuid = $langXml.MetaDataObject.Language.Properties.ExtendedConfigurationObject
$langBody = @"
<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:app="http://v8.1c.ru/8.2/managed-application/core" xmlns:cfg="http://v8.1c.ru/8.1/data/enterprise/current-config" xmlns:cmi="http://v8.1c.ru/8.2/managed-application/cmi" xmlns:ent="http://v8.1c.ru/8.1/data/enterprise" xmlns:lf="http://v8.1c.ru/8.2/managed-application/logform" xmlns:style="http://v8.1c.ru/8.1/data/ui/style" xmlns:sys="http://v8.1c.ru/8.1/data/ui/fonts/system" xmlns:v8="http://v8.1c.ru/8.1/data/core" xmlns:v8ui="http://v8.1c.ru/8.1/data/ui" xmlns:web="http://v8.1c.ru/8.1/data/ui/colors/web" xmlns:win="http://v8.1c.ru/8.1/data/ui/colors/windows" xmlns:xen="http://v8.1c.ru/8.3/xcf/enums" xmlns:xpr="http://v8.1c.ru/8.3/xcf/predef" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.20">
	<Language uuid="$langExtUuid">
		<Properties>
			<Name>$langRu</Name>
			<LanguageCode>ru</LanguageCode>
		</Properties>
	</Language>
</MetaDataObject>
"@
[System.IO.File]::WriteAllText((Join-Path $stub "Languages\$langRu.xml"), $langBody, $utf8)

# Common module: use ExtendedConfigurationObject UUID as main module UUID
$modSrc = Join-Path $extSrc ("CommonModules\$modName.xml")
[xml]$modXml = Get-Content -LiteralPath $modSrc -Encoding UTF8
$modExtUuid = $modXml.MetaDataObject.CommonModule.Properties.ExtendedConfigurationObject
$modBody = @"
<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:app="http://v8.1c.ru/8.2/managed-application/core" xmlns:cfg="http://v8.1c.ru/8.1/data/enterprise/current-config" xmlns:cmi="http://v8.1c.ru/8.2/managed-application/cmi" xmlns:ent="http://v8.1c.ru/8.1/data/enterprise" xmlns:lf="http://v8.1c.ru/8.2/managed-application/logform" xmlns:style="http://v8.1c.ru/8.1/data/ui/style" xmlns:sys="http://v8.1c.ru/8.1/data/ui/fonts/system" xmlns:v8="http://v8.1c.ru/8.1/data/core" xmlns:v8ui="http://v8.1c.ru/8.1/data/ui" xmlns:web="http://v8.1c.ru/8.1/data/ui/colors/web" xmlns:win="http://v8.1c.ru/8.1/data/ui/colors/windows" xmlns:xen="http://v8.1c.ru/8.3/xcf/enums" xmlns:xpr="http://v8.1c.ru/8.3/xcf/predef" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.20">
	<CommonModule uuid="$modExtUuid">
		<Properties>
			<Name>$modName</Name>
			<Synonym/>
			<Comment/>
			<Global>false</Global>
			<ClientManagedApplication>false</ClientManagedApplication>
			<Server>true</Server>
			<ExternalConnection>true</ExternalConnection>
			<ClientOrdinaryApplication>true</ClientOrdinaryApplication>
			<ServerCall>false</ServerCall>
			<Privileged>false</Privileged>
			<ReturnValuesReuse>DontUse</ReturnValuesReuse>
		</Properties>
	</CommonModule>
</MetaDataObject>
"@
[System.IO.File]::WriteAllText((Join-Path $stub "CommonModules\$modName.xml"), $modBody, $utf8)

$cfgMain = @"
<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:app="http://v8.1c.ru/8.2/managed-application/core" xmlns:cfg="http://v8.1c.ru/8.1/data/enterprise/current-config" xmlns:cmi="http://v8.1c.ru/8.2/managed-application/cmi" xmlns:ent="http://v8.1c.ru/8.1/data/enterprise" xmlns:lf="http://v8.1c.ru/8.2/managed-application/logform" xmlns:style="http://v8.1c.ru/8.1/data/ui/style" xmlns:sys="http://v8.1c.ru/8.1/data/ui/fonts/system" xmlns:v8="http://v8.1c.ru/8.1/data/core" xmlns:v8ui="http://v8.1c.ru/8.1/data/ui" xmlns:web="http://v8.1c.ru/8.1/data/ui/colors/web" xmlns:win="http://v8.1c.ru/8.1/data/ui/colors/windows" xmlns:xen="http://v8.1c.ru/8.3/xcf/enums" xmlns:xpr="http://v8.1c.ru/8.3/xcf/predef" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.20">
	<Configuration uuid="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee">
		<InternalInfo>
			<xr:ContainedObject><xr:ClassId>9cd510cd-abfc-11d4-9434-004095e12fc7</xr:ClassId><xr:ObjectId>11111111-1111-1111-1111-111111111111</xr:ObjectId></xr:ContainedObject>
			<xr:ContainedObject><xr:ClassId>9fcd25a0-4822-11d4-9414-008048da11f9</xr:ClassId><xr:ObjectId>22222222-2222-2222-2222-222222222222</xr:ObjectId></xr:ContainedObject>
			<xr:ContainedObject><xr:ClassId>e3687481-0a87-462c-a166-9f34594f9bba</xr:ClassId><xr:ObjectId>33333333-3333-3333-3333-333333333333</xr:ObjectId></xr:ContainedObject>
			<xr:ContainedObject><xr:ClassId>9de14907-ec23-4a07-96f0-85521cb6b53b</xr:ClassId><xr:ObjectId>44444444-4444-4444-4444-444444444444</xr:ObjectId></xr:ContainedObject>
			<xr:ContainedObject><xr:ClassId>51f2d5d8-ea4d-4064-8892-82951750031e</xr:ClassId><xr:ObjectId>55555555-5555-5555-5555-555555555555</xr:ObjectId></xr:ContainedObject>
			<xr:ContainedObject><xr:ClassId>e68182ea-4237-4383-967f-90c1e3370bc7</xr:ClassId><xr:ObjectId>66666666-6666-6666-6666-666666666666</xr:ObjectId></xr:ContainedObject>
			<xr:ContainedObject><xr:ClassId>fb282519-d103-4dd3-bc12-cb271d631dfc</xr:ClassId><xr:ObjectId>77777777-7777-7777-7777-777777777777</xr:ObjectId></xr:ContainedObject>
		</InternalInfo>
		<Properties>
			<Name>StubUH</Name>
			<Synonym><v8:item><v8:lang>ru</v8:lang><v8:content>Stub</v8:content></v8:item></Synonym>
			<Comment/>
			<NamePrefix/>
			<ConfigurationExtensionCompatibilityMode>Version8_3_21</ConfigurationExtensionCompatibilityMode>
			<DefaultRunMode>ManagedApplication</DefaultRunMode>
			<UsePurposes><v8:Value xsi:type="app:ApplicationUsePurpose">PersonalComputer</v8:Value></UsePurposes>
			<ScriptVariant>Russian</ScriptVariant>
			<DefaultLanguage>Language.$langRu</DefaultLanguage>
			<InterfaceCompatibilityMode>TaxiEnableVersion8_2</InterfaceCompatibilityMode>
		</Properties>
		<ChildObjects>
			<Language>$langRu</Language>
			<CommonPicture>$picName</CommonPicture>
			<CommonModule>$modName</CommonModule>
			<Catalog>$orgName</Catalog>
			<Catalog>$usersName</Catalog>
			<Catalog>$groupsName</Catalog>
		</ChildObjects>
	</Configuration>
</MetaDataObject>
"@
[System.IO.File]::WriteAllText((Join-Path $stub 'Configuration.xml'), $cfgMain, $utf8)

function Invoke-Ibcmd([string[]]$IbArgs) {
	$out = & $ibcmd @IbArgs 2>&1 | Out-String
	Add-Content -Path $log -Value ("`n=== " + ($IbArgs -join ' ') + " ===`n" + $out)
	if ($LASTEXITCODE -ne 0) { throw "ibcmd failed ($LASTEXITCODE): $($IbArgs -join ' ')`n$out" }
}

"Build start $(Get-Date); package=$($pkg.FullName); ext=$extName" | Set-Content -Path $log -Encoding UTF8

Invoke-Ibcmd @("infobase", "create", "--db-path=$ib", "--import=$stub", "--apply", "--force")
Invoke-Ibcmd @("config", "extension", "create", "--db-path=$ib", "--name=$extName", "--name-prefix=$prefix", "--purpose=customization")
Invoke-Ibcmd @("config", "import", "--db-path=$ib", "--extension=$extName", $extSrc)
if (Test-Path -LiteralPath $cfe) { Remove-Item -LiteralPath $cfe -Force }
Invoke-Ibcmd @("config", "save", "--db-path=$ib", "--extension=$extName", $cfe)

$size = (Get-Item -LiteralPath $cfe).Length
Write-Output "OK: $cfe ($size bytes)"
Add-Content -Path $log -Value "OK: $cfe ($size bytes)"
