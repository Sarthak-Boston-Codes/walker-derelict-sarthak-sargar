$log = Join-Path $PSScriptRoot 'watchdog.log'
$min = 99999
while ($true) {
  $free = [int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1KB)
  if ($free -lt $min) { $min = $free; "$(Get-Date -f s) new low $free MB" | Add-Content $log }
  if ($free -lt 2048) { "$(Get-Date -f s) STOP at $free MB" | Add-Content $log; Get-Process ffmpeg -EA SilentlyContinue | Stop-Process -Force; break }
  Start-Sleep -Seconds 3
}
