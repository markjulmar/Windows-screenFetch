Add-Type -AssemblyName System.Windows.Forms

Function Get-SystemSpecifications() 
{

    $UserInfo = Get-UserInformation;
    $OS = Get-OS;
    $Kernel = Get-Kernel;
    $Uptime = Get-FormattedUptime;
    $Motherboard = Get-Mobo;
    $Shell = Get-Shell;
    $Resolution = Get-Resolution;
    $NetworkInfo = Get-NetworkInfo;
    $CPU = Get-CPU;
    $GPU = Get-GPU;
    $RAM = Get-RAM;
    $Disks = Get-Disks;


    [System.Collections.ArrayList] $SystemInfoCollection = 
        $UserInfo.ToString(), 
        $OS.ToString(), 
        $Kernel.ToString(),
        $Uptime.ToString(),
        $Motherboard.ToString(),
        $Shell.ToString(),
        $Resolution.ToString(),
        $NetworkInfo.ToString(),
        $CPU.ToString(),
        $GPU.ToString(),
        $RAM.ToString();

    foreach ($Disk in $Disks)
    {
        [void]$SystemInfoCollection.Add($Disk.ToString());
    }
    
    return $SystemInfoCollection;
}

Function Get-LineToTitleMappings() 
{ 
    $TitleMappings = @{
        0 = "";
        1 = "OS: "; 
        2 = "Kernel: ";
        3 = "Uptime: ";
        4 = "Motherboard: ";
        5 = "Shell: ";
        6 = "Resolution: ";
        7 = "Network: ";
        8 = "CPU: ";
        9 = "GPU: ";
        10 = "RAM: ";
    };

    return $TitleMappings;
}

Function Get-UserInformation()
{
    return [System.Environment]::UserName + "@" + [System.Environment]::MachineName;
    #return (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object UserName).UserName.Split('\')[1];
}

Function Get-OS()
{
    $servicePack = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion | Select-Object -ExpandProperty DisplayVersion;
    return (Get-CimInstance -Class CIM_OperatingSystem).Caption + " " + $servicePack + ", " + (Get-CimInstance -Class CIM_OperatingSystem).OSArchitecture;
}

Function Get-Kernel()
{
    return [System.Environment]::OSVersion.Version;
}

Function Get-FormattedUptime()
{
    return (Get-CimInstance -ClassName CIM_OperatingSystem).LastBootUpTime -replace '\\r?\\n', '';
}

Function Get-NetworkInfo()
{
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | 
    Where-Object IPAddress | 
    ForEach-Object {
        $adapter = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.DeviceID -eq $_.Index } | Select-Object -First 1
        $type = Switch ($adapter.AdapterType) {
            "Ethernet 802.3" { "Ethernet" }
            "Wireless LAN" { "Wi-Fi" }
            default {
                if ($adapter.NetConnectionID -match "VPN") { "VPN" } else { "Other" }
            }
        }

        [PSCustomObject]@{
            Type        = $type
            Description = $_.Description
            IPv4Address = ($_.IPAddress -match '^\d+\.\d+\.\d+\.\d+$')[0]
        }
    }

    return $adapters[0].Type + ": " + $adapters[0].IPv4Address

}

Function Get-Mobo()
{
    $Motherboard = Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product;
    return $Motherboard.Manufacturer + " " + $Motherboard.Product;

}

Function Get-Shell()
{
    return "PowerShell $($PSVersionTable.PSVersion.ToString())";
}

Function Get-Resolution()
{
    $VideoInfo = Get-CimInstance Win32_VideoController | Where-Object CurrentHorizontalResolution -ge 800 | Select-Object Name, CurrentHorizontalResolution, CurrentVerticalResolution;
    return $VideoInfo[0].CurrentHorizontalResolution.ToString() + "x" + $VideoInfo[0].CurrentVerticalResolution.ToString();
}


Function Get-CPU() 
{
    return (Get-CimInstance -Class CIM_Processor).Name;
}

Function Get-GPU() 
{
    return (Get-CimInstance -Class Win32_VideoController).Name -join ', ';
}

