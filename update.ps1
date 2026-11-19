# update-for-iobroker-latest.ps1
# Prepares ioBroker.winctrl for the ioBroker latest repository.
# PowerShell 5.1 compatible.

$ErrorActionPreference = 'Stop'

$Email = 'zockerfloh7@posteo.de'
$CompanionUrl = 'https://github.com/ZockerFloh7/winctrl-companion/releases/download/v0.0.3/WinCtrl-0.0.3-windows-x64.exe'
$CompanionReleaseUrl = 'https://github.com/ZockerFloh7/winctrl-companion/releases/tag/v0.0.3'

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    $Directory = Split-Path -Parent $Path
    if ($Directory -and -not (Test-Path $Directory)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path -Parent $Path) -ErrorAction SilentlyContinue).Path + '\' + (Split-Path -Leaf $Path), $Content, $Utf8NoBom)
}

# Create backups
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDirectory = ".\backup-before-iobroker-latest-$Timestamp"
New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null

$FilesToBackup = @(
    '.\package.json',
    '.\io-package.json',
    '.\tsconfig.json',
    '.\README.md',
    '.\LICENSE',
    '.\admin\jsonConfig.json',
    '.\.github\workflows\test-and-release.yml',
    '.\.github\dependabot.yml',
    '.\.github\workflows\dependabot-auto-merge.yml'
)

foreach ($File in $FilesToBackup) {
    if (Test-Path $File) {
        $Relative = $File.TrimStart('.\') -replace '\\', '__'
        Copy-Item -Path $File -Destination (Join-Path $BackupDirectory $Relative) -Force
    }
}

Write-Host "Backups saved to: $BackupDirectory" -ForegroundColor Green

# package.json
$PackageJson = @'
{
  "name": "iobroker.winctrl",
  "version": "0.0.3",
  "description": "Control Windows PCs through a local WinCtrl companion application",
  "author": {
    "name": "ZockerFloh7",
    "email": "zockerfloh7@posteo.de"
  },
  "license": "MIT",
  "main": "main.js",
  "files": [
    "admin/",
    "lib/",
    "main.js",
    "io-package.json",
    "README.md",
    "LICENSE"
  ],
  "dependencies": {
    "@iobroker/adapter-core": "^3.4.3"
  },
  "homepage": "https://github.com/ZockerFloh7/ioBroker.winctrl",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/ZockerFloh7/ioBroker.winctrl.git"
  },
  "bugs": {
    "url": "https://github.com/ZockerFloh7/ioBroker.winctrl/issues"
  },
  "keywords": [
    "ioBroker",
    "windows",
    "automation",
    "desktop",
    "remote-control"
  ],
  "engines": {
    "node": ">=22.19.0"
  },
  "devDependencies": {
    "@alcalzone/release-script": "^5.2.1",
    "@alcalzone/release-script-plugin-iobroker": "^5.2.0",
    "@alcalzone/release-script-plugin-license": "^5.2.2",
    "@alcalzone/release-script-plugin-manual-review": "^5.2.0",
    "@iobroker/adapter-dev": "^1.5.0",
    "@iobroker/eslint-config": "^2.2.0",
    "@iobroker/testing": "^6.3.2",
    "@tsconfig/node22": "^22.0.0",
    "@types/iobroker": "npm:@iobroker/types@^7.1.0",
    "@types/node": "^22.0.0",
    "typescript": "~5.9.3"
  },
  "scripts": {
    "lint": "eslint main.js",
    "check:syntax": "node --check main.js",
    "release": "release-script",
    "test:unit": "node --test main.test.js",
    "test": "npm run test:unit && npm run test:package",
    "test:package": "mocha test/package.js --exit",
    "test:integration": "mocha test/integration.js --exit",
    "test:all": "npm test && npm run test:integration"
  }
}
'@

Write-Utf8NoBom -Path '.\package.json' -Content $PackageJson

