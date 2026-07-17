# install-windows.ps1  (OPTIONAL)
#
# The docrig CAPTURE rig runs INSIDE your Kali VM (Linux/X11 only) -- this script
# does NOT install it. It only preps the Windows host for the optional next-day
# REPORTING / COMPILE phase: turning evidence bundles into a PDF and transcribing
# the narration locally. Capture always stays in Kali.
#
#   powershell -ExecutionPolicy Bypass -File .\reporting\install-windows.ps1

$ErrorActionPreference = 'Stop'

function Have($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

if (-not (Have 'winget')) {
  Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Yellow
  exit 1
}

# Reporting-phase toolchain only. All local / offline — nothing here is an AI chatbot.
$pkgs = @(
  @{ Name='ffmpeg'; Cmd='ffmpeg'; Id='Gyan.FFmpeg' },            # play / transcode narration, feed local STT
  @{ Name='pandoc'; Cmd='pandoc'; Id='JohnMacFarlane.Pandoc' },  # Markdown -> PDF / DOCX report
  @{ Name='python'; Cmd='python'; Id='Python.Python.3.12' }      # compile tooling / templating
)

foreach ($p in $pkgs) {
  if (Have $p.Cmd) {
    Write-Host ("[skip]    {0} already installed" -f $p.Name) -ForegroundColor DarkGray
  } else {
    Write-Host ("[install] {0} ({1})" -f $p.Name, $p.Id) -ForegroundColor Cyan
    winget install --id $p.Id -e --accept-source-agreements --accept-package-agreements
  }
}

Write-Host ""
Write-Host "Windows host is ready for the reporting/compile phase." -ForegroundColor Green
Write-Host "Notes:"
Write-Host "  - PDF export via pandoc also needs a LaTeX engine (e.g. TinyTeX/MiKTeX); install if you want PDF."
Write-Host "  - Zero-AI offline transcription: use whisper.cpp locally (no cloud, no chatbot)."
Write-Host "  - The capture rig itself lives in Kali: run reporting/install-kali.sh there."