Function Get-RAM() 
{
    $FreeRam = ([math]::Truncate((Get-CIMInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB)); 
    $TotalRam = ([math]::Truncate((Get-CIMInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB));
    $UsedRam = $TotalRam - $FreeRam;
    $FreeRamPercent = ($FreeRam / $TotalRam) * 100;
    $FreeRamPercent = "{0:N0}" -f $FreeRamPercent;
    $UsedRamPercent = ($UsedRam / $TotalRam) * 100;
    $UsedRamPercent = "{0:N0}" -f $UsedRamPercent;

    return $UsedRam.ToString() + "GB / " + $TotalRam.ToString() + "GB " + "(" + $UsedRamPercent.ToString() + "%" + ")";
}

Function Get-Disks() 
{     
    $FormattedDisks = New-Object System.Collections.Generic.List[System.Object];

    $NumDisks = (Get-CimInstance Win32_LogicalDisk).Count;

    if ($NumDisks) 
    {
        for ($i=0; $i -lt ($NumDisks); $i++) 
        {
            $DiskID = (Get-CimInstance Win32_LogicalDisk)[$i].DeviceId;

            $FreeDiskSize = (Get-CimInstance Win32_LogicalDisk)[$i].FreeSpace
            $FreeDiskSizeGB = $FreeDiskSize / 1073741824;
            $FreeDiskSizeGB = "{0:N0}" -f $FreeDiskSizeGB -replace "\D+";

            $DiskSize = (Get-CimInstance Win32_LogicalDisk)[$i].Size;
            $DiskSizeGB = $DiskSize / 1073741824;
            $DiskSizeGB = "{0:N0}" -f $DiskSizeGB -replace "\D+";

            $FreeDiskPercent = ($FreeDiskSizeGB / $DiskSizeGB) * 100;
            $FreeDiskPercent = "{0:N0}" -f $FreeDiskPercent;

            $UsedDiskSizeGB = $DiskSizeGB - $FreeDiskSizeGB;
            $UsedDiskPercent = ($UsedDiskSizeGB / $DiskSizeGB) * 100;
            $UsedDiskPercent = "{0:N0}" -f $UsedDiskPercent;

            $FormattedDisk = "Disk " + $DiskID.ToString() + " " + 
                $UsedDiskSizeGB.ToString() + "GB" + " / " + $DiskSizeGB.ToString() + "GB " + 
                "(" + $UsedDiskPercent.ToString() + "%" + ")";
            $FormattedDisks.Add($FormattedDisk);
        }
    }
    else 
    {
        $DiskID = (Get-CimInstance Win32_LogicalDisk).DeviceId;

        $FreeDiskSize = (Get-CimInstance Win32_LogicalDisk).FreeSpace
        $FreeDiskSizeGB = $FreeDiskSize / 1073741824;
        $FreeDiskSizeGB = "{0:N0}" -f $FreeDiskSizeGB -replace "\D+";

        $DiskSize = (Get-CimInstance Win32_LogicalDisk).Size;
        $DiskSizeGB = $DiskSize / 1073741824;
        $DiskSizeGB = "{0:N0}" -f $DiskSizeGB -replace "\D+";


        if ($DiskSize -gt 0) 
        {
            $FreeDiskPercent = ($FreeDiskSizeGB / $DiskSizeGB) * 100;
            $FreeDiskPercent = "{0:N0}" -f $FreeDiskPercent;

            $UsedDiskSizeGB = $DiskSizeGB - $FreeDiskSizeGB;
            $UsedDiskPercent = ($UsedDiskSizeGB / $DiskSizeGB) * 100;
            $UsedDiskPercent = "{0:N0}" -f $UsedDiskPercent;

            $FormattedDisk = "Disk " + $DiskID.ToString() + " " +
                $UsedDiskSizeGB.ToString() + "GB" + " / " + $DiskSizeGB.ToString() + "GB " +
                "(" + $UsedDiskPercent.ToString() + "%" + ")";
            $FormattedDisks.Add($FormattedDisk);
        } 
        else 
        {
            $FormattedDisk = "Disk " + $DiskID.ToString() + " Empty";
            $FormattedDisks.Add($FormattedDisk);
        }
    }

    return $FormattedDisks;
}