# io-package.json
$IOPackageJson = @'
{
  "common": {
    "name": "winctrl",
    "version": "0.0.3",
    "news": {
      "0.0.3": {
        "en": "Token, execution status, return values and connection monitoring",
        "de": "Token, Ausführungsstatus, Rückgabewerte und Verbindungsprüfung",
        "ru": "Токен, статус выполнения, возвращаемые значения и мониторинг подключения",
        "pt": "Token, estado de execução, valores de retorno e monitorização da ligação",
        "nl": "Token, uitvoeringsstatus, retourwaarden en verbindingsmonitoring",
        "fr": "Jeton, état d''exécution, valeurs de retour et surveillance de la connexion",
        "it": "Token, stato di esecuzione, valori restituiti e monitoraggio della connessione",
        "es": "Token, estado de ejecución, valores devueltos y supervisión de la conexión",
        "pl": "Token, status wykonywania, wartości zwracane i monitorowanie połączenia",
        "uk": "Токен, статус виконання, значення, що повертаються, та моніторинг з''єднання",
        "zh-cn": "令牌、执行状态、返回值和连接监控"
      }
    },
    "desc": {
      "en": "Controls Windows desktop functions through the WinCtrl HTTP companion application.",
      "de": "Steuert Windows-Desktop-Funktionen über die WinCtrl-HTTP-Companion-Anwendung.",
      "ru": "Управляет функциями рабочего стола Windows через HTTP-приложение WinCtrl.",
      "pt": "Controla funções do ambiente de trabalho Windows através da aplicação complementar HTTP WinCtrl.",
      "nl": "Bedient Windows-bureaubladfuncties via de WinCtrl HTTP-companiontoepassing.",
      "fr": "Contrôle les fonctions du bureau Windows via l''application compagnon HTTP WinCtrl.",
      "it": "Controlla le funzioni del desktop Windows tramite l''applicazione companion HTTP WinCtrl.",
      "es": "Controla funciones del escritorio de Windows mediante la aplicación complementaria HTTP WinCtrl.",
      "pl": "Steruje funkcjami pulpitu systemu Windows za pomocą aplikacji towarzyszącej WinCtrl HTTP.",
      "uk": "Керує функціями робочого столу Windows через HTTP-додаток WinCtrl.",
      "zh-cn": "通过 WinCtrl HTTP 配套应用控制 Windows 桌面功能。"
    },
    "platform": "Javascript/Node.js",
    "mode": "daemon",
    "icon": "winctrl.png",
    "enabled": true,
    "keywords": [
      "windows",
      "control",
      "automation"
    ],
    "readme": "https://github.com/ZockerFloh7/ioBroker.winctrl/blob/main/README.md",
    "loglevel": "info",
    "type": "utility",
    "adminUI": {
      "config": "json"
    },
    "titleLang": {
      "en": "Windows Control",
      "de": "Windows-Steuerung",
      "ru": "Управление Windows",
      "pt": "Controlo do Windows",
      "nl": "Windows-bediening",
      "fr": "Contrôle Windows",
      "it": "Controllo Windows",
      "es": "Control de Windows",
      "pl": "Sterowanie systemem Windows",
      "uk": "Керування Windows",
      "zh-cn": "Windows 控制"
    },
    "authors": [
      "ZockerFloh7 <zockerfloh7@posteo.de>"
    ],
    "extIcon": "https://raw.githubusercontent.com/ZockerFloh7/ioBroker.winctrl/main/admin/winctrl.png",
    "licenseInformation": {
      "type": "free",
      "license": "MIT"
    },
    "tier": 3,
    "connectionType": "local",
    "dataSource": "poll",
    "compact": false,
    "dependencies": [
      {
        "js-controller": ">=6.0.11"
      }
    ],
    "globalDependencies": [
      {
        "admin": ">=7.6.17"
      }
    ]
  },
  "native": {
    "clientIp": "",
    "port": 8085,
    "token": ""
  },
  "instanceObjects": [
    {
      "_id": "info",
      "type": "channel",
      "common": {
        "name": "Information"
      },
      "native": {}
    },
    {
      "_id": "info.connection",
      "type": "state",
      "common": {
        "role": "indicator.connected",
        "name": "Device connection to Windows PC",
        "type": "boolean",
        "read": true,
        "write": false,
        "def": false
      },
      "native": {}
    }
  ],
  "protectedNative": [
    "token"
  ],
  "encryptedNative": [
    "token"
  ]
}
'@

