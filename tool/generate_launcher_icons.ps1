Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$master = Join-Path $root 'build/classfinder_icon_master.png'
$masterDir = Split-Path -Parent $master
if (-not (Test-Path $masterDir)) {
  New-Item -ItemType Directory -Path $masterDir | Out-Null
}

function New-RoundedRectPath {
  param(
    [float] $X,
    [float] $Y,
    [float] $Width,
    [float] $Height,
    [float] $Radius
  )

  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $diameter = $Radius * 2
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc(
    $X + $Width - $diameter,
    $Y + $Height - $diameter,
    $diameter,
    $diameter,
    0,
    90
  )
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-RoundedRect {
  param(
    [System.Drawing.Graphics] $Graphics,
    [System.Drawing.Brush] $Brush,
    [float] $X,
    [float] $Y,
    [float] $Width,
    [float] $Height,
    [float] $Radius
  )

  $path = New-RoundedRectPath $X $Y $Width $Height $Radius
  $Graphics.FillPath($Brush, $path)
  $path.Dispose()
}

function New-MasterIcon {
  $bitmap = [System.Drawing.Bitmap]::new(1024, 1024)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode =
    [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.RectangleF]::new(0, 0, 1024, 1024),
    [System.Drawing.Color]::FromArgb(255, 9, 19, 38),
    [System.Drawing.Color]::FromArgb(255, 17, 64, 116),
    35
  )
  $graphics.FillRectangle($background, 0, 0, 1024, 1024)
  $background.Dispose()

  $halo = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(34, 255, 255, 255)
  )
  Fill-RoundedRect $graphics $halo 80 94 864 836 172
  $halo.Dispose()

  $card = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 248, 250, 252)
  )
  Fill-RoundedRect $graphics $card 188 176 648 672 96
  $card.Dispose()

  $header = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 29, 78, 216)
  )
  Fill-RoundedRect $graphics $header 188 176 648 174 96
  $graphics.FillRectangle($header, 188, 266, 648, 84)
  $header.Dispose()

  $cyan = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 125, 225, 241)
  )
  $softCoral = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 255, 180, 134)
  )
  $graphics.FillEllipse($cyan, 288, 236, 42, 42)
  $graphics.FillEllipse($softCoral, 374, 236, 42, 42)
  $graphics.FillEllipse($cyan, 460, 236, 42, 42)
  $cyan.Dispose()
  $softCoral.Dispose()

  $gridPen = [System.Drawing.Pen]::new(
    [System.Drawing.Color]::FromArgb(255, 217, 226, 236),
    8
  )
  $gridPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $gridPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  foreach ($x in @(350, 512, 674)) {
    $graphics.DrawLine($gridPen, $x, 404, $x, 760)
  }
  foreach ($y in @(492, 584, 676)) {
    $graphics.DrawLine($gridPen, 262, $y, 762, $y)
  }
  $gridPen.Dispose()

  $blue = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 29, 78, 216)
  )
  $teal = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 8, 145, 178)
  )
  $green = [System.Drawing.SolidBrush]::new(
    [System.Drawing.Color]::FromArgb(255, 22, 163, 74)
  )
  Fill-RoundedRect $graphics $blue 280 422 192 54 20
  Fill-RoundedRect $graphics $teal 532 516 168 54 20
  Fill-RoundedRect $graphics $green 322 610 168 54 20
  $blue.Dispose()
  $teal.Dispose()
  $green.Dispose()

  $route = [System.Drawing.Pen]::new(
    [System.Drawing.Color]::FromArgb(255, 249, 115, 22),
    42
  )
  $route.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $route.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $route.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $graphics.DrawLines(
    $route,
    @(
      [System.Drawing.PointF]::new(330, 740),
      [System.Drawing.PointF]::new(448, 802),
      [System.Drawing.PointF]::new(706, 560)
    )
  )
  $route.Dispose()

  $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
  $graphics.FillEllipse($white, 310, 720, 42, 42)
  $graphics.FillEllipse($white, 686, 540, 42, 42)
  $white.Dispose()

  $bitmap.Save($master, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
}

function Resize-Icon {
  param(
    [string] $Destination,
    [int] $Size
  )

  $source = [System.Drawing.Image]::FromFile($master)
  $output = [System.Drawing.Bitmap]::new($Size, $Size)
  $graphics = [System.Drawing.Graphics]::FromImage($output)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode =
    [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.DrawImage($source, 0, 0, $Size, $Size)
  $output.Save((Join-Path $root $Destination), [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $output.Dispose()
  $source.Dispose()
}

New-MasterIcon

$targets = @(
  @{ Path = 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'; Size = 48 },
  @{ Path = 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png'; Size = 72 },
  @{ Path = 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'; Size = 96 },
  @{ Path = 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'; Size = 144 },
  @{ Path = 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'; Size = 192 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png'; Size = 20 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png'; Size = 40 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png'; Size = 60 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png'; Size = 29 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png'; Size = 58 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png'; Size = 87 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png'; Size = 40 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png'; Size = 80 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png'; Size = 120 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png'; Size = 120 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png'; Size = 180 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png'; Size = 76 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png'; Size = 152 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png'; Size = 167 },
  @{ Path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'; Size = 1024 }
)

foreach ($target in $targets) {
  Resize-Icon -Destination $target.Path -Size $target.Size
}

Write-Host "Generated $($targets.Count) launcher icons."
