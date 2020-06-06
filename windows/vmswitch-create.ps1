$SwitchType   = ''
$NetVMSwitch  = ''
$NetIPAddress = ''
$PrefixLength = ''

# -- USER INPUT -----------------------------------------------------------------------------------

Write-Output "[1] Private"
Write-Output "[2] Internal"
Write-Output "[3] External"

do {
    $SwitchType = Read-Host -Prompt 'Switch Type (1,2,3)'
} while (
    $SwitchType -notmatch '^[1-3]$'
)

$NetVMSwitch = Read-Host -Prompt 'Virtual Switch name'

do {
    $NetIPAddress = Read-Host -Prompt 'IP Address'
} while (
    $NetIPAddress -notmatch "{0}{1}" -f
        '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}',
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
)

do {
    $PrefixLength = Read-Host -Prompt 'Prefix Length'
} while (
    $PrefixLength -notmatch '^(3[0-2]|[12][0-9]|[0-9])$'
)

switch ($SwitchType) {
    1 { $SwitchType = 'Private'  }
    2 { $SwitchType = 'Internal' }
    3 { $SwitchType = 'External' }
}

# -- SWITCH CREATION ------------------------------------------------------------------------------

New-VMSwitch -Name "$NetVMSwitch" -SwitchType "$SwitchType"

if ((Get-VMSwitch | Where-Object { $_.Name -eq "$NetVMSwitch" }).Count -notmatch 1) {
    Write-Host -ForegroundColor Red  "Something went wrong while creating the VM Switch."
    Write-Host -ForegroundColor Blue "Use Get-VMSwitch to check if the interface has been created."
}

$NetVMSwitchId = (Get-NetAdapter | Where-Object {$_.Name -like "*$NetVMSwitch*"}).ifIndex

New-NetIPAddress -IPAddress "$NetIPAddress" -PrefixLength "$PrefixLength" -InterfaceIndex "$NetVMSwitchId"

