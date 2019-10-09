<# 

.DESCRIPTION 
 Using the created DSC Configuration searches for the data and imports the data into a SQL Database.
 The Database tables need to exists already see SQLTableCreation.txt for the SQL commands to create the needed tables
 Note:  if the Table name changes you will have to modify 4 lines of code to change the name of hte SQL table
        Current = $cmd.CommandText = "INSERT INTO Table_1
        Current = $cmd.CommandText = "INSERT INTO Table_2
        Current = $cmd.CommandText = "INSERT INTO Table_3
        Current = $cmd.CommandText = "INSERT INTO Table_4
        New     = $cmd.CommandText = "INSERT INTO <tablename>
#> 


$dscFile = 'C:\Temp\15\PSDesiredStateConfiguration.DSC.ps1'
$content = Get-Content $DscFile
$SQLServer = 'SCCM'
$SQLDBName = 'Test_Dataset'

ForEach ($line in $content)
{
    if (($line -match "\s\s\sNode\s"))
    {
        $hostname = $line.Split("Node ")[-1]
    }
    elseif (($line -match "\s\s\sService\s")) #-and ($line.Length -eq '52'))
    {
        $sd = Get-ServiceData -Hostname $hostname -Count $line.ReadCount -Datafile $dscFile
        $data = @{}
        ForEach ($property in $sd.psobject.Properties.name)
        {
            $data[$property] = $sd.$property
        }
        Write-SQLData -SQL "SCCM" -SQLDB "Test_Dataset" -Data $data -SD
    }
    elseif (($line -match "\s\s\sRegistry\s")) #-and ($line.Length -eq '52'))
    {
        $rd = Get-RegistryData -Hostname $hostname -Count $line.ReadCount -Datafile $dscFile
        $data = @{}
        ForEach ($property in $rd.psobject.Properties.name)
        {
            $data[$property] = $rd.$property
        }
        Write-SQLData -SQL "SCCM" -SQLDB "Test_Dataset" -Data $data -RD
    }
    elseif (($line -match "\s\s\sFile\s")) #-and ($line.Length -eq '52'))
    {
        $fd = Get-FileData -Hostname $hostname -Count $line.ReadCount -Datafile $dscFile
        $data = @{}
        ForEach ($property in $fd.psobject.Properties.name)
        {
            $data[$property] = $fd.$property
        }
        Write-SQLData -SQL "SCCM" -SQLDB "Test_Dataset" -Data $data -FD
    }
    elseif (($line -match "\s\s\sWindowsFeature\s"))
    {
        $wd = Get-WFData -Hostname $hostname -Count $line.ReadCount -Datafile $dscFile
        $data = @{}
        ForEach ($property in $wd.psobject.Properties.name)
        {
            $data[$property] = $wd.$property
        }
        Write-SQLData -SQL "SCCM" -SQLDB "Test_Dataset" -Data $data -WD
    }
}

#Getting Registry Data
function Get-RegistryData
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Hostname,
        
        [Parameter(Mandatory = $true)]
        [Int32]
        $Count,
        
        [Parameter(Mandatory = $true)]
        [String]
        $Datafile
    )
    
    if ($count)
    {
        $n = $count
        $a = (Get-Content $Datafile)[($n+1),($n+2),($n+3),($n+4),($n+5)]
        $registry = New-Object System.Collections.ArrayList
        $ro = New-Object psobject
        $rom = Add-Member -InputObject $ro -MemberType NoteProperty -Name ComputerName -Value $Hostname -PassThru
        $rom = Add-Member -InputObject $ro -MemberType NoteProperty -Name SettingType -Value Registry -PassThru

        forEach($line in $a)
        {
            $splitLine = $line.Split('=')
            if ($splitLine[0] -match 'ValueName')
            {
                $rom = Add-Member -InputObject $ro -MemberType NoteProperty -Name ValueName -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'Key')
            {
                $rom = Add-Member -InputObject $ro -MemberType NoteProperty -Name Key -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'Ensure')
            {
                $rom = Add-Member -InputObject $ro -MemberType NoteProperty -Name Ensure -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'ValueType')
            {
                $rom = Add-Member -InputObject $ro -MemberType NoteProperty -Name ValueType -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'ValueData')
            {
                $rom = Add-Member -InputObject $ro -MemberType NoteProperty -Name ValueData -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
        }

        $registry.Add($rom) |Out-Null
        $registry
    }
}

