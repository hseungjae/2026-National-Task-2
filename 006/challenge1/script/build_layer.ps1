# Pillow Lambda Layer 빌드 스크립트 (Windows PowerShell)
# challenge1/lambda/layer/python/ 에 Pillow 설치

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LayerDir = Join-Path $ScriptDir "..\lambda\layer\python"
$LayerDir = [System.IO.Path]::GetFullPath($LayerDir)

Write-Host ">>> Pillow Lambda Layer 빌드 시작"
Write-Host ">>> 설치 경로: $LayerDir"

# 기존 레이어 디렉토리 초기화
if (Test-Path $LayerDir) {
    Remove-Item -Recurse -Force $LayerDir
}
New-Item -ItemType Directory -Force -Path $LayerDir | Out-Null

# Amazon Linux 2023 호환 바이너리로 설치 시도
Write-Host ">>> manylinux 바이너리로 Pillow 설치 중..."
$result = pip install pillow `
    --target $LayerDir `
    --platform manylinux2014_x86_64 `
    --implementation cp `
    --python-version 3.13 `
    --only-binary=:all: `
    --quiet 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ">>> manylinux 실패, 로컬 환경으로 재시도..."
    pip install pillow --target $LayerDir --quiet
}

Write-Host ""
Write-Host ">>> 설치된 패키지:"
Get-ChildItem $LayerDir | Select-Object -First 10 -ExpandProperty Name

Write-Host ""
Write-Host ">>> 빌드 완료!"
Write-Host ">>> 이제 terraform apply 를 실행하세요:"
Write-Host "    cd $(Split-Path -Parent $ScriptDir)"
Write-Host "    terraform init"
Write-Host "    terraform apply"
