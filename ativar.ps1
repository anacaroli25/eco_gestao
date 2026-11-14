$env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + [Environment]::GetEnvironmentVariable("Path", "Machine")
Write-Host "PATH atualizado com sucesso!" -ForegroundColor Green
flutter --version
