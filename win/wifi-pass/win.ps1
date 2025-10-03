# Создаем временную директорию и переходим в нее
$TempDir = "$env:temp\wifi-passwords"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Set-Location $TempDir

# Экспортируем все профили Wi-Fi с паролями в XML-файлы
netsh wlan export profile key=clear | Out-Null

# Парсим XML-файлы, извлекаем имена сетей и пароли
$WifiData = Get-ChildItem -Path "*.xml" | ForEach-Object {
    $XmlContent = Get-Content -Path $_.FullName
    $XmlData = [xml]$XmlContent
    [PSCustomObject]@{
        SSID = $XmlData.WLANProfile.SSIDConfig.SSID.Name
        Password = $XmlData.WLANProfile.MSM.Security.SharedKey.KeyMaterial
    }
}

# Формируем полный путь к файлу и сохраняем данные
$OutputPath = "$env:USERPROFILE\Downloads\info123.txt"
$WifiData | Format-Table | Out-String | Out-File -FilePath $OutputPath

# Удаляем временную директорию
Remove-Item $TempDir -Recurse -Force
