#This is to load the XAML code that actually formats the forms page
#Shoutouts to Foxdeploy.com for the XAML loader
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework
$inputXML = @"
<Window x:Class="formsTest.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:formsTest"
        mc:Ignorable="d"
        Title="Garf Multi-Tool" Height="416" Width="470" Background="#FFFFE1C8">
    <Grid ScrollViewer.VerticalScrollBarVisibility="Disabled" ClipToBounds="True" Width="450">
        <Grid.RowDefinitions>
            <RowDefinition Height="63*"/>
            <RowDefinition Height="17*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition/>
        </Grid.ColumnDefinitions>
        <Label x:Name="lbltitle" Content="Garf Multi-Tool" HorizontalAlignment="Center" VerticalAlignment="Top" FontFamily="Microsoft YaHei UI" FontSize="20" FontWeight="Bold"/>
        <ComboBox x:Name="ddlCat" HorizontalAlignment="Center" Margin="0,38,0,0" VerticalAlignment="Top" Width="146" MaxDropDownHeight="200"/>
        <ComboBox x:Name="ddlScript" HorizontalAlignment="Center" Margin="0,78,0,0" VerticalAlignment="Top" Width="175" MaxDropDownHeight="200"/>
        <Button x:Name="btnRun" Content="Run" HorizontalAlignment="Left" Margin="323,110,0,0" VerticalAlignment="Top" FontFamily="Microsoft YaHei" FontWeight="Bold" Width="75" RenderTransformOrigin="0.551,1.125"/>
        <Label x:Name="lblCat" Content="Category:" HorizontalAlignment="Left" Margin="50,35,0,0" VerticalAlignment="Top" FontFamily="Microsoft YaHei UI" FontSize="14"/>
        <Label x:Name="lblScript" Content="Script:" HorizontalAlignment="Left" Margin="50,72,0,0" VerticalAlignment="Top" FontFamily="Microsoft YaHei UI" FontSize="14"/>
        <TextBox x:Name="lbOutput" HorizontalAlignment="Center" Margin="0,143,0,0" TextWrapping="Wrap" Text="Output" VerticalAlignment="Top" Width="374" Height="220" Grid.RowSpan="2" IsReadOnly="True"/>
        <TextBox x:Name="tbParams" HorizontalAlignment="Left"  Margin="76,110,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="232" IsManipulationEnabled="True" ToolTip="Put a space between each paramater. If function doesn't need paramters this is ignored."/>
        <Label x:Name="lblParams" Content="Params:" HorizontalAlignment="Left" Margin="23,107,0,0" VerticalAlignment="Top"/>
    </Grid>
</Window>
"@
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try { $Form = [Windows.Markup.XamlReader]::Load( $reader ) }
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    write-host $error[0].Exception.Message -ForegroundColor Red
    if ($error[0].Exception.Message -like "*button*") {
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
    }
}
catch {
    #if it broke some other way 
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | % { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) }
 

if ($global:ReadmeDisplay -ne $true) { Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*

 
#===========================================================================
# End of XAML loader.
# Initialize-Categories reads the function names, divides the categories into keys and script names into values on a hashtable
# Update-DDL just updates the script dropdown list whenever category changes
# Display-Output displays whatever is outputted from your function if needed. HOWEVER
# you need to copy paste the following lines
#===========================================================================

$script:categoryExtensions = @{}
#Get the script names and categories from the name (Yeah ChatGPT helped)
function Initialize-Categories {
    $pattern = "pwsh(.+?)\.(.+)"
    $currentFunctions = Get-ChildItem function: | Where-Object { $_.Name -like 'pwsh*' }

    foreach ($function in $currentFunctions) {
        if ($function -match $pattern) {
            $category = $matches[1] 
            $scriptName = $matches[2]
            if ($script:categoryExtensions.ContainsKey($category)) {
                $script:categoryExtensions[$category] += $scriptName
            }
            else {
                $script:categoryExtensions[$category] = @($scriptName)
            }
        }
    }

    foreach ($key in $script:categoryExtensions.Keys) {
        $WPFddlCat.AddText($key)
    }

    if ($WPFddlCat.Items.Count -gt 0) {
        $WPFddlCat.SelectedItem = $WPFddlCat.Items[0]
    }

    $WPFddlCat.Add_SelectionChanged({
            Update-DDL $WPFddlCat.SelectedItem
        })

    Update-DDL $WPFddlCat.SelectedItem
}

function Update-DDL($selectedCategory) {
    $WPFddlScript.Items.Clear()
    $scripts = $script:categoryExtensions[$selectedCategory]
    foreach ($script in $scripts) {
        $WPFddlScript.AddText($script)
    }
    if ($WPFddlScript.Items.Count -gt 0) {
        $WPFddlScript.SelectedItem = $WPFddlScript.Items[0]
    }
}

function Display-Output {
    param($Output)
    $WPFlbOutput.Items.Add($Output)
}
#Check for AD module
$ADInstalled = $null
function checkForAD {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $ADInstalled = $true
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        $ADInstalled = $false
    }
}
#===========================================================================
# PUT YOUR SCRIPTS INTO FUNCTIONS HERE
# THEY MUST START WITH "pwsh" followed by the category name, then a period
#
#  There are some examples below
#===========================================================================