Write-Utf8NoBom -Path '.\io-package.json' -Content $IOPackageJson

# tsconfig.json
$TsConfig = @'
{
  "extends": "@tsconfig/node22/tsconfig.json",
  "compilerOptions": {
    "noEmit": true,
    "allowJs": true,
    "checkJs": true,
    "resolveJsonModule": true,
    "noImplicitAny": false,
    "useUnknownInCatchVariables": false
  },
  "include": [
    "**/*.js",
    "**/*.d.ts"
  ],
  "exclude": [
    "node_modules/**",
    "widgets/**"
  ]
}
'@

Write-Utf8NoBom -Path '.\tsconfig.json' -Content $TsConfig

# GitHub Actions workflow
$Workflow = @'
name: Test and Release

on:
  push:
    branches:
      - "main"
    tags:
      - "v[0-9]+.[0-9]+.[0-9]+"
      - "v[0-9]+.[0-9]+.[0-9]+-**"
  pull_request: {}

concurrency:
  group: ${{ github.ref }}
  cancel-in-progress: true

jobs:
  check-and-lint:
    if: contains(github.event.head_commit.message, '[skip ci]') == false
    runs-on: ubuntu-latest
    steps:
      - uses: ioBroker/testing-action-check@v2
        with:
          node-version: '22.x'
          lint: true

  adapter-tests:
    needs: check-and-lint
    if: contains(github.event.head_commit.message, '[skip ci]') == false
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        node-version: [22.x, 24.x, 26.x]
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - uses: ioBroker/testing-action-adapter@v1
        with:
          node-version: ${{ matrix.node-version }}
          os: ${{ matrix.os }}
          extra-tests: 'npm run test:unit'

  deploy:
    needs: [check-and-lint, adapter-tests]
    if: |
      contains(github.event.head_commit.message, '[skip ci]') == false &&
      github.event_name == 'push' &&
      startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: write
    steps:
      - uses: ioBroker/testing-action-deploy@v1
        with:
          node-version: '24'
          github-token: ${{ secrets.GITHUB_TOKEN }}
'@

Write-Utf8NoBom -Path '.\.github\workflows\test-and-release.yml' -Content $Workflow

# Dependabot configuration
$Dependabot = @'
version: 2
updates:
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: cron
      cron: "17 3 * * 1"
    open-pull-requests-limit: 15
    assignees:
      - ZockerFloh7
    versioning-strategy: increase
    cooldown:
      default-days: 7
    ignore:
      - dependency-name: "@types/node"
        update-types:
          - "version-update:semver-major"

  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: cron
      cron: "43 4 * * 1"
    open-pull-requests-limit: 15
    assignees:
      - ZockerFloh7
'@

Write-Utf8NoBom -Path '.\.github\dependabot.yml' -Content $Dependabot

# Replace deprecated auto-merge workflow
$AutoMergeWorkflow = @'
name: Automerge Dependabot PRs

on:
  pull_request_target:
    types:
      - opened
      - reopened
      - synchronize

jobs:
  automerge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: iobroker-bot-orga/action-automerge-dependabot@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
'@

Write-Utf8NoBom -Path '.\.github\workflows\automerge-dependabot.yml' -Content $AutoMergeWorkflow

if (Test-Path '.\.github\workflows\dependabot-auto-merge.yml') {
    Remove-Item -Path '.\.github\workflows\dependabot-auto-merge.yml' -Force
}

# Admin JSON configuration
$JsonConfig = @'
{
  "type": "panel",
  "i18n": true,
  "items": {
    "_heading": {
      "type": "header",
      "text": "winctrl_heading",
      "size": 2
    },
    "_intro": {
      "type": "staticText",
      "text": "winctrl_intro",
      "newLine": true,
      "sm": 12
    },
    "clientIp": {
      "type": "text",
      "label": "clientIp_label",
      "help": "clientIp_help",
      "sm": 12,
      "md": 8
    },
    "port": {
      "type": "number",
      "label": "port_label",
      "min": 1,
      "max": 65535,
      "sm": 12,
      "md": 4
    },
    "_divider": {
      "type": "divider",
      "newLine": true
    },
    "token": {
      "type": "password",
      "label": "token_label",
      "help": "token_help",
      "newLine": true,
      "sm": 12
    },
    "_note": {
      "type": "staticText",
      "text": "winctrl_note",
      "newLine": true,
      "sm": 12
    }
  }
}
'@

