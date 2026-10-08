# Records the three film captures with Godot Movie Maker, converts each to MP4
# (H.264 crf 12 + AAC 256k), and writes SHA-256s of the raw AVI and the MP4.
# Run from anywhere:  powershell -File record_all.ps1
param([string[]]$Only = @())
$exe  = "C:\Users\sarth\GotDot\Godot_v4.7.2-stable_win64.exe"
$film = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$game = Join-Path (Split-Path -Parent (Split-Path -Parent $film)) "godot"
$cap  = Join-Path $film "captures"
foreach ($r in @(@("RUN_A_clear","clear"), @("RUN_B_grab","grab"), @("RUN_C_mute","mute"))) {
    $name, $route = $r
    if ($Only.Count -and $route -notin $Only) { continue }
    $avi = Join-Path $cap "$name.avi"
    $env:ROUTE = $route
    $env:ROUTE_LOG = Join-Path $cap "$name.route.log"
    & $exe --path $game --write-movie $avi --fixed-fps 30 -s (Join-Path $PSScriptRoot "route.gd") 2>&1 |
        ForEach-Object { "$_" } | Select-String "frames at|TIMEOUT|SCRIPT ERROR"
    $aviHash = (Get-FileHash $avi -Algorithm SHA256).Hash.ToLower()
    $mp4 = Join-Path $cap "$name.mp4"
    ffmpeg -v error -y -i $avi -c:v libx264 -preset medium -crf 12 -pix_fmt yuv420p -c:a aac -b:a 256k $mp4
    $mp4Hash = (Get-FileHash $mp4 -Algorithm SHA256).Hash.ToLower()
    "$name  avi_sha256=$aviHash  mp4_sha256=$mp4Hash"
}