#Getting Services Data
function Get-ServiceData
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Hostname,
        
        [Parameter(Mandatory = $true)]
        [Int32]
        $Count,
        
        [Parameter(Mandatory = $true)]
        [String]
        $Datafile
    )
    
    if ($count)
    {
        $n = $count
        $a = (Get-Content $Datafile)[($n+1),($n+2),($n+3),($n+4),($n+5),($n+6),($n+7),($n+8)]
        $services = New-Object System.Collections.ArrayList
        $so = New-Object psobject
        $som = Add-Member -InputObject $so -MemberType NoteProperty -Name ComputerName -Value $Hostname -PassThru
        $som = Add-Member -InputObject $so -MemberType NoteProperty -Name SettingType -Value Services -PassThru

        forEach($line in $a)
        {
            $splitLine = $line.Split('=')
            if ($splitLine[0] -match 'State')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name State -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'Dependencies')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name Dependencies -Value $SplitLine[1].TrimEnd(';') -PassThru
            }
            elseif ($splitLine[0] -match 'DisplayName')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name DisplayName -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'Name')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name Name -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'Description')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name Description -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'BuiltInAccount')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name BuiltInAccount -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'Path')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name Path -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'StartUpType')
            {
                $som = Add-Member -InputObject $so -MemberType NoteProperty -Name StartUpType -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
        }

        $services.Add($som) |Out-Null
        $services
    }
}

#Getting File\folder Data
function Get-FileData
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Hostname,
        
        [Parameter(Mandatory = $true)]
        [Int32]
        $Count,
        
        [Parameter(Mandatory = $true)]
        [String]
        $Datafile
    )
    
    if ($count)
    {
        $n = $count
        $a = (Get-Content $Datafile)[($n+1),($n+2),($n+3),($n+4),($n+5)]
        $files = New-Object System.Collections.ArrayList
        $fo = New-Object psobject
        $fom = Add-Member -InputObject $fo -MemberType NoteProperty -Name ComputerName -Value $Hostname -PassThru
        $fom = Add-Member -InputObject $fo -MemberType NoteProperty -Name SettingType -Value "File\Foler" -PassThru

        forEach($line in $a)
        {
            $splitLine = $line.Split('=')
            if ($splitLine[0] -match 'DestinationPath')
            {
                $fom = Add-Member -InputObject $fo -MemberType NoteProperty -Name DestinationPath -Value $SplitLine[1].TrimStart(" '").TrimEnd("';") -PassThru
            }
            elseif ($splitLine[0] -match 'Type')
            {
                $fom = Add-Member -InputObject $fo -MemberType NoteProperty -Name Type -Value $SplitLine[1].TrimStart(" '").TrimEnd("';") -PassThru
            }
            elseif ($splitLine[0] -match 'SourcePath')
            {
                $fom = Add-Member -InputObject $fo -MemberType NoteProperty -Name SourcePath -Value $SplitLine[1].TrimStart(" '").TrimEnd("';") -PassThru
            }
            elseif ($splitLine[0] -match 'Ensure')
            {
                $fom = Add-Member -InputObject $fo -MemberType NoteProperty -Name Ensure -Value $SplitLine[1].TrimStart(" '").TrimEnd("';") -PassThru
            }
        }

        $files.Add($fom) |Out-Null
        $files
    }
}

