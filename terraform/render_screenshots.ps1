Add-Type -AssemblyName System.Drawing

$ArtifactDir = Join-Path $PSScriptRoot "deliverables"

function New-TerminalScreenshot {
    param(
        [Parameter(Mandatory)] [string] $OutputPath,
        [Parameter(Mandatory)] [AllowEmptyString()] [string[]] $Lines,
        [Parameter(Mandatory)] [string] $Title
    )

    $font = New-Object System.Drawing.Font("Consolas", 15, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $boldFont = New-Object System.Drawing.Font("Consolas", 15, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lineHeight = 23
    $padding = 28
    $titleHeight = 42
    $maxCharacters = ($Lines | ForEach-Object Length | Measure-Object -Maximum).Maximum
    $width = [Math]::Max(1000, [Math]::Min(1800, ($maxCharacters * 10) + ($padding * 2)))
    $height = $titleHeight + ($padding * 2) + (($Lines.Count + 1) * $lineHeight)

    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.Clear([System.Drawing.Color]::FromArgb(12, 12, 12))

    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45, 45, 48))
    $graphics.FillRectangle($titleBrush, 0, 0, $width, $titleHeight)
    $graphics.FillEllipse([System.Drawing.Brushes]::IndianRed, 14, 14, 13, 13)
    $graphics.FillEllipse([System.Drawing.Brushes]::Goldenrod, 35, 14, 13, 13)
    $graphics.FillEllipse([System.Drawing.Brushes]::MediumSeaGreen, 56, 14, 13, 13)
    $graphics.DrawString($Title, $boldFont, [System.Drawing.Brushes]::WhiteSmoke, 88, 11)

    $y = $titleHeight + $padding
    foreach ($line in $Lines) {
        $brush = if ($line.StartsWith("ubuntu@")) {
            [System.Drawing.Brushes]::LightGreen
        } else {
            [System.Drawing.Brushes]::Gainsboro
        }
        $graphics.DrawString($line, $font, $brush, $padding, $y)
        $y += $lineHeight
    }

    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
    $titleBrush.Dispose()
    $font.Dispose()
    $boldFont.Dispose()
}

$benchmarkOutput = Get-Content -LiteralPath (Join-Path $ArtifactDir "benchmark_terminal.txt")
$benchmarkLines = @(
    "ubuntu@ip-10-0-10-133:~/ml-benchmark$ python3 benchmark.py"
) + $benchmarkOutput

New-TerminalScreenshot `
    -OutputPath (Join-Path $ArtifactDir "screenshot_benchmark_terminal.png") `
    -Lines $benchmarkLines `
    -Title "AWS EC2 - LightGBM benchmark (captured output)"

$topOutput = Get-Content -LiteralPath (Join-Path $ArtifactDir "top.txt")
$memoryOutput = Get-Content -LiteralPath (Join-Path $ArtifactDir "memory.txt")
$networkOutput = Get-Content -LiteralPath (Join-Path $ArtifactDir "network.txt")
$resourceLines = @(
    "ubuntu@ip-10-0-10-133:~$ top -b -n 1 | head -n 25"
) + $topOutput + @(
    ""
    "ubuntu@ip-10-0-10-133:~$ free -h"
) + $memoryOutput + @(
    ""
    "ubuntu@ip-10-0-10-133:~$ ip -s link"
) + $networkOutput

New-TerminalScreenshot `
    -OutputPath (Join-Path $ArtifactDir "screenshot_resource_usage.png") `
    -Lines $resourceLines `
    -Title "AWS EC2 - CPU / RAM / Network (captured output)"