# Informational popup box
function pwshGeneral.Show-InformationDialog {
    param (
        [Parameter(mandatory = $true)]
        [string]$Message
    )
    
    [System.Windows.MessageBox]::Show($Message, "Information", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
}

function pwshGeneral.Get-UptimeInDays {
    # Get the uptime using Get-Uptime cmdlet
    $uptime = Get-Uptime

    # Convert uptime to days and output
    $days = [math]::Round($uptime.TotalDays, 2)
    return $days
}
#Get DHCP server info
function pwshGeneral.Get-DHCPInfo { return netsh dhcp server show mibinfo }
#Querys sessions, removes extra spaces so it fits in the output
function pwshGeneral.Get-AllSessions { return quser | ForEach-Object { $_ -replace '\s+', ' ' } }

#Find a file (Yeah it lags a bit if you have a lot of files)
function pwshGeneral.Find-MyFile {
    param(
        [string]$rootPath = "C:\",
        [string]$fileName = "garf.txt"
    )
    $ErrorActionPreference = 'SilentlyContinue' 
    $foundFiles = Get-ChildItem -Path $rootPath -Filter $fileName -Recurse -ErrorAction SilentlyContinue -File
    foreach ($file in $foundFiles) {
        Write-Output "Found it! $($file.FullName)"
    }
    if (!$foundFiles) {
        Write-Output "No file named '$fileName' found starting from $rootPath."
    }
}

function pwshAD.Disable-ADAccount {
    param(
        [Parameter(mandatory = $true)]
        [string]$username
    )
    try {
        Disable-ADAccount -Identity $username        
    }
    catch {
        Write-Output "Error: Make sure you put a username in the params!"
    }
}


#===========================================================================
# Final touches
#===========================================================================
Initialize-Categories
$WPFBtnRun.Add_Click({
        #Button delay
        $WPFBtnRun.IsEnabled = $false  
        Start-Sleep -Seconds 0.5  
        $WPFBtnRun.IsEnabled = $true 

        $WPFlbOutput.Clear()

        if ($WPFddlCat.SelectedItem -eq "AD") {
            checkForAD
            if (-not $ADInstalled) {
                $WPFlbOutput.AppendText("AD module couldn't install!`r`n")
                return
            }
        }
        #Get the function
        $selectedFunctionName = "pwsh{0}.{1}" -f $WPFddlCat.SelectedItem, $WPFddlScript.SelectedItem
        $functionInfo = Get-Command $selectedFunctionName -ErrorAction SilentlyContinue

        if ($functionInfo) {
            $params = @{}
            $rawParams = $WPFtbParams.Text.Trim() -split ' '
            foreach ($param in $rawParams) {
                if ($param -match '^(\w+)=(.*)') {
                    $params[$matches[1]] = $matches[2]
                }
            }

            # Check for missing mandatory parameters
            foreach ($paramMetaData in $functionInfo.Parameters.GetEnumerator()) {
                $param = $paramMetaData.Key
                $isMandatory = $paramMetaData.Value.Attributes | Where-Object { $_.TypeId.Name -eq "ParameterAttribute" -and $_.Mandatory }
                if ($isMandatory -and -not $params.ContainsKey($param)) {
                    $WPFlbOutput.AppendText("Mandatory parameter '$param' is missing for the function '$selectedFunctionName'. Please provide it in the format paramName=paramValue.`r`n")
                    return
                }
            }

            try {
                $output = & $selectedFunctionName @params
                if ($output -is [System.Collections.IEnumerable] -and $output -isnot [string]) {
                    foreach ($item in $output) {
                        $WPFlbOutput.AppendText("$item`r`n")
                    }
                }
                else {
                    $WPFlbOutput.AppendText("$output`r`n")
                }
            }
            catch {
                $WPFlbOutput.AppendText("Error executing function with parameters: $_`r`n")
            }
        }
        else {
            $WPFlbOutput.AppendText("Function '$selectedFunctionName' does not exist.`r`n")
        }
    })
$Form.ShowDialog() | out-null