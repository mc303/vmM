<#

	Context Menu HowTO https://learn-powershell.net/2014/07/24/building-a-clipboard-history-viewer-using-powershell/
#>

$inputXML = @"

"@
	$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
	$inputXML = Get-Content "$(Split-Path -Parent $PSScriptRoot)\gui-vmM\MainWindow.xaml"

	$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
	[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 
	[xml]$XAML = $inputXML
	#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
	try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
	catch [System.Management.Automation.MethodInvocationException] {
		Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
		write-host $error[0].Exception.Message -ForegroundColor Red
		if ($error[0].Exception.Message -like "*button*"){
			write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"}
	}
	catch{#if it broke some other way<img draggable="false" class="emoji" alt="??" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
		Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
    }
	
	#===========================================================================
	# Store Form Objects In PowerShell
	#===========================================================================
 
	$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
	Function Get-FormVariables{
		if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
		write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
		get-variable WPF*
	}












	$Form.ShowDialog() | out-null