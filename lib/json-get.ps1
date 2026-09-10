param(
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$Key
)
$ErrorActionPreference = 'Stop'
$j = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
$v = $j.PSObject.Properties[$Key]
if ($null -eq $v -or $null -eq $v.Value) { exit 3 }
[Console]::Write([string]$v.Value)
