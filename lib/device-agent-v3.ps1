param(
  [Parameter(Mandatory=$true)][string]$SessionId,
  [Parameter(Mandatory=$true)][string]$AgentId,
  [Parameter(Mandatory=$true)][string]$LogRepo,
  [Parameter(Mandatory=$true)][string]$ControlPath,
  [Parameter(Mandatory=$true)][string]$ReportPrefix,
  [Parameter(Mandatory=$true)][string]$SourceRepo,
  [Parameter(Mandatory=$true)][string]$SourceRef
)
$ErrorActionPreference = 'Stop'
$Work = 'C:\WinRERepair'
$AgentDir = Join-Path $Work 'agent'
$TokenPath = Join-Path $Work '.auth\github-logs.token'
$Safety = Join-Path $Work 'runtime\safety.cmd'
$Curl = 'C:\Windows\System32\curl.exe'
$ResultEnv = Join-Path $Work 'COMMAND_RESULT.env'
$Attach = Join-Path $Work 'REPORT_ATTACHMENT.txt'
$Last = Join-Path $AgentDir 'last-command-id.txt'
$Inflight = Join-Path $AgentDir 'inflight-command-id.txt'
$Interrupted = Join-Path $AgentDir 'interrupted-command-id.txt'
New-Item -ItemType Directory -Force -Path $AgentDir,(Join-Path $Work '.auth'),(Join-Path $Work 'runtime') | Out-Null
if (!(Test-Path $TokenPath) -or !(Test-Path $Safety) -or !(Test-Path $Curl)) { exit 91 }
$Token = (Get-Content -LiteralPath $TokenPath -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($Token)) { exit 90 }

function Invoke-Curl([string[]]$Args) {
  & $Curl @Args
  return $LASTEXITCODE
}
function Upload-Text([string]$Path,[string]$Message,[string]$RepoPath) {
  $bytes = [IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -gt 51200) { return $false }
  $b64 = [Convert]::ToBase64String($bytes)
  $body = @{ message=$Message; content=$b64 } | ConvertTo-Json -Compress
  $bodyPath = Join-Path $Work ('upload-' + [Guid]::NewGuid().ToString('N') + '.json')
  [IO.File]::WriteAllText($bodyPath,$body,[Text.UTF8Encoding]::new($false))
  $url = 'https://api.github.com/repos/' + $LogRepo + '/contents/' + $RepoPath
  $args = @('--ssl-no-revoke','--silent','--show-error','--connect-timeout','15','--max-time','120','-X','PUT','-H','Accept: application/vnd.github+json','-H',('Authorization: Bearer ' + $Token),'-H','X-GitHub-Api-Version: 2022-11-28','-H','Content-Type: application/json','--data-binary',('@' + $bodyPath),$url,'-o',(Join-Path $Work 'upload-response.json'),'-w','%{http_code}')
  $http = & $Curl @args
  $rc = $LASTEXITCODE
  Remove-Item -LiteralPath $bodyPath -Force -ErrorAction SilentlyContinue
  return ($rc -eq 0 -and ($http -as [int]) -in 200,201)
}
function Report([string]$Status,[int]$Rc,[string]$Message,[string]$Evidence,[string]$CommandId='') {
  $r = @(
    'status=' + $Status,
    'return_code=' + $Rc,
    'session_id=' + $SessionId,
    'agent_id=' + $AgentId,
    'command_id=' + $CommandId,
    'date=' + (Get-Date -Format 'yyyy-MM-dd'),
    'time=' + (Get-Date -Format 'HH:mm:ss'),
    'message=' + $Message,
    'evidence=' + $Evidence
  ) -join "`r`n"
  $r += "`r`n"
  $rf = Join-Path $Work 'LAST_RUN_REPORT.txt'
  [IO.File]::WriteAllText($rf,$r,[Text.UTF8Encoding]::new($false))
  $name = 'run-' + $AgentId + '-' + [Guid]::NewGuid().ToString('N') + '.txt'
  [void](Upload-Text $rf 'RescueMeAI bounded recovery report' ($ReportPrefix + '/' + $name))
  if (Test-Path $Attach) {
    $ainfo = Get-Item $Attach
    if ($ainfo.Length -le 51200) {
      $aname = 'attachment-' + $AgentId + '-' + [Guid]::NewGuid().ToString('N') + '.txt'
      [void](Upload-Text $Attach 'RescueMeAI bounded diagnostic attachment' ($ReportPrefix + '/' + $aname))
    }
    Remove-Item -LiteralPath $Attach -Force -ErrorAction SilentlyContinue
  }
}
function Read-HandledId([string]$Path) {
  if (!(Test-Path $Path)) { return 0L }
  $s = (Get-Content -LiteralPath $Path -Raw).Trim()
  if ($s -match '^\d{1,15}$') { return [int64]$s }
  return 0L
}

