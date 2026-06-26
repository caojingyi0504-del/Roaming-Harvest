$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ProjectParent = Split-Path -Parent $ProjectRoot
$DefaultGodot = Join-Path $ProjectParent "Godot_v4.6.2-stable_win64.exe"
$Godot = if ($env:GODOT_EXE) { $env:GODOT_EXE } else { $DefaultGodot }

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found. Set GODOT_EXE to your Godot .exe path."
}

$LogPath = Join-Path $ProjectRoot "godot_grassworld_check.log"
& $Godot --headless --path $ProjectRoot --scene "res://scenes/GrassWorld.tscn" --quit-after 5 --log-file $LogPath
$ExitCode = $LASTEXITCODE

if (Test-Path -LiteralPath $LogPath) {
    $Problems = Select-String -Path $LogPath -Pattern "ERROR|SCRIPT ERROR|Parser Error|Parse Error" -CaseSensitive:$false
    if ($Problems) {
        $Problems | ForEach-Object { Write-Host $_.Line }
        exit 1
    }
}

exit $ExitCode
