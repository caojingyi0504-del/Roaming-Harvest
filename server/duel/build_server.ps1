param(
    [string]$Godot = $env:GODOT_BIN,
    [switch]$PackOnly
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$outputDirectory = Join-Path $PSScriptRoot "build\server"
$stagingDirectory = Join-Path $PSScriptRoot "build\staging"
$outputBinary = Join-Path $outputDirectory "RoamingHarvestDuelServer.x86_64"

if ([string]::IsNullOrWhiteSpace($Godot)) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        $Godot = $command.Source
    } else {
        $Godot = Join-Path (Split-Path $projectRoot -Parent) "Godot_v4.6.2-stable_win64.exe"
    }
}

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}

function Invoke-GodotExport([string]$Arguments) {
    $process = Start-Process -FilePath $Godot -ArgumentList $Arguments -WindowStyle Hidden -Wait -PassThru
    return $process.ExitCode
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stagingDirectory "scripts\duel") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stagingDirectory "scenes\duel") -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $PSScriptRoot "dedicated_project.godot") -Destination (Join-Path $stagingDirectory "project.godot") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "dedicated_export_presets.cfg") -Destination (Join-Path $stagingDirectory "export_presets.cfg") -Force
Copy-Item -LiteralPath (Join-Path $projectRoot "scenes\duel\DuelServer.tscn") -Destination (Join-Path $stagingDirectory "scenes\duel\DuelServer.tscn") -Force
foreach ($scriptName in @("duel_server.gd", "duel_endpoint.gd", "duel_match.gd", "duel_rules.gd")) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "scripts\duel\$scriptName") -Destination (Join-Path $stagingDirectory "scripts\duel\$scriptName") -Force
}

if ($PackOnly) {
    $checkPack = Join-Path $outputDirectory "DuelServerCheck.pck"
    if (Test-Path -LiteralPath $checkPack) {
        Remove-Item -LiteralPath $checkPack -Force
    }
	$engineExitCode = Invoke-GodotExport "--headless --path `"$stagingDirectory`" --export-pack `"Linux Duel Server`" `"$checkPack`""
    if (-not (Test-Path -LiteralPath $checkPack)) {
		throw "Dedicated server pack validation failed with exit code $engineExitCode"
    }
} else {
    $outputPack = [System.IO.Path]::ChangeExtension($outputBinary, ".pck")
    foreach ($oldOutput in @($outputBinary, $outputPack)) {
        if (Test-Path -LiteralPath $oldOutput) {
            Remove-Item -LiteralPath $oldOutput -Force
        }
    }
	$engineExitCode = Invoke-GodotExport "--headless --path `"$stagingDirectory`" --export-release `"Linux Duel Server`" `"$outputBinary`""
	if (-not (Test-Path -LiteralPath $outputBinary) -or -not (Test-Path -LiteralPath $outputPack)) {
		throw "Linux export failed. Install the matching Godot 4.6 Linux export templates, then retry. Engine exit code: $engineExitCode"
	}
}

Write-Host "Dedicated server build completed in $outputDirectory"