Write-Utf8NoBom -Path '.\admin\jsonConfig.json' -Content $JsonConfig

# i18n translations
$Languages = @{
    'de' = @{
        'winctrl_heading' = 'WinCtrl · Windows-Verbindung'
        'winctrl_intro' = 'Befehle ausführen und Blockly-Rückgabewerte empfangen. Netzwerk-Anfragezeitlimit: fest 10 Minuten.'
        'clientIp_label' = 'Windows-PC · IP-Adresse oder Hostname'
        'clientIp_help' = 'Zum Beispiel 192.168.1.50 — ohne http://'
        'port_label' = 'Port'
        'token_label' = 'WinCtrl-Token'
        'token_help' = 'Exakt das Token aus den Windows-Einstellungen, kein zusätzlich berechneter Hash.'
        'winctrl_note' = 'Verbindungsprüfung alle 30 Sekunden. Grün bei bestätigter Erreichbarkeit, sonst Gelb. HTTP nur im vertrauenswürdigen LAN/VPN verwenden.'
    }
    'en' = @{
        'winctrl_heading' = 'WinCtrl · Windows connection'
        'winctrl_intro' = 'Execute commands and receive Blockly return values. Network request timeout: fixed 10 minutes.'
        'clientIp_label' = 'Windows PC · IP address or hostname'
        'clientIp_help' = 'For example 192.168.1.50 — without http://'
        'port_label' = 'Port'
        'token_label' = 'WinCtrl token'
        'token_help' = 'Exactly the token configured in the Windows settings, not an additionally calculated hash.'
        'winctrl_note' = 'Connection check every 30 seconds. Green when reachability is confirmed, otherwise yellow. Use HTTP only in a trusted LAN/VPN.'
    }
    'ru' = @{
        'winctrl_heading' = 'WinCtrl · Подключение к Windows'
        'winctrl_intro' = 'Выполняйте команды и получайте возвращаемые значения Blockly. Таймаут сетевого запроса: фиксированно 10 минут.'
        'clientIp_label' = 'Компьютер Windows · IP-адрес или имя хоста'
        'clientIp_help' = 'Например, 192.168.1.50 — без http://'
        'port_label' = 'Порт'
        'token_label' = 'Токен WinCtrl'
        'token_help' = 'Точно токен, настроенный в параметрах Windows, без дополнительного вычисленного хеша.'
        'winctrl_note' = 'Проверка подключения каждые 30 секунд. Зелёный — доступность подтверждена, иначе жёлтый. Используйте HTTP только в доверенной LAN/VPN.'
    }
    'pt' = @{
        'winctrl_heading' = 'WinCtrl · Ligação ao Windows'
        'winctrl_intro' = 'Execute comandos e receba valores devolvidos pelo Blockly. Tempo limite do pedido de rede: 10 minutos fixos.'
        'clientIp_label' = 'PC Windows · Endereço IP ou nome de anfitrião'
        'clientIp_help' = 'Por exemplo, 192.168.1.50 — sem http://'
        'port_label' = 'Porta'
        'token_label' = 'Token WinCtrl'
        'token_help' = 'Exatamente o token configurado nas definições do Windows, sem um hash adicional calculado.'
        'winctrl_note' = 'Verificação da ligação a cada 30 segundos. Verde quando a acessibilidade é confirmada, caso contrário amarelo. Utilize HTTP apenas numa LAN/VPN fidedigna.'
    }
    'nl' = @{
        'winctrl_heading' = 'WinCtrl · Windows-verbinding'
        'winctrl_intro' = 'Voer opdrachten uit en ontvang Blockly-retourwaarden. Time-out voor netwerkverzoeken: vast 10 minuten.'
        'clientIp_label' = 'Windows-pc · IP-adres of hostnaam'
        'clientIp_help' = 'Bijvoorbeeld 192.168.1.50 — zonder http://'
        'port_label' = 'Poort'
        'token_label' = 'WinCtrl-token'
        'token_help' = 'Precies het token dat in de Windows-instellingen is geconfigureerd, zonder extra berekende hash.'
        'winctrl_note' = 'Verbindingscontrole elke 30 seconden. Groen wanneer bereikbaarheid is bevestigd, anders geel. Gebruik HTTP alleen in een vertrouwd LAN/VPN.'
    }
    'fr' = @{
        'winctrl_heading' = 'WinCtrl · Connexion Windows'
        'winctrl_intro' = 'Exécutez des commandes et recevez les valeurs retournées par Blockly. Délai d''attente des requêtes réseau : 10 minutes fixes.'
        'clientIp_label' = 'PC Windows · Adresse IP ou nom d''hôte'
        'clientIp_help' = 'Par exemple 192.168.1.50 — sans http://'
        'port_label' = 'Port'
        'token_label' = 'Jeton WinCtrl'
        'token_help' = 'Exactement le jeton configuré dans les paramètres Windows, sans hachage supplémentaire calculé.'
        'winctrl_note' = 'Vérification de connexion toutes les 30 secondes. Vert lorsque l''accessibilité est confirmée, sinon jaune. Utilisez HTTP uniquement dans un LAN/VPN de confiance.'
    }
    'it' = @{
        'winctrl_heading' = 'WinCtrl · Connessione Windows'
        'winctrl_intro' = 'Esegui comandi e ricevi i valori restituiti da Blockly. Timeout delle richieste di rete: 10 minuti fissi.'
        'clientIp_label' = 'PC Windows · Indirizzo IP o nome host'
        'clientIp_help' = 'Ad esempio 192.168.1.50 — senza http://'
        'port_label' = 'Porta'
        'token_label' = 'Token WinCtrl'
        'token_help' = 'Esattamente il token configurato nelle impostazioni di Windows, senza un hash aggiuntivo calcolato.'
        'winctrl_note' = 'Controllo della connessione ogni 30 secondi. Verde quando la raggiungibilità è confermata, altrimenti giallo. Usa HTTP solo in una LAN/VPN affidabile.'
    }
    'es' = @{
        'winctrl_heading' = 'WinCtrl · Conexión con Windows'
        'winctrl_intro' = 'Ejecuta comandos y recibe valores devueltos por Blockly. Tiempo de espera de solicitudes de red: 10 minutos fijos.'
        'clientIp_label' = 'PC con Windows · Dirección IP o nombre de host'
        'clientIp_help' = 'Por ejemplo, 192.168.1.50 — sin http://'
        'port_label' = 'Puerto'
        'token_label' = 'Token de WinCtrl'
        'token_help' = 'Exactamente el token configurado en la configuración de Windows, sin un hash adicional calculado.'
        'winctrl_note' = 'Comprobación de conexión cada 30 segundos. Verde cuando se confirma la accesibilidad; de lo contrario, amarillo. Usa HTTP solo en una LAN/VPN de confianza.'
    }
    'pl' = @{
        'winctrl_heading' = 'WinCtrl · Połączenie z systemem Windows'
        'winctrl_intro' = 'Wykonuj polecenia i otrzymuj wartości zwracane przez Blockly. Limit czasu żądania sieciowego: stałe 10 minut.'
        'clientIp_label' = 'Komputer z systemem Windows · Adres IP lub nazwa hosta'
        'clientIp_help' = 'Na przykład 192.168.1.50 — bez http://'
        'port_label' = 'Port'
        'token_label' = 'Token WinCtrl'
        'token_help' = 'Dokładnie token skonfigurowany w ustawieniach systemu Windows, bez dodatkowo obliczonego skrótu.'
        'winctrl_note' = 'Sprawdzanie połączenia co 30 sekund. Zielony, gdy dostępność została potwierdzona, w przeciwnym razie żółty. Używaj HTTP tylko w zaufanej sieci LAN/VPN.'
    }
    'uk' = @{
        'winctrl_heading' = 'WinCtrl · З''єднання з Windows'
        'winctrl_intro' = 'Виконуйте команди та отримуйте значення, що повертає Blockly. Тайм-аут мережевого запиту: фіксовано 10 хвилин.'
        'clientIp_label' = 'Комп''ютер Windows · IP-адреса або ім''я хоста'
        'clientIp_help' = 'Наприклад, 192.168.1.50 — без http://'
        'port_label' = 'Порт'
        'token_label' = 'Токен WinCtrl'
        'token_help' = 'Саме токен, налаштований у параметрах Windows, без додатково обчисленого хешу.'
        'winctrl_note' = 'Перевірка з''єднання кожні 30 секунд. Зелений, якщо доступність підтверджено, інакше жовтий. Використовуйте HTTP лише в надійній LAN/VPN.'
    }
    'zh-cn' = @{
        'winctrl_heading' = 'WinCtrl · Windows 连接'
        'winctrl_intro' = '执行命令并接收 Blockly 返回值。网络请求超时：固定 10 分钟。'
        'clientIp_label' = 'Windows 电脑 · IP 地址或主机名'
        'clientIp_help' = '例如 192.168.1.50 — 不含 http://'
        'port_label' = '端口'
        'token_label' = 'WinCtrl 令牌'
        'token_help' = '与 Windows 设置中配置的令牌完全一致，而非额外计算的哈希值。'
        'winctrl_note' = '每 30 秒进行一次连接检查。确认可访问时为绿色，否则为黄色。请仅在可信的局域网/VPN 中使用 HTTP。'
    }
}

