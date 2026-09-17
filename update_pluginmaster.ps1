param([switch]$NoPush)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginmasterPath = Join-Path $root "pluginmaster.json"
$pluginsDir = Join-Path $root "plugins"

$pluginmaster = Get-Content -LiteralPath $pluginmasterPath -Raw -Encoding UTF8 | ConvertFrom-Json
$pluginmaster = @($pluginmaster)

Get-ChildItem -LiteralPath $pluginsDir -Directory | ForEach-Object {
    $subdir = $_.FullName
    $jsonFiles = @(Get-ChildItem -LiteralPath $subdir -Filter "*.json" -File)
    if ($jsonFiles.Count -eq 0) {
        Write-Warning "No JSON file found in $subdir"
        return
    }
    foreach ($jsonFile in $jsonFiles) {
        $pluginJsonPath = $jsonFile.FullName
        Write-Host "Processing: $pluginJsonPath"
        $pluginData = Get-Content -LiteralPath $pluginJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $internalName = $pluginData.InternalName
        if ([string]::IsNullOrWhiteSpace($internalName)) {
            throw "Missing InternalName: $pluginJsonPath"
        }

        $match = $null
        for ($i = 0; $i -lt $pluginmaster.Count; $i++) {
            if ($pluginmaster[$i].InternalName -eq $internalName) {
                $match = $i
                break
            }
        }

        if ($match -eq $null) {
            if (-not (Test-Path -LiteralPath (Join-Path $subdir 'latest.zip'))) {
                throw "Missing latest.zip for new plugin: $internalName"
            }
            $folder = [Uri]::EscapeDataString((Split-Path -Leaf $subdir))
            $url = "https://raw.githubusercontent.com/eroubue/DalamudPlugins/refs/heads/main/plugins/$folder/latest.zip"
            foreach ($field in @('DownloadLinkInstall', 'DownloadLinkUpdate', 'DownloadLinkTesting')) {
                $pluginData | Add-Member -NotePropertyName $field -NotePropertyValue $url -Force
            }
            $pluginmaster += $pluginData
            Write-Host "  Added entry: $internalName"
            continue
        }

        Write-Host "  Updating entry [$match]: $internalName"

        $entry = $pluginmaster[$match]

        if ($pluginData.PSObject.Properties.Name -contains "DalamudApiLevel") {
            $old = $entry.DalamudApiLevel
            $new = $pluginData.DalamudApiLevel
            $entry | Add-Member -NotePropertyName DalamudApiLevel -NotePropertyValue $new -Force
            Write-Host "    DalamudApiLevel: $old -> $new"
        }

        if ($pluginData.PSObject.Properties.Name -contains "AssemblyVersion") {
            $old = $entry.AssemblyVersion
            $new = $pluginData.AssemblyVersion
            $entry | Add-Member -NotePropertyName AssemblyVersion -NotePropertyValue $new -Force
            Write-Host "    AssemblyVersion: $old -> $new"
        }

        if ($pluginData.PSObject.Properties.Name -contains "Description") {
            $old = $entry.Description
            $new = $pluginData.Description
            $entry | Add-Member -NotePropertyName Description -NotePropertyValue $new -Force
            Write-Host "    Description: $old -> $new"
        }

        if ($pluginData.PSObject.Properties.Name -contains "Punchline") {
            $old = $entry.Punchline
            $new = $pluginData.Punchline
            $entry | Add-Member -NotePropertyName Punchline -NotePropertyValue $new -Force
            Write-Host "    Punchline: $old -> $new"
        }
    }
}

$json = ConvertTo-Json -InputObject @($pluginmaster) -Depth 100
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($pluginmasterPath, $json, $utf8NoBom)
Write-Host "`nDone. Updated $pluginmasterPath"

if (-not $NoPush) {
    function Invoke-RepositoryGit {
        param([string[]]$GitArguments)
        & git -C $root @GitArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Git failed: git $($GitArguments -join ' ')"
        }
    }

    $branch = Invoke-RepositoryGit @('branch', '--show-current')
    if ($branch -ne 'main') { throw 'Publish from main: download links point to main.' }
    $staged = Invoke-RepositoryGit @('diff', '--cached', '--name-only')
    if ($staged) { throw 'Commit or unstage existing staged changes before publishing.' }
    Invoke-RepositoryGit @('add', '--', 'pluginmaster.json', 'plugins', 'update_pluginmaster.ps1', 'README.md', '.gitignore')
    $changes = Invoke-RepositoryGit @('diff', '--cached', '--name-only')
    if ($changes) {
        Invoke-RepositoryGit @('commit', '-m', 'Update plugin manifests and packages')
    }
    Invoke-RepositoryGit @('push', 'origin', 'main')
}
