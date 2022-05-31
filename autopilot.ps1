$progressPreference = 'silentlyContinue'
$serial = (Get-WmiObject -Class win32_bios).serialnumber

Write-Progress -Activity "Installing NuGet package provider." -Status "Working" -PercentComplete 0
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Downloading and installing Azure AD and WindowsAutoPilotIntune Module
Write-Progress -Activity "Downloading and installing AzureAD module"
Install-Module AzureAD,WindowsAutoPilotIntune,Microsoft.Graph.Intune -Force

# Importing required modules
Import-Module -Name AzureAD,WindowsAutoPilotIntune,Microsoft.Graph.Intune 


# Downloading and installing get-windowsautopilotinfo script
Write-Progress "Downloading and installing get-windowsautopilotinfo script"
Install-Script -Name Get-WindowsAutoPilotInfo -Force

# Intune Login
Write-Progress "Connecting to Microsoft Graph"
Try {
    Connect-MSGraph -Credential (Get-credential -message "Type in the user and password")
    write-host "Successfully connected to Microsoft Graph" -foregroundcolor green
}
Catch {
    write-host "Error: Could not connect to Microsoft Graph. Please login with the account that has premissions to administer Intune and autopilot or verify your password" -foregroundcolor red 
Break }


# Creating temporary folder to store autopilot csv file 

Write-Progress "Checking if Temp folder exist in C:\"

IF (!(Test-Path C:\Temp) -eq $true) {

    Write-Host "Test folder was not found in C:\. Creating Test Folder..." -ForegroundColor Cyan
    New-Item -Path C:\Temp -ItemType Directory | Out-Null
}

Else { Write-Host "Test folder already exist" -ForegroundColor Green }



$tag = Read-Host "Enter group tag"
while($tag -eq "")
{
    $confirm = Read-Host "Group tag is empty. Continue and leave empty? [Y/N]"
    if($confirm -eq "Y")
    {
        break
    }
    else
    {
        $tag = Read-Host "Enter group tag:"
    }
}

# Creating Autopilot csv file
Write-Progress "Creating Autopilot CSV File"
Try {
    $hwinfo = &"C:\Program Files\WindowsPowerShell\Scripts\Get-WindowsAutoPilotInfo.ps1"
    Add-Member -InputObject $hwinfo -NotePropertyName "Group Tag" -NotePropertyValue $tag
    $hwinfo | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', ""}  | out-file c:\temp\$serial.csv

    Write-Host "Successfully created autopilot csv file" -ForegroundColor Green}

Catch {
    write-host "Error: Something went wrong. Unable to create csv file." -foregroundcolor red 
Break }

 

#Importing CSV File into Intune
Write-Progress "Importing Autopilot CSV File into Intune"
Try {
    Import-AutoPilotCSV -csvFile "C:\Temp\$serial.csv"
    Write-Host "Successfully imported autopilot csv file" -ForegroundColor Green}

Catch {
    Write-Host "Error: Something went wrong. Please check your csv file and try again"
    Break}