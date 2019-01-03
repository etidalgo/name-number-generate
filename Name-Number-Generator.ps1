# Start with a clean screen.
Clear-Host

# Set $ScriptFolder to the directory containing this script.
$ScriptFolder = Split-Path $MyInvocation.MyCommand.Definition -Parent

# Define required data files, for error handling.
$RequiredFiles = ('Males.txt','Females.txt','Surnames.txt')

# Check for required data files. Post errors for each missing file.
$RequiredFiles | ForEach-Object {
    if (!(Test-Path "$ScriptFolder\$_"))
    {
        Write-Host "$_ not found." -ForegroundColor Red
        $MissingFiles++
    }
}

# If files are missing, post final error, do variables cleanup, and exit.
if ($MissingFiles)
{
    Write-Host "Could not find $MissingFiles source file(s). Aborting script." -ForegroundColor Red
    Remove-Variable ScriptFolder,RequiredFiles,MissingFiles
    Exit
}

# Create a single-letter alias for Get-Random, since it's going to be used a LOT!
New-Alias g Get-Random

# Begin loop to get user input for number of items to be generated.
while (!$ValidInput)
{
    try
    {
        # Get input from the user and attempt to convert it to an integer.
        [int]$UserInput = Read-Host -Prompt 'Items to be generated'

        # If integer conversion is successful, set $ValidInput so loop will exit.
        $ValidInput = $true
    }

    catch
    {
        # Integer conversion failed. Alert user and retry.
        Write-Host 'Invalid input. Enter a number only.' -ForegroundColor Red
    }
}

# Announce items being generated.
Write-Host "`nGenerating $UserInput names & phone numbers. Please be patient.`n"

# Start generating names & numbers.
1..$UserInput | ForEach-Object {

    # Pick a surname.
    $Surname = Get-Content "$ScriptFolder\Surnames.txt" | g

    # Flip a coin for gender.
    $Male = g 2

    # Pick a first name based on the gender.
    if ($Male)
    {$FirstName = Get-Content "$ScriptFolder\Males.txt" | g}

    else
    {$FirstName = Get-Content "$ScriptFolder\Females.txt" | g}

    # Pick a phone number format randomly.
    $NumberFormat = g 5

    # Generate a random area code & exchange code based on the chosen format.
    switch ($NumberFormat)
    {
        # Area code invalid because it begins with a 1 or 0.
        0 {$Prefix = "($(g 2)$(g 10)$(g 10)) $(g 10)$(g 10)$(g 10)"}

        # Area code invalid because it has a 9 in the middle.
        1 {$Prefix = "($(g 10)9$(g 10)) $(g 10)$(g 10)$(g 10)"}

        # Exchange code invalid because it begins with a 1 or 0.
        2 {$Prefix = "($(g 10)$(g 10)$(g 10)) $(g 2)$(g 10)$(g 10)"}

        # Exchange code invalid because it ends in two 1s.
        3 {$Prefix = "($(g 10)$(g 10)$(g 10)) $(g 10)11"}

        # Exchange code invalid because it has three 5s.
        # Note: Other conditions must be met for 555 numbers to be invalid. These are applied later on.
        4 {$Prefix = "($(g 10)$(g 10)$(g 10)) 555"}
    }

    # Generate a random subscriber ID based on chosen format and $Prefix.
    switch ($NumberFormat)
    {
        # Subscriber ID for any non-555 number can be totally random.
        {$_ -lt 4} {$Suffix = "$(g 10)$(g 10)$(g 10)$(g 10)"}

        # Subscriber IDs for 555 numbers need to meet certain criteria.
        4 {
            switch ($Prefix)
            {
                # Only the 0199 subscriber ID is allowed for 555 numbers in the 800 area code.
                '(800) 555' {$Suffix = '0199'}

                # Any subscriber ID from 0100-0199 is allowed for the rest.
                default {$Suffix = "01$(g 10)$(g 10)"}
            }
        }
    }

    # Output name and number.
    Write-Output "$FirstName $Surname $Prefix-$Suffix"
}

# Final variables & aliases cleanup.
Remove-Item alias:\g
Remove-Variable ScriptFolder,RequiredFiles,Surname,Male,FirstName,NumberFormat,Prefix,Suffix,ValidInput,UserInput