if (Test-Path $Inflight) {
  $old = (Get-Content -LiteralPath $Inflight -Raw).Trim()
  if ($old -match '^\d{1,15}$') {
    Set-Content -LiteralPath $Interrupted -Value $old -NoNewline
    Set-Content -LiteralPath $Last -Value $old -NoNewline
    Remove-Item -LiteralPath $Inflight -Force -ErrorAction SilentlyContinue
    Report 'WARNING' 40 'A previous queued command was interrupted and was not replayed.' ('Interrupted command ID ' + $old) $old
  }
}

Report 'PASS' 0 'RescueMeAI device agent is online and listening for validated commands.' 'None.' ''
Clear-Host
Write-Host '================================================================'
Write-Host 'RescueMeAI secure support channel is ONLINE'
Write-Host '================================================================'
Write-Host ('Session : ' + $SessionId)
Write-Host ('Agent   : ' + $AgentId)
Write-Host 'Mode    : OUTBOUND GITHUB POLLING'
Write-Host 'Safety  : LOCAL GATE ACTIVE'
Write-Host ''
Write-Host 'Leave this window open. No inbound remote shell is open.'
Write-Host '================================================================'

while ($true) {
  try {
    $queue = Join-Path $AgentDir 'queue.json'
    $url = 'https://api.github.com/repos/' + $LogRepo + '/contents/' + $ControlPath + '?ref=main'
    $args = @('--ssl-no-revoke','--silent','--show-error','--connect-timeout','15','--max-time','120','-H','Accept: application/vnd.github.raw+json','-H',('Authorization: Bearer ' + $Token),'-H','X-GitHub-Api-Version: 2022-11-28',$url,'-o',$queue,'-w','%{http_code}')
    $http = & $Curl @args
    if ($LASTEXITCODE -ne 0 -or ($http -as [int]) -ne 200) { Start-Sleep -Seconds 10; continue }
    $c = Get-Content -LiteralPath $queue -Raw | ConvertFrom-Json
    if ([int]$c.protocol -ne 1) { Report 'FAIL' 93 'Unsupported command protocol.' 'No command executed.' ''; Start-Sleep 10; continue }
    $cidText = [string]$c.command_id
    if ($cidText -notmatch '^\d{1,15}$') { Report 'FAIL' 93 'Invalid command ID.' 'No command executed.' ''; Start-Sleep 10; continue }
    $cid = [int64]$cidText
    $handled = [Math]::Max((Read-HandledId $Last),(Read-HandledId $Inflight))
    if ($cid -le $handled) { Start-Sleep -Seconds 10; continue }
    $action = ([string]$c.action).ToUpperInvariant()
    if ($action -notin @('PING','STOP_AGENT','RUN_NEXT')) { Report 'FAIL' 94 'Non-allowlisted command action rejected.' 'Nothing executed.' $cidText; Start-Sleep 10; continue }
    $target = ([string]$c.target_agent).ToUpperInvariant()
    if ($target -ne '*' -and $target -ne $AgentId.ToUpperInvariant()) { Start-Sleep 10; continue }
    $risk = ([string]$c.risk).ToUpperInvariant()
    if ($risk -notin @('READ_ONLY','REPAIR_WRITE','DESTRUCTIVE')) { Report 'FAIL' 93 'Invalid risk classification.' 'Nothing executed.' $cidText; Start-Sleep 10; continue }
    Set-Content -LiteralPath $Inflight -Value $cidText -NoNewline

    if ($action -eq 'PING') {
      Set-Content -LiteralPath $Last -Value $cidText -NoNewline
      Remove-Item -LiteralPath $Inflight -Force -ErrorAction SilentlyContinue
      Report 'PASS' 0 'RescueMeAI command channel responded successfully.' 'None.' $cidText
      Start-Sleep 10; continue
    }
    if ($action -eq 'STOP_AGENT') {
      Set-Content -LiteralPath $Last -Value $cidText -NoNewline
      Remove-Item -LiteralPath $Inflight -Force -ErrorAction SilentlyContinue
      Report 'PASS' 0 'RescueMeAI agent stopped by authenticated control command.' 'None.' $cidText
      exit 0
    }

    $repo = [string]$c.repo; $path = [string]$c.path; $ref = [string]$c.ref; $sha = ([string]$c.sha256).ToLowerInvariant()
    if ($repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or $path -notmatch '^[A-Za-z0-9_.\/-]+$' -or $ref -notmatch '^[0-9a-fA-F]{40}$' -or $sha -notmatch '^[0-9a-fA-F]{64}$') {
      Report 'FAIL' 93 'RUN_NEXT source metadata failed validation.' 'Nothing executed.' $cidText
      Set-Content -LiteralPath $Last -Value $cidText -NoNewline; Remove-Item $Inflight -Force -ErrorAction SilentlyContinue; Start-Sleep 10; continue
    }
    $cmdFile = Join-Path $AgentDir ('command-' + $cidText + '.cmd')
    $cmdUrl = 'https://api.github.com/repos/' + $repo + '/contents/' + $path + '?ref=' + $ref
    $args = @('--ssl-no-revoke','--fail','--silent','--show-error','--connect-timeout','15','--max-time','120','-H','Accept: application/vnd.github.raw+json','-H',('Authorization: Bearer ' + $Token),'-H','X-GitHub-Api-Version: 2022-11-28',$cmdUrl,'-o',$cmdFile)
    & $Curl @args
    if ($LASTEXITCODE -ne 0) { Report 'FAIL' 90 'Immutable recovery command could not be downloaded.' 'No command executed.' $cidText; Set-Content $Last $cidText -NoNewline; Remove-Item $Inflight -Force -ErrorAction SilentlyContinue; Start-Sleep 10; continue }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $cmdFile).Hash.ToLowerInvariant()
    if ($actual -ne $sha) { Report 'FAIL' 96 'Recovery command integrity verification failed.' 'Downloaded command was not executed.' $cidText; Set-Content $Last $cidText -NoNewline; Remove-Item $Inflight -Force -ErrorAction SilentlyContinue; Start-Sleep 10; continue }

    & $Safety evaluate $cmdFile $risk $cidText $target $AgentId
    $safeRc = $LASTEXITCODE
    if ($safeRc -eq 40) { Report 'WARNING' 40 'Destructive command was blocked because local authorization was not provided.' 'Nothing destructive executed.' $cidText; Set-Content $Last $cidText -NoNewline; Remove-Item $Inflight -Force -ErrorAction SilentlyContinue; Start-Sleep 10; continue }
    if ($safeRc -ge 80) { Report 'FAIL' $safeRc 'Local safety gate rejected the queued command.' 'Nothing executed.' $cidText; Set-Content $Last $cidText -NoNewline; Remove-Item $Inflight -Force -ErrorAction SilentlyContinue; Start-Sleep 10; continue }

    Remove-Item -LiteralPath $ResultEnv -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Attach -Force -ErrorAction SilentlyContinue
    & $env:ComSpec /d /c ('call "' + $cmdFile + '"')
    $cmdRc = $LASTEXITCODE
    $status = if ($cmdRc -eq 0) {'PASS'} elseif ($cmdRc -ge 80) {'FAIL'} else {'WARNING'}
    $message = if ($cmdRc -eq 0) {'Recovery command completed successfully.'} elseif ($cmdRc -ge 80) {'Recovery command stopped because a required step failed.'} else {'Recovery command completed with a condition requiring review.'}
    $evidence = 'None unless specifically requested.'
    if (Test-Path $ResultEnv) {
      foreach ($line in Get-Content -LiteralPath $ResultEnv) {
        if ($line -match '^([^=]+)=(.*)$') {
          switch ($matches[1].ToUpperInvariant()) {
            'STATUS' { $status = $matches[2] }
            'MESSAGE' { $message = $matches[2] }
            'EVIDENCE' { $evidence = $matches[2] }
          }
        }
      }
    }
    Report $status $cmdRc $message $evidence $cidText
    Set-Content -LiteralPath $Last -Value $cidText -NoNewline
    Remove-Item -LiteralPath $Inflight -Force -ErrorAction SilentlyContinue
  } catch {
    Report 'WARNING' 40 ('Agent loop exception: ' + $_.Exception.Message) 'No command was executed unless already reported.' ''
  }
  Start-Sleep -Seconds 10
}
