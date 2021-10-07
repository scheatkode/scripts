$NetNat = ''
$InternalAddress = ''
$ExternalAddress = ''
$PrefixLength = ''
$InternalPort = ''
$ExternalPort = ''
$Protocol

function ValidatePort
{
    param([Parameter(Mandatory)]$Port)

    try { $Port = [int]$Port } catch { return $False }
    if ($Port -gt 65535 -or $Port -lt 1) { return $False }

    return $True
}

# -- USER INPUT -----------------------------------------------------------------------------------

$NetNat = Read-Host -Prompt 'Net Nat name'

do {
    $ExternalAddress = Read-Host -Prompt 'External address [0.0.0.0]'
} while (
    $ExternalAddress -notmatch "{0}{1}" -f
        '^(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}',
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))?$'
)

if ($ExternalAddress -eq '') {
    $ExternalAddress = '0.0.0.0'
}

do {
    $InternalAddress = Read-Host -Prompt 'Internal address'
} while (
    $InternalAddress -notmatch "{0}{1}" -f
        '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}',
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
)

do {
    $PrefixLength = Read-Host -Prompt 'Prefix Length'
} while (
    $PrefixLength -notmatch '^(3[0-2]|[12][0-9]|[0-9])$'
)

Write-Host '[1] TCP'
Write-Host '[2] UDP'

do {
    $Protocol = Read-Host -Prompt 'Protocol (1,2)'
} while (
    $Protocol -notmatch '^[12]$'
)

do {
    $ExternalPort = Read-Host -Prompt 'External port'
} while (
    -not (ValidatePort($ExternalPort))
)

do {
    $InternalPort = Read-Host -Prompt 'Internal port'
} while (
    -not (ValidatePort($InternalPort))
)

# -- NAT CREATION ---------------------------------------------------------------------------------

switch ($Protocol) {
    1 { $Protocol = 'TCP' }
    2 { $Protocol = 'UDP' }
}

New-NetNat -Name "$NetNat" -InternalIPInterfaceAddressPrefix "$InternalAddress/$PrefixLength"

# Check success

try {
    Get-NetNat -Name "$NetNat" | Out-Null
} catch {
    Write-Host -ForegroundColor Red 'Something went wrong during NAT creation'
    exit 1
}

# Bind port

Add-NetNatStaticMapping                   `
    -NatName           "$NetNat"          `
    -Protocol          "$Protocol"        `
    -ExternalIPAddress "$ExternalAddress" `
    -ExternalPort      "$ExternalPort"    `
    -InternalIPAddress "$InternalAddress" `
    -InternalPort      "$InternalPort"

# Check success

try {
    Get-NetNatStaticMapping -NatName "$NetNat" | Out-Null
} catch {
    Write-Host -ForegroundColor Red 'Something went wrong during port binding'
    exit 1
}

