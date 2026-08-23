import { NextResponse } from 'next/server';

const SCRIPT = `# ==============================================================================
# LaterBox Windows PowerShell Installer
# Website: https://laterbox.dev
# Repository: https://github.com/Chaste-Djaziri/laterbox
# ==============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   LaterBox for Windows Installation    " -ForegroundColor Cyan
Write-Host "   https://laterbox.dev                 " -ForegroundColor DarkCyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'

$Repo = "Chaste-Djaziri/laterbox"
$PrimaryUrl = "https://laterbox.dev/downloads/laterbox-windows-setup.exe"
$FallbackUrl = "https://github.com/$Repo/releases/latest/download/laterbox-windows-setup.exe"
$TempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "laterbox-windows-setup.exe")

Write-Host "\`n[1/3] Downloading latest LaterBox Setup installer..." -ForegroundColor Yellow

try {
    Write-Host "  • Fetching: $PrimaryUrl"
    Invoke-WebRequest -Uri $PrimaryUrl -OutFile $TempFile -UseBasicParsing
} catch {
    Write-Host "  • Retrying via GitHub direct release..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $FallbackUrl -OutFile $TempFile -UseBasicParsing
}

Write-Host "[2/3] Launching LaterBox installer..." -ForegroundColor Yellow
Start-Process -FilePath $TempFile -Wait

Write-Host "\`n[3/3] Cleaning up temporary installer..." -ForegroundColor Yellow
if (Test-Path $TempFile) {
    Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
}

Write-Host "\`n✔ LaterBox installed successfully!" -ForegroundColor Green
Write-Host "You can now launch LaterBox from your Start Menu or Desktop." -ForegroundColor White
`;

export async function GET() {
  return new NextResponse(SCRIPT, {
    status: 200,
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'public, max-age=3600, s-maxage=3600',
    },
  });
}