foreach ($Language in $Languages.Keys) {
    $Translations = $Languages[$Language]
    $Json = @{}
    foreach ($Key in $Translations.Keys) {
        $Json[$Key] = $Translations[$Key]
    }

    $JsonContent = $Json | ConvertTo-Json -Depth 5
    Write-Utf8NoBom -Path ".\admin\i18n\$Language.json" -Content $JsonContent
}

# Remove obsolete words.js
if (Test-Path '.\admin\words.js') {
    Remove-Item -Path '.\admin\words.js' -Force
}

# README.md
$Readme = @'
# ioBroker.winctrl

Control a Windows PC from ioBroker through the separate WinCtrl Windows companion application.

This adapter sends configured action triggers to the companion's HTTP command server.
The Windows companion executes the action and returns its result to ioBroker.
Actions may contain Windows-side Blockly plans, for example to start an application,
control a window, send keyboard input or operate a media player.

## Project status

Version 0.0.3 is a public test release.

## Requirements

- Node.js 22.19.0 or newer, as declared by this adapter's package.json.
- An ioBroker installation compatible with the adapter's dependencies.
- Download the Windows companion application: [WinCtrl Companion v0.0.3]($CompanionUrl).
- Network access from the ioBroker host to the Windows command-server port.
- A configured command-server token.

