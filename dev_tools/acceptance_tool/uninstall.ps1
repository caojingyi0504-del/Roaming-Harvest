param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath($ProjectRoot.TrimEnd('\', '/'))
$projectFile = Join-Path $root "project.godot"
$expectedFolder = [System.IO.Path]::GetFullPath((Join-Path $root "dev_tools\acceptance_tool"))
$expectedLine = 'AcceptanceTool="*res://dev_tools/acceptance_tool/acceptance_tool.gd"'

if (-not (Test-Path -LiteralPath $projectFile -PathType Leaf)) {
    Write-Host "[FAILED] project.godot was not found. Nothing was changed." -ForegroundColor Red
    exit 10
}

if (-not $expectedFolder.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "[FAILED] Tool directory is outside the project root. Nothing was changed." -ForegroundColor Red
    exit 11
}

$text = [System.IO.File]::ReadAllText($projectFile)
$escaped = [System.Text.RegularExpressions.Regex]::Escape($expectedLine)
$matches = [System.Text.RegularExpressions.Regex]::Matches($text, "(?m)^$escaped`r?$")
if ($matches.Count -ne 1) {
    Write-Host "[FAILED] Expected exactly one AcceptanceTool autoload entry. Nothing was changed." -ForegroundColor Red
    exit 12
}

$updated = [System.Text.RegularExpressions.Regex]::Replace(
    $text,
    "(?m)^$escaped`r?`n?",
    "",
    1
)
$temporary = "$projectFile.acceptance_tool.tmp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($temporary, $updated, $utf8NoBom)
Move-Item -LiteralPath $temporary -Destination $projectFile -Force

Write-Host "[DONE] AcceptanceTool was removed from project.godot." -ForegroundColor Green
Write-Host "The wrapper will now remove the dedicated tool directory." -ForegroundColor Green
exit 0