#Getting Windows Features Data
function Get-WFData
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Hostname,
        
        [Parameter(Mandatory = $true)]
        [Int32]
        $Count,
        
        [Parameter(Mandatory = $true)]
        [String]
        $Datafile
    )
    
    if ($count)
    {
        $n = $count
        $a = (Get-Content $Datafile)[($n+1),($n+2),($n+3),($n+4),($n+5)]
        $features = New-Object System.Collections.ArrayList
        $wo = New-Object psobject
        $wom = Add-Member -InputObject $wo -MemberType NoteProperty -Name ComputerName -Value $Hostname -PassThru
        $wom = Add-Member -InputObject $wo -MemberType NoteProperty -Name SettingType -Value "Features" -PassThru

        forEach($line in $a)
        {
            $splitLine = $line.Split('=')
            if ($splitLine[0] -match 'IncludeAllSubFeature')
            {
                $wom = Add-Member -InputObject $wo -MemberType NoteProperty -Name IncludeAllSubFeature -Value $SplitLine[1].TrimStart(" ").TrimEnd(";") -PassThru
            }
            elseif ($splitLine[0] -match "\s\sName\s")
            {
                $wom = Add-Member -InputObject $wo -MemberType NoteProperty -Name Name -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'DisplayName')
            {
                $wom = Add-Member -InputObject $wo -MemberType NoteProperty -Name DisplayName -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
            elseif ($splitLine[0] -match 'Ensure')
            {
                $wom = Add-Member -InputObject $wo -MemberType NoteProperty -Name Ensure -Value $SplitLine[1].TrimStart(' "').TrimEnd('";') -PassThru
            }
        }

        $features.Add($wom) |Out-Null
        $features
    }
}

#SQL Data Import

function Write-SQLData
{
        Param
    (
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQL,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLDB,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $Data,

        [Switch]$RD,

        [Switch]$FD,

        [Switch]$SD,

        [Switch]$WD
    )


    $SQLServer = $SQL
    $SQLDBName = $SQLDB
    $timeformat='MM-dd-yyyy hh:mm:ss tt'
    $time2 = (Get-Date).ToString($timeformat)
 
    #Connects to Database
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.connection = $connection

    if ($RD)
    {
        #Inserts information to the DB
        $cmd.CommandText = "INSERT INTO Table_1 (Time,ComputerName,SettingType,KeyName,ValueType,ValueData,Ensure)
        VALUES('{0}','{1}','{2}','{3}','{4}','{5}','{6}')" -f
        $time2,$Data.ComputerName,$Data.SettingType,"$($Data.Key)\$($Data.ValueName)",$Data.ValueType,$Data.ValueData,$Data.Ensure
        $cmd.ExecuteNonQuery() |Out-Null
        write-host "Running registry import"
    }
    elseif ($FD)
    {
        $cmd.CommandText = "INSERT INTO Table_2 (Time,ComputerName,Type,DestinationPath,SourcePath,Ensure)
        VALUES('{0}','{1}','{2}','{3}','{4}','{5}')" -f
        $time2,$Data.ComputerName,$Data.Type,$Data.DestinationPath,$Data.SourcePath,$Data.Ensure
        $cmd.ExecuteNonQuery() |Out-Null
        write-host "Running file\folder import"
    }
    elseif ($SD)
    {
        #Inserts information to the DB
        $cmd.CommandText = "INSERT INTO Table_3 (Time,ComputerName,SettingType,DisplayName,Name,Description,Path,State,StartUpType,Dependencies,BuiltInAccount)
        VALUES('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}')" -f
        $time2,$Data.ComputerName,$Data.SettingType,$Data.DisplayName,$Data.Name,$Data.Description,$Data.Path,$Data.State,$Data.StartUpType,$Data.Dependencies,$Data.BuiltInAccount
        $cmd.ExecuteNonQuery() |Out-Null
        write-host "Running Services import"
    }
    elseif ($WD)
    {
        $cmd.CommandText = "INSERT INTO Table_4 (Time,ComputerName,SettingType,DisplayName,Name,IncludeAllSubFeatures,Ensure)
        VALUES('{0}','{1}','{2}','{3}','{4}','{5}','{6}')" -f
        $time2,$Data.ComputerName,$Data.SettingType,$Data.DisplayName,$Data.Name,$Data.IncludeAllSubFeature,$Data.Ensure
        $cmd.ExecuteNonQuery() |Out-Null
        write-host "Running Windows Features import"
    }
    else
    {
        write-host "Not Running"
    }

    #Closes Connection
    $connection.Close()
}
