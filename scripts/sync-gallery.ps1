param(
  [string]$Source = "",
  [string]$DeployRoot = "",
  [string]$DefaultMedium = "Procreate",
  [int]$DefaultYear = 2026
)

$ErrorActionPreference = "Stop"

function To-RelativeWebPath {
  param([string]$Path)
  return ($Path -replace "\\", "/")
}

function Get-GalleryMeta {
  param(
    [string]$Root,
    [System.IO.FileInfo]$File
  )

  $rootPath = (Resolve-Path $Root).Path.TrimEnd("\", "/")
  $relative = $File.FullName.Substring($rootPath.Length).TrimStart("\", "/")
  $parts = $relative -split "[\\/]"
  $title = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)

  if ($parts.Count -eq 1) {
    return @{
      Category = ""
      Author = "Unknown"
      Title = $title
      Relative = $relative
    }
  }

  if ($parts.Count -eq 2) {
    return @{
      Category = ""
      Author = $parts[0]
      Title = $title
      Relative = $relative
    }
  }

  $category = ($parts[0..($parts.Count - 3)] -join " / ")
  return @{
    Category = $category
    Author = $parts[$parts.Count - 2]
    Title = $title
    Relative = $relative
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")

if ([string]::IsNullOrWhiteSpace($DeployRoot)) {
  $DeployRoot = $repoRoot.Path
}

if ([string]::IsNullOrWhiteSpace($Source)) {
  $workspaceSource = Join-Path (Split-Path -Parent $repoRoot.Path) "assets/gallery"
  $repoSource = Join-Path $repoRoot.Path "assets/gallery"
  if (Test-Path $workspaceSource) {
    $Source = $workspaceSource
  } else {
    $Source = $repoSource
  }
}

$sourcePath = Resolve-Path $Source
$deployPath = Resolve-Path $DeployRoot
$bundleGallery = Join-Path $deployPath "assets/bundle/gallery"
$dataPath = Join-Path $deployPath "assets/gallery-data.js"

New-Item -ItemType Directory -Path $bundleGallery -Force | Out-Null

$extensions = @(".jpg", ".jpeg", ".png", ".webp", ".gif")
$files = Get-ChildItem -LiteralPath $sourcePath -Recurse -File |
  Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
  Sort-Object FullName

$items = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
  $meta = Get-GalleryMeta -Root $sourcePath -File $file
  $relative = $meta.Relative
  $target = Join-Path $bundleGallery $relative
  $targetDir = Split-Path -Parent $target
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  Copy-Item -LiteralPath $file.FullName -Destination $target -Force

  $webRelative = To-RelativeWebPath $relative
  $id = "gallery/" + ([System.IO.Path]::ChangeExtension($webRelative, $null).TrimEnd("."))

  $items.Add([ordered]@{
    id = $id
    category = $meta.Category
    authorName = $meta.Author
    title = $meta.Title
    medium = $DefaultMedium
    year = $DefaultYear
    note = ""
    img = "assets/bundle/gallery/$webRelative"
    imgPosition = "50% 50%"
    imgFit = "contain"
  })
}

$json = ConvertTo-Json -InputObject @($items.ToArray()) -Depth 8
if ([string]::IsNullOrWhiteSpace($json)) {
  $json = "[]"
}

$content = @"
window.GALLERY_ARTWORKS = $json;
"@

Set-Content -LiteralPath $dataPath -Value $content -Encoding UTF8

Write-Output "Synced $($items.Count) artwork(s)."
Write-Output "Source: $sourcePath"
Write-Output "Data: $dataPath"
Write-Output "Images: $bundleGallery"
