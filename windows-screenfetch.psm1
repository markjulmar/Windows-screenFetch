#### Screenfetch for powershell
#### Author Julian Chow


Function Screenfetch($distro)
{
    $AsciiArt = "";

    if (-not $distro) 
    {
        $AsciiArt = . Get-WindowsArt;
    }

    if (([string]::Compare($distro, "mac", $true) -eq 0) -or 
        ([string]::Compare($distro, "macOS", $true) -eq 0) -or 
        ([string]::Compare($distro, "osx", $true) -eq 0)) {
            
        $AsciiArt = . Get-MacArt;
    }
    else 
    {
        $AsciiArt = . Get-WindowsArt;
    }

    $SystemInfoCollection = . Get-SystemSpecifications;
    $LineToTitleMappings = . Get-LineToTitleMappings;

    if ($SystemInfoCollection.Count -gt $AsciiArt.Count) 
    { 
        Write-Error "System Specs occupies more lines than the Ascii Art resource selected"
    }

    for ($line = 0; $line -lt $AsciiArt.Count; $line++) 
    {
        Write-Host $AsciiArt[$line] -f Red -NoNewline;

        if ($line -eq 0) 
        {
            Write-Host $SystemInfoCollection[$line] -f Cyan;
        }

        elseif ($LineToTitleMappings.Count -gt $line)
        {
            Write-Host $LineToTitleMappings[$line] -f Cyan -NoNewline;
            Write-Host $SystemInfoCollection[$line];
        }

        elseif ($SystemInfoCollection.Count -gt $line) 
        {
            if ($SystemInfoCollection[$line] -like '*:*')
            {
                $Separator = ":";
                $Index = $SystemInfoCollection[$line].IndexOf($Separator)

                if ($Index -ge 0) {
                    $Title = $SystemInfoCollection[$line].Substring(0, $Index + 1) + ' '  # Includes the colon
                    $Content = $SystemInfoCollection[$line].Substring($Index + 1).Trim()  # Everything after the colon

                    Write-Host $Title -f Cyan -NoNewline
                    Write-Host $Content
                }
                else {
                    # If no colon exists, just print the line normally
                    Write-Host $SystemInfoCollection[$line]
                }
            }
            else
            {
                Write-Host $SystemInfoCollection[$line];            
            }
        }
        else {
            Write-Host("");
        }
    }
}