The adapter may run on a different machine from the Windows PC, including an ioBroker
container. Configure the Windows PC's reachable IP address or hostname; do not use
127.0.0.1 unless the command server is actually reachable through the adapter host's
loopback interface.

## Prepare the Windows companion

1. Install and start the compatible WinCtrl Windows application.
2. Configure its command-server address, port and a new authentication token.
3. Create an action and assign a trigger such as /netflix.
4. Enable the action. Disabled actions cannot be invoked by their HTTP trigger.
5. If the companion's IP whitelist is enabled, allow the source IP seen for your
   ioBroker host. Token authentication remains necessary.
6. Test the Windows action locally before triggering it from ioBroker.

Desktop automation requires the appropriate interactive Windows session. Actions may
not work as expected on a locked desktop, secure prompts or applications with different
privilege levels. Validate each action on the intended Windows PC.

## Install the adapter

For a locally built development package:

1. Run npm pack in the adapter source directory.
2. Install the resulting .tgz file through the ioBroker Admin custom-source file installer.
3. Open the adapter instance settings and configure the connection.

Do not install the Windows application's update ZIP as an ioBroker adapter package.

## Instance settings

| Setting | Meaning |
| --- | --- |
| clientIp | Windows IP address or hostname, without http://, port or path |
| port | Command-server TCP port; default 8085 |
| token | The exact token configured in the Windows companion |

The adapter uses HTTP GET and sends the token as an Authorization: Bearer header.
Do not put the token into command values or trigger names.

## Data points

Replace winctrl.0 with your actual instance ID if necessary.

| Data point | Type | Writable | Meaning |
| --- | --- | --- | --- |
| command | string | yes | Action trigger to execute, e.g. netflix or /media/pause |
| status | number | no | 0 = failed, 1 = request running, 2 = success |
| response | string | no | Action return value on success, otherwise a diagnostic message |
| httpStatus | number | no | HTTP response code; 0 if no response code was recorded |
| lastError | string | no | Last execution error; cleared when a new execution starts |
| lastCommand | string | no | Last normalized trigger prepared for sending |
| info.connection | boolean | no | Last observed reachability/authentication result |

httpStatus = 0 can also occur before a request is sent, for example when trigger validation
fails. It is not exclusively a network-timeout indicator.

## Execute an action

Write a trigger to winctrl.0.command with ack=false.

Example using the ioBroker JavaScript adapter:

```javascript
setState('winctrl.0.command', 'netflix', false);
```

The adapter normalizes the trigger to /netflix. It sets status to 1 while waiting
for the HTTP response, then sets status to 2 on success or 0 on failure.
Read response for the action's returned string. An explicitly returned empty string
remains empty and is not replaced with OK.

Use the Windows companion's return-value block to provide a result from its Blockly plan.
Writing a command is an execution request; the acknowledged command value is not proof
that the action succeeded. Inspect status, response and lastError.

## Execution behavior and limits

- Execution requests have a fixed 600-second timeout, including reading the response body.
- This limit also applies to otherwise healthy long-running Windows actions.
- A timeout or adapter shutdown does not guarantee that a Windows action has stopped.
- Failed requests are not retried automatically, to avoid duplicate execution.
- Only one execution request is handled at a time per adapter instance. Additional
  commands received while busy are rejected with a log warning, not queued.
- Do not use a rejected additional command to infer a result from the active request's
  data points: those data points still describe the active request.
- A Windows busy response (HTTP 409) fails the new request because it was not started.
- status = 1 means that this adapter is waiting for a response. It is not independent
  confirmation of the Windows worker's current state.
- After restarting during an observed running request, the adapter reports that the
  previous result is unknown. It does not resume observing that Windows job.
- /ping is reserved for connection checks and cannot be submitted as a command.

## Connection monitoring

A connection check runs during startup and is scheduled every 30 seconds. Its own timeout
is 4 seconds. New checks are skipped while an execution request or another ping is active.

The companion should provide an authenticated /ping endpoint. The adapter recognizes its
Pong response. It also supports one specific legacy WinCtrl JSON 404 response for older
companions without a native ping endpoint; arbitrary HTTP 404 responses are not accepted.

info.connection is the latest observation, not a persistent connection or a guarantee
that the next action will succeed. An execution failure can still leave it true when
an authenticated WinCtrl response was received.

## Security

- HTTP is unencrypted: the token and command traffic are not protected in transit.
- Use a trusted LAN or VPN; do not expose the command server through an Internet port forward.
- Use the companion's IP whitelist and appropriate Windows firewall rules.
- The token field is masked and listed in protectedNative. This does not mean that
  the stored token has been encrypted by this adapter.
- Protect ioBroker backups and configuration files containing credentials.
- Rotate any token accidentally shared in a log, screenshot, repository or support request.
- Actions can start applications, send input and close windows. Review plans before enabling
  them. Closing windows may affect unsaved work.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Token missing in instance settings | Enter and save the companion token in the adapter settings. |
| HTTP 401 or 403 | Check both the token and the Windows companion's IP whitelist. The current adapter uses a generic authentication message for these response codes. |
| Unknown or disabled action | Check the trigger spelling and whether the Windows action is enabled. |
| HTTP 409 | Another Windows action is running; the new action was not started. |
| Request timeout | Check connectivity and action duration. The Windows action may still be running; do not blindly retry. |
| Invalid JSON response | Check the host, port and compatible companion protocol; ensure the request is reaching WinCtrl. |
| Window not found | Check the title and Windows session, or wait for the window before operating on it. |

## Development and checks

```text
npm ci
npm run check:syntax
npm run lint
npm test
npm run test:integration
```

npm test runs helper unit tests and package-file validation. The integration test currently
uses JS-Controller 7.2.5 and checks basic adapter startup. With an empty default token,
startup logs a configuration error and skips HTTP initialization; this smoke test does
not validate successful command execution.

See the repository's issue tracker for bug reports. Never include tokens in reports.

## Changelog

### 0.0.3 — public test release

- Token-authenticated HTTP action requests.
- Execution status and returned values.
- Connection monitoring and separate HTTP/error diagnostic data points.
- Fixed execution-request timeout and basic automated checks.

## License

MIT License

Copyright (c) 2026 ZockerFloh7 <zockerfloh7@posteo.de>

See [LICENSE](LICENSE) for the full license text.
'@

$Readme = $Readme.Replace('$CompanionUrl', $CompanionUrl)
Write-Utf8NoBom -Path '.\README.md' -Content $Readme

# LICENSE
$License = @'
MIT License

Copyright (c) 2026 ZockerFloh7 <zockerfloh7@posteo.de>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'@

Write-Utf8NoBom -Path '.\LICENSE' -Content $License

# CHANGELOG.md
$Changelog = @'
# Changelog

## 0.0.3

- Token-authenticated HTTP action requests.
- Execution status and returned values.
- Connection monitoring and separate HTTP/error diagnostic data points.
- Fixed execution-request timeout and basic automated checks.
'@

Write-Utf8NoBom -Path '.\CHANGELOG.md' -Content $Changelog

# CHANGELOG_OLD.md
$ChangelogOld = @'
# Older changelog entries

No older changelog entries are currently available.
'@

Write-Utf8NoBom -Path '.\CHANGELOG_OLD.md' -Content $ChangelogOld

Write-Host 'All configuration files have been updated.' -ForegroundColor Green

# Install dependencies and run checks
Write-Host 'Installing dependencies...' -ForegroundColor Cyan
npm install
if ($LASTEXITCODE -ne 0) {
    throw 'npm install failed. Tests were not executed.'
}

Write-Host 'Running syntax check...' -ForegroundColor Cyan
npm run check:syntax
if ($LASTEXITCODE -ne 0) {
    throw 'Syntax check failed.'
}

Write-Host 'Running lint...' -ForegroundColor Cyan
npm run lint
if ($LASTEXITCODE -ne 0) {
    throw 'Lint failed.'
}

Write-Host 'Running unit tests...' -ForegroundColor Cyan
npm run test:unit
if ($LASTEXITCODE -ne 0) {
    throw 'Unit tests failed.'
}

Write-Host 'Running package tests...' -ForegroundColor Cyan
npm run test:package
if ($LASTEXITCODE -ne 0) {
    throw 'Package tests failed.'
}

Write-Host 'Running npm pack dry run...' -ForegroundColor Cyan
npm pack --dry-run
if ($LASTEXITCODE -ne 0) {
    throw 'npm pack dry run failed.'
}

Write-Host 'All checks passed.' -ForegroundColor Green

# Git commit
Write-Host 'Creating Git commit...' -ForegroundColor Cyan
git add .
git commit -m "Prepare adapter for ioBroker latest repository"

if ($LASTEXITCODE -ne 0) {
    throw 'Git commit failed.'
}

Write-Host 'Commit created. Push was intentionally not executed.' -ForegroundColor Green

Write-Host ''
Write-Host 'Manual steps still required:' -ForegroundColor Yellow
Write-Host '1. Run: npm owner add bluefox iobroker.winctrl'
Write-Host '2. Set GitHub repository topics:'
Write-Host '   iobroker, iobroker-adapter, windows, remote-control, desktop-automation, smarthome, http'
Write-Host '3. Update the adapter release notes to link to:'
Write-Host "   $CompanionReleaseUrl"
Write-Host '4. Push with: git push origin main'
Write-Host '5. Run the ioBroker Adapter Check again.'