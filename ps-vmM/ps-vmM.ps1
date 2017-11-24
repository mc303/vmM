<#

	Context Menu HowTO https://learn-powershell.net/2014/07/24/building-a-clipboard-history-viewer-using-powershell/
	Clone Info http://www.vmdev.info/?p=202

	param input
	https://learn-powershell.net/2014/02/04/using-powershell-parameter-validation-to-make-your-day-easier/
#>

$inputXML = @"

"@
	$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
	$inputXML = Get-Content "$(Split-Path -Parent $PSScriptRoot)\gui-vmM\gui-vmM.xaml"

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

	Set-Variable -Name "ParantVMSnapshotName" -Scope Global -Option AllScope -Value 0

	Set-Variable -Name "ParantVMPrefix" -Scope Global -Option AllScope -Value 0

	$Global:ParantVMPrefix = "base-parentvm-" 
	$Global:ParantVMSnapshotName = 'LinkedCloneFromThisSnapshot'

	#vSphere ssl Thumbprint
	$thumbprintSSL = ""

	$WPFcmdSnapshotCreate.IsEnabled = $false
	$WPFcmdOpenConsole.IsEnabled = $false
	$WPFcmdPowerOn.IsEnabled = $false
	$WPFcmdPowerOff.IsEnabled = $false
	$WPFcmdReset.IsEnabled = $false
	$WPFcmdShutdownGuest.IsEnabled = $false
	$WPFcmdRestartGuest.IsEnabled = $false

	$WPFcmdDisconnect.IsEnabled = $false

	$WPFlblVCUsername.IsEnabled = $false
	$WPFlblVCPasswd.IsEnabled = $false
	$WPFtxtVCUsername.IsEnabled = $false
	$WPFtxtVCPasswd.IsEnabled = $false



	#Set tabindex for the tab1 controls 
	$WPFtxtvSphereConnection.TabIndex = 0
	$WPFchkbUseVCCredentials.TabIndex = 1
	$WPFtxtVCUsername.TabIndex = 2
	$WPFtxtVCPasswd.TabIndex = 3
	$WPFcmdConnect.TabIndex = 4
	
	# Create DataSet
	$dtVMList = New-Object System.Data.DataTable("VMList")
	$dtSnapshotList = New-Object System.Data.DataTable("SnapshotList")
	$dtVMParentVM  = New-Object System.Data.DataTable("VMParentVM")
	$dtVMSnapshots  = New-Object System.Data.DataTable("VMSnapshots")
	$dtVMFolders = New-Object System.Data.DataTable("VMFolders")
	$dtVMDatastores = New-Object System.Data.DataTable("VMDatastores")

	$dvVMlist	= New-Object System.Data.DataView($dtVMList)
	$dvSnapshotList	= New-Object System.Data.DataView($dtSnapshotList)
	$dvVMParentVM	= New-Object System.Data.DataView($dtVMParentVM)
	$dvVMSnapshots	= New-Object System.Data.DataView($dtVMSnapshots)
	$dvVMFolders	= New-Object System.Data.DataView($dtVMFolders)
	$dvVMDatastores	= New-Object System.Data.DataView($dtVMDatastores)

	$colsVMList = @("GuestVM","GuestVMPowerState","VMHost","MoRef","GuestVMID")
	$colsSnapshotList = @("IsCurrent","SnapshotName","DateCreated","ParentSnapshot","SnapshotID","ParentSnapshotID")
	$colsVMParentVM	= @("GuestVM","GuestVMID")
	$colsVMSnapshots = @("Snapshot","SnapshotID")
	$colsVMFolders = @("Folder","FolderID")
	$colsVMDatastores = @("Datastore","DatastoreID")

	[System.Collections.Generic.List[String]]$deployedLinkedCloneVMs = @()

	# Schema (columns)
	foreach ($colVMList in $colsVMList) {
		$dtVMlist.Columns.Add($colVMList) | Out-Null
	}

	foreach ($colSnapshotList in $colsSnapshotList) {
		$dtSnapshotList.Columns.Add($colSnapshotList) | Out-Null
	}

	foreach ($colVMParentVM in $colsVMParentVM) {
		$dtVMParentVM.Columns.Add($colVMParentVM) | Out-Null
	}

	foreach ($colVMSnapshots in $colsVMSnapshots) {
		$dtVMSnapshots.Columns.Add($colVMSnapshots) | Out-Null
	}

	foreach ($colVMFolders in $colsVMFolders) {
		$dtVMFolders.Columns.Add($colVMFolders) | Out-Null
	}
	
	foreach ($colVMDatastores in $colsVMDatastores) {
		$dtVMDatastores.Columns.Add($colVMDatastores) | Out-Null
	}
			
	$WPFlvVMs.ItemsSource = $dvVMlist
	$WPFlvSnapshotList.ItemsSource = $dvSnapshotList 

	$WPFcbbParentVM.ItemsSource = $dvVMParentVM
	$WPFcbbParentVM.DisplayMemberPath = 'GuestVM'
	$WPFcbbParentVM.SelectedValuePath = 'GuestVMID'

	$WPFcbbVMFolders.ItemsSource = $dvVMFolders
	$WPFcbbVMFolders.DisplayMemberPath = 'Folder'
	$WPFcbbVMFolders.SelectedValuePath = 'FolderID'

	$WPFcbbVMDatastores.ItemsSource = $dvVMDatastores
	$WPFcbbVMDatastores.DisplayMemberPath = 'Datastore'
	$WPFcbbVMDatastores.SelectedValuePath = 'DatastoreID'



	#Disables Tabs 
	($WPFtabControl.Items[1]).IsEnabled = $false 

	function loadSettingsXML{
		
		if (Test-Path -Path "$PSScriptRoot\settings.xml"){
			[xml]$ConfigSettings = Get-Content "$PSScriptRoot\settings.xml"

			if($ConfigSettings.settings.main.vsphereconnection){$WPFtxtvSphereConnection.Text = $ConfigSettings.settings.main.vsphereconnection}
			if($ConfigSettings.settings.main.vcusername){$WPFtxtVCUsername.Text = $ConfigSettings.settings.main.vcusername}
			if($ConfigSettings.settings.main.vcpasswd){$WPFtxtVCPasswd.Password = $ConfigSettings.settings.main.vcpasswd}

			$WPFlblHostnameCount.content = """=$($WPFcbbVMHostnameNumbering.Text.Length + $WPFtxtVMHostnamePrefix.Text.Length)"" NetBIOS Name max 15 characters"
			$WPFtxtVMHostnamePrefix.MaxLength = 15 - $WPFcbbVMHostnameNumbering.Text.Length
		}
	}

	function Get-FolderPath {

		param (
		[parameter(valuefrompipeline = $true,
		position = 0,
		HelpMessage = "Enter a folder")]
		[VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl[]]$Folder,
		[switch]$ShowHidden = $false
		)

		begin {
		$excludedNames = "Datacenters", "vm", "host"
		$hash = @{ };
		}

		process {
			$Folder | %{
			$fld = $_.Extensiondata
			$fldColor = "yellow"
			if ($fld.ChildType -contains "VirtualMachine") {
			$fldColor = "blue"
			}
			$path = $fld.Name
			while ($fld.Parent) {
				$fld = Get-View $fld.Parent
				if ((!$ShowHidden -and $excludedNames -notcontains $fld.Name) -or $ShowHidden) {
				$path = $fld.Name + "/" + $path
				}
				}
				$row = "" | Select Name, Path, Color, Type, Id, ParentId
				$row.Name = $_.Name
				$row.Path = $path
				$row.Color = $fldColor
				$row.Type = $_.Type
				$row.Id = $_.Id
				$row.ParentId = $_.ParentId
				$hash.Add($_.Id,$_.Name)
				$row
			}
		}
	}

	function addItemToVMSlist(){
		param($GuestVM,
			  $GuestVMPowerState,
			  $VMHost,
			  $MoRef,
			  $GuestVMID
		)

		$dtVMlist.Rows.Add("$GuestVM","$GuestVMPowerState","$VMHost","$MoRef","$GuestVMID")
	}

	function updateItemInVMSlist{
		param(
			$ItemIndex,
			$GuestVMPowerState,
			$VMHost
		)

		$dtVMlist.Rows[$ItemIndex].GuestVMPowerState = $GuestVMPowerState
		$dtVMlist.Rows[$ItemIndex].VMHost = $VMHost
	}

	function addItemToVMParentVM{
		param($GuestVM,
			  $GuestVMID
		)
		$dtVMParentVM.Rows.Add("$GuestVM","$GuestVMID")
	}

	function addItemToVMSnapshotDB {
		param($Snapshot,
			  $SnapshotID
		)

		$dtVMSnapshots.Rows.Add("$Snapshot","$SnapshotID")
	}

	function addItemToVMFolders{
		param($Folder,
			  $FolderID
		)
		$dtVMFolders.Rows.Add("$Folder","$FolderID")
	}

	function addItemToVMDatastores{
		param($Datastore,
			  $DatastoreID
		)
		$dtVMDatastores.Rows.Add("$Datastore","$DatastoreID")
	}


	function updatePowerStateGuestVM(){
		param (
			$ItemIndex,
			$VMname
		)
		$_powerstate = Get-VM -Name $VMname | Sort-Object name | % {
			updateItemInVMSlist -ItemIndex $ItemIndex -GuestVMPowerState $_.PowerState -VMHost $_.VMHost
		}
	}	

	function getVMSInventory(){
		param (
			$ClearDataSet=$false
		)

		if($ClearDataSet){
			$dtVMList.Clear() | Out-Null
		}	
		
		Get-VM | Sort-Object name | % {
			addItemToVMSlist -GuestVM $_.name -GuestVMPowerState $_.PowerState -VMHost $_.VMHost -MoRef $_.ExtensionData.MoRef.Value -GuestVMID $_.Id
			
		} | Out-Null
	}

	function createSnapshotList(){
		Param(
			$VMname,
			$ClearDataSet=$false
		)
		if($ClearDataSet){
			$dtSnapshotList.Clear() | Out-Null
		}

		$_snapshot = Get-VM -Name $vmname | Get-Snapshot -ErrorAction SilentlyContinue #| Sort-Object -Descending
		$_snapshot | % {
			addItemToSnapshotList -IsCurrent $_.IsCurrent.ToString() -SnapshotName $_.Name -DateCreated $_.Created -ParentSnapshot $_.ParentSnapshot -SnapshotID $_.Id -ParentSnapshotID $_.ParentSnapshotId
		} -Confirm:$false | Out-Null
	}

	function newSnapshot(){
		param(
			$vmname,
			$newSnaphsotName
		)
		
		Get-VM -Name $vmname | New-Snapshot -Name "$newSnaphsotName" -Confirm:$false | Out-Null
	}

	function deleteSelectedSnapshot(){
		param (
			$ItemIndex,
			$vmname
		)

		Get-Snapshot -VM $vmname -Id $dtSnapshotList.Rows[$ItemIndex].SnapshotID  | Remove-Snapshot -Confirm:$false | Out-Null

	}

	function deleteSelectedSnapshotChain(){
		param (
			$ItemIndex,
			$vmname
		)

		Get-Snapshot -VM $vmname -Id $dtSnapshotList.Rows[$ItemIndex].SnapshotID | Remove-Snapshot -RemoveChildren:$true -Confirm:$false | Out-Null
	}

	function deleteAllSnapshots(){
		param (
			$vmname
		)

		Get-VM -Name $vmname | Get-Snapshot | Remove-Snapshot -RemoveChildren:$false -confirm:$false | Out-Null
	}

	function revertToSelectedSnapshot(){
		param (
			$ItemIndex,
			$vmname
		)
		
		$_revertSnapshot = Get-Snapshot -VM $vmname -Id $dtSnapshotList.Rows[$ItemIndex].SnapshotID 
		Set-VM -VM $vmname -Snapshot $_revertSnapshot -Confirm:$false | Out-Nul
	}

	function getSnapshotsFromVM(){
		param(
			$MoRef
		)

		$dtVMSnapshots.Clear()

		Get-VM -ID $MoRef | Get-Snapshot | Sort-Object Name -Descending | % {
			addItemToVMSnapshotDB -Snapshot $_.Name -SnapshotID $_.Id
		} 

		if($dtVMSnapshots.Rows.Count -gt 0){$WPFcbbParentVMSnapshot.SelectedIndex = 0}
	}

	#getParentVMToComboBox

	function enableButtonOnPoweredOff(){
		$WPFcmdOpenConsole.IsEnabled = $True
		$WPFcmdPowerOn.IsEnabled = $True
		$WPFcmdPowerOff.IsEnabled = $false
		$WPFcmdReset.IsEnabled = $false
		$WPFcmdShutdownGuest.IsEnabled = $false
		$WPFcmdRestartGuest.IsEnabled = $false

		$WPFcmdSnapshotCreate.IsEnabled = $true
	}

	function enableButtonOnPoweredOn(){
		$WPFcmdOpenConsole.IsEnabled = $True
		$WPFcmdPowerOn.IsEnabled = $false
		$WPFcmdPowerOff.IsEnabled = $True
		$WPFcmdReset.IsEnabled = $True
		$WPFcmdShutdownGuest.IsEnabled = $True
		$WPFcmdRestartGuest.IsEnabled = $True

		$WPFcmdSnapshotCreate.IsEnabled = $false
	}

	function enableButtonsOnPowerState(){
	
		param (
			$PowerState
		)

		if($PowerState -eq "PoweredOff"){
			enableButtonOnPoweredOff
		}else {
			enableButtonOnPoweredOn
		}
	}

	function deleteVMPermanently(){
        param(
            $vmname
        )

        $_lcvm = Get-VM -Name $vmname -ErrorAction SilentlyContinue
	
		if ($_lcvm){
			if ($_lcvm.PowerState -eq "PoweredOn"){
				Stop-VM -VM $vmname -Kill -Confirm:$false | Out-Null

			} 
			Remove-VM -VM $vmname -DeletePermanently -Confirm:$false | Out-Null
		}
    }

	function addGuestinfoToVM(){
		param(
			$VMname,
			$GuestinfoKey,
			$GuestinfoValue
		)
        
		Get-VM -Name $VMname | New-AdvancedSetting -Name $GuestinfoKey -Value $GuestinfoValue -Type VM -Force:$true -Confirm:$false | Out-Null
    }

	
	function ActionStartVM(){
		param(
			$VMname,
			[switch]$RunAsync=$false
		)
		if($RunAsync){
			Start-VM -VM $VMname -Confirm:$false -RunAsync | Out-Null
		} else {
			Start-VM -VM $VMname -Confirm:$false | Out-Null
		}
	}

	
	function ActionStopKillVM(){
		param(
			$VMname,
			[switch]$RunAsync=$false
		)

		if($RunAsync){
			Stop-VM -VM $VMname -Kill -Confirm:$false -RunAsync | Out-Null
		} else {
			Stop-VM -VM $VMname -Kill -Confirm:$false | Out-Null
		}
	}

	function ActionStopVM(){
		param(
			$VMname,
			[switch]$RunAsync=$false
		)
		if($RunAsync){
			Stop-VM -VM $VMname -Confirm:$false -RunAsync | Out-Null
		} else {
			Stop-VM -VM $VMname -Confirm:$false | Out-Null
		}
	}

	function ActionResetVM(){
		param(
			$VMname,
			[switch]$RunAsync=$false
		)

		if($RunAsync){
			Restart-VM -VM $VMname -RunAsync -Confirm:$false | Out-Null
		} else {
			Restart-VM -VM $VMname -Confirm:$false | Out-Null
		}
	}

	function ActionRefreshVMList(){
		if ($WPFlvVMs.items.Count -gt 0){
			$selectedVM = ($WPFlvVMs.SelectedItem).GuestVM
			getVMSInventory -ClearDataSet $true
			$selectedVMFromDataset = $dtVMList.Select("GuestVM='$selectedVM'")
			foreach($_item in $selectedVMFromDataset){
				$WPFlvVMs.SelectedIndex = $dtVMList.Rows.IndexOf($_item)
			}
		}
	}

	function actionMessageBox(){
		param(
			$MBMessage,
			$MBTitle,
			$MBButtons,
			$MBIcon
		)
		
		$msgBoxInput =  [System.Windows.MessageBox]::Show("$MBMessage","$MBTitle","$MBButtons","$MBIcon")
		
		switch  ($msgBoxInput) {
			'Yes' {
				return 'Yes'
			}
			'No' {
				return 'No'
			}
			'Cancel' {
				return 'Cancel'
			}
			'OK' {
				return 'OK'
			}
		}
	}
	

	function createFullCloneVMFromParentVM {
				param(
					$ParentVM,
					$VMname,
					$DestinationFolderID,
					$DestinationDatastoreID,
					$ParentBaseVMSnapshotID
				)

				#Write-Host "Creating Linked Clone VM $_vmname ..."
				$_LinkedCloneBaseSnapshot = Get-Snapshot -VM $ParentVM -Id $ParentBaseVMSnapshotID
				$_DestinationDatastore = Get-Datastore -ID $DestinationDatastoreID
				$_DestinationFolder = Get-Folder -ID $DestinationFolderID


				#Write-Host "New-VM -Name $_vmname -VM $ParentVM -Location $_DestinationFolder -Datastore $_DestinationDatastore -ResourcePool Resources -LinkedClone -ReferenceSnapshot $_LinkedCloneBaseSnapshot"
				$_createdLinkedCloneVM = New-VM `
											-Name $VMname `
											-VM $ParentVM `
											-Location $_DestinationFolder `
											-Datastore $_DestinationDatastore `
											-ResourcePool Resources `
										
	}

	function createFullCloneFromVM{
			param(
					$ParentVM,
					$VMname,
					$DestinationFolderID,
					$DestinationDatastoreID
				)

				$_DestinationDatastore = Get-Datastore -ID $DestinationDatastoreID
				$_DestinationFolder = Get-Folder -ID $DestinationFolderID

				$_createFullCloneFromVM = New-VM `
											-Name $VMname `
											-VM $ParentVM `
											-Location $_DestinationFolder `
											-Datastore $_DestinationDatastore `
											-ResourcePool Resources

	}

	function deployLinkedCloneVMs(){
		param(
			$ParentVM,
			$FullConeVM,
			[switch]$DeleteVMBeforeDeploy=$false,
			[switch]$StartVMAfterDeploy=$false,
			[switch]$LinkVMtoXenDesktop=$false,
			[switch]$NewADComputerAccount=$false,
			[switch]$CreatePooledVM=$false
		)

		[int]$_lc_vms = $WPFtxtVMSDeploy.Text 
		[int]$_lc_vdi_startnumber = $WPFtxtVMStartNumber.Text
		[string]$_lc_numbering = "{0:d$(($WPFcbbVMHostnameNumbering.SelectedIndex + 1))}"
		[string]$_lc_vmname_prefix = $WPFtxtVMHostnamePrefix.Text

		
		$_newguid = [guid]::NewGuid()
		$_parentVMName = "$($Global:ParantVMPrefix)$_newguid"

		$DeployedLinkedCloneVMs.Clear()

		# Create VMname list
		1..$_lc_vms | ForEach-Object {
			[string]$_vmnr = $_lc_numbering -f $_lc_vdi_startnumber
			$_vmname = "$($_lc_vmname_prefix)$_vmnr"
			
			#Add VMname to List(VMname)
			$deployedLinkedCloneVMs.Add($_vmname) 

			#Add +1 to VMname
			$_lc_vdi_startnumber += 1
		}

		if($CreatePooledVM){
			# First Delete all VMs
			foreach ($_newvm in $deployedLinkedCloneVMs){
				if($DeleteVMBeforeDeploy){	
					deleteVMPermanently -vmname $_newvm
				}
			}

			foreach ($_newvm in $deployedLinkedCloneVMs){	
				write-host "creating full clone $_newvm "
				createFullCloneFromVM `
					-ParentVM $ParentVM `
					-VMname $_newvm `
					-DestinationFolderID $WPFcbbVMFolders.SelectedValue `
					-DestinationDatastoreID $WPFcbbVMDatastores.SelectedValue 

				addGuestinfoToVM -VMname $_newvm -GuestinfoKey "guestinfo.hostname" -GuestinfoValue $_newvm 

				#Set memory and Memory Reservation
				Get-VM -Name $_newvm | Set-VM -MemoryGB $WPFcbbVMMemoryInGB.SelectedValue -Confirm:$false
				Get-VM -Name $_newvm | Get-VMResourceConfiguration | Set-VMResourceConfiguration -MemReservationGB $WPFcbbVMMemoryReservationInGB.SelectedValue -Confirm:$false
			}
		}

		if($NewADComputerAccount){
			foreach ($_newvm in $deployedLinkedCloneVMs){

				actionCreateNewADComputerAccountV2 `
					-ADComputerName $_newvm `
					-OU $WPFcbbADOU.SelectedValue `
					-DNSSuffix $WPFtxtADDNSSuffix.Text.Trim() `
					-DomainController $WPFtxtADDomainController.Text.Trim() `
					-ADCredentials:$WPFchkbADCredToCreateADComputer.IsChecked `
					-Username $WPFtxtADUsername.Text.Trim() `
					-Passwd $WPFtxtADPasswd.Password
			}

			#wait until de AD accounts are created
			waitUntilADComputerAccountsExists -ADComputerNames $deployedLinkedCloneVMs -WaitFor5SecCount 60
		}



		if($LinkVMtoXenDesktop){
			updateOrAddVMtoBrokerMachine `
				-AdminAddress $WPFtxtAdminServer.Text.Trim() `
				-XDHyp $WPFcbbXDHyp.Text.Trim() `
				-DeployedLinkedCloneVMs $deployedLinkedCloneVMs `
				-HypervisorConnectionUID $WPFcbbXenHypervisorConnection.SelectedValue `
				-DesktopDeliveryGroupUID  $WPFcbbXenDeliveryGroup.SelectedValue `
				-MachineCatalogUID $WPFcbbXenMachineCatalog.SelectedValue `
				-NetBIOSDomain $WPFtxtNetBIOSName.Text.trim() `
				-TurnOnMaintenanceMode:$WPFchkbXenTurnOnMaintenanceMode.IsChecked `
				-Tag $ParentVM			
		}

		if($StartVMAfterDeploy -and $CreatePooledVM){
			foreach ($_newvm in $deployedLinkedCloneVMs){
				ActionStartVM -VMname $_newvm -RunAsync $true
			}	
		}

		if($WPFchkbPurgeKerberos.IsChecked){
			executeKlist
		}

		ActionRefreshVMList
		
	}

	function credentialsVC{
		$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @("$($WPFtxtVCUsername.Text)",$WPFtxtVCPasswd.SecurePassword)
		return $credentials
	}

	function connectVIServer(){
		param (
			[switch]$UseADCredentials,
			$vSphereConnection

		)
	
		#Load VMWare PowerCLI try connection to server
		try{
			if (!(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue)){

				$moduleList = @(
					"VMware.VimAutomation.Core",						
					"VMware.VumAutomation"
				)
				Import-Module -Name $moduleList -ErrorAction Stop
			}
			#Connecteer met de server srvvc01
			DisConnect-VIServer -Force -ErrorAction SilentlyContinue -Confirm:$false | Out-Null
			if ($UseADCredentials){
				$credentials = credentialsVC
				write-host "VC"
			} else {
				$credentials = credentialsAD
				write-host "AD"
			}

			Connect-VIServer -Server $vSphereConnection -Credential $credentials -ErrorAction Stop | Out-Null
				
			$VC = $true
		} catch [Exception]{
	
				#[System.Exception]
				<#
					Error Message: 3-5-2017 15:26:02	Connect-VIServer		Network connectivity error occured. Please verify that the network address and port are correct.
					ObjectNotFound: (:) [Connect-VIServer], ViServerConnectionException
					Error Message: 3-5-2017 15:24:49	Connect-VIServer		Cannot complete login due to an incorrect user name or password.	
					NotSpecified: (:) [Connect-VIServer], InvalidLogin
					Error handeling URL https://vwiki.co.uk/Exceptions_and_Error_Handling_(PowerShell)
				#>
				switch ($_.CategoryInfo.Reason){
					"ViServerConnectionException"{
						#Network connectivity error occured. Please verify that the network address and port are correct.	
						$_errmsg = "Network connectivity error occured.`r`nPlease verify that the network address and port are correct."
						actionMessageBox -MBMessage $_errmsg -MBTitle "ViServerConnectionException" -MBButtons "OK" -MBIcon "Error"

					}
					"InvalidLogin"{
						#Cannot complete login due to an incorrect user name or password.
						$_errmsg = "Cannot complete login due to an`r`nincorrect user name or password."
						actionMessageBox -MBMessage $_errmsg -MBTitle "InvalidLogin" -MBButtons "OK" -MBIcon "Error"

					}
					
				}

				$VC = $false
			}

			if($VC){
				Write-Host "$VC"
				$WPFcmdConnect.IsEnabled = $False
				$WPFcmdDisconnect.IsEnabled = $true
				$WPFcmdConnect.Content = "Connected"
				$WPFcmdDisconnect.Visibility = [System.Windows.Visibility]::Visible

				#Enable Tabs 2 and 3
				($WPFtabControl.Items[1]).IsEnabled = $true
				$WPFcmdDeployLinkedCloneVMRefresh.IsEnabled = $true

				getVMSInventory
				#write-host "getVMSInventory Ready"
				
				$WPFlvVMs.SelectedIndex = 0
			} else {
				Write-Host "$VC -and $CH -and $CB -and $ADCred"
			}

	}

	function unloadAndDisconnect() {
			
		DisConnect-VIServer -Force -ErrorAction SilentlyContinue -Confirm:$false | Out-Null
		$WPFcmdConnect.IsEnabled = $true
		$WPFcmdDisconnect.IsEnabled = $false
		($WPFtabControl.Items[1]).IsEnabled = $false
		($WPFtabControl.Items[2]).IsEnabled = $false
		$WPFcmdDeployLinkedCloneVM.IsEnabled = $false
		$WPFcmdDeployLinkedCloneVMRefresh.IsEnabled = $false
		$dtVMList.Clear()
		$dtSnapshotList.Clear()
		$dtVMSnapshots.Clear()
		$dtVMFolders.Clear()
		$dtVMDatastores.Clear()
		$dtADorganizationalUnit.Clear()
		$dtXenHypervisorConnection.Clear()
		$dtXenMachineCatalog.Clear()
		$dtXenDeliveryGroup.Clear()
		$dtADorganizationalUnit.Clear()
	}

	function consoleVMRC(){
		param (
			$ItemIndex
		)
		#thumbprint is on line 44 $connect[44] not tested yet 
		# $test = Powershell -Command  "Add-PSSnapin vmware.vimautomation.core; Connect-VIServer esxi -User Username -Password Password" 
		# $test[46].trim()
		#https://vcsa0001.bad-cloud.lan:9443/vsphere-client/webconsole.html?vmId=vm-514&vmName=AXA002&serverGuid=b882b87f-f00e-4109-94a1-bf3ebea2296b&locale=en_US&host=vcsa0001.bad-cloud.lan:443&sessionTicket=cst-VCT-520b3d79-0339-d447-4547-c5e5cfe34806--tp-7D-1D-D6-11-0B-DA-6E-23-7A-EC-1A-F1-B4-7E-EB-D1-1B-AD-BC-BF&thumbprint=7D:1D:D6:11:0B:DA:6E:23:7A:EC:1A:F1:B4:7E:EB:D1:1B:AD:BC:BF
		$_glDefault = $global:DefaultVIServers #| where {$_.Name -eq "$(($WPFlvVMs.SelectedItem).VMHost)"}
        $_sessionmanager = Get-View $_glDefault.ExtensionData.Client.ServiceContent.SessionManager
        $_vcenter = $_glDefault.serviceuri.Host
        $_vmid =  $dtVMlist.Rows[$ItemIndex].MoRef #$WPFlvVMs.SelectedIndex
        $_ticket =  $_sessionmanager.AcquireCloneTicket()
		
		#write-host "vmrc://clone:$($_ticket)@$($_vcenter):443/?moid=$($_vmid)"
        try {
			if (Test-Path -LiteralPath "C:\Program Files (x86)\VMware\VMware Remote Console\vmrc.exe"){
				Start-Process -FilePath "C:\Program Files (x86)\VMware\VMware Remote Console\vmrc.exe" -ArgumentList "vmrc://clone:$_ticket@$($_vcenter):443/?moid=$_vmid"
			}
			}
        catch {
			write-host $ErrorMessage
		}
    }

	# Control actions

	$Form.Add_Loaded({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		loadSettingsXML
	})


	$WPFcmdConnect.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		connectVIServer -UseADCredentials:$WPFchkbUseVCCredentials.IsChecked -vSphereConnection $WPFtxtvSphereConnection.Text.trim()
	})

	$WPFcmdDisconnect.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		
		)

		unloadAndDisconnect
	})

	#$WPFcmdDeployLinkedCloneVM.Add_Click({
	#	param(
	#		[Parameter(Mandatory)][Object]$sender,
	#		[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
	#	)

	#	deployLinkedCloneVMs `
	#		-ParentVM  $WPFcbbParentVM.SelectedItem.Row.GuestVM `
	#		-FullConeVM $WPFcbbParentVM.SelectedItem.Row.GuestVM `
	#		-DeleteVMBeforeDeploy:$WPFchkbRemoveMachine.IsChecked  `
	#		-StartVMAfterDeploy:$WPFchkbDLCVMPowerOn.IsChecked `
	#		-LinkVMtoXenDesktop:$WPFchkbUpdateHostedMachineID.IsChecked `
	#		-NewADComputerAccount:$WPFchkbADCreateComputerAccount.IsChecked `
	#		-CreatePooledVM:$WPFchkbVMCreatePooledVM.IsChecked
				
	#})

	$WPFcmlvVMsRefresh.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		ActionRefreshVMList

	})

	$WPFcmlvVMsDeleteFromDisk.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		$_anwser = actionMessageBox -MBMessage "Delete the virtual machine and its associated disks?`r`nIf other VMs are sharing their disks, the shared disks will not be deleted and the VMs will continue to have access to the shared disks." -MBTitle "Delete from Disk" -MBButtons "YesNo" -MBIcon "Warning"
		if ($_anwser -eq 'Yes'){
			if ($WPFlvVMs.SelectedIndex -gt -1){
				foreach($_item in $WPFlvVMs.SelectedItems){
					deleteVMPermanently -vmname $_item["GuestVM"]
				}

				if($WPFtxtVMSearch.Text.Length -gt 0){
					$WPFtxtVMSearch.Text = ""
				}
				getVMSInventory -ClearDataSet $true
				$WPFlvVMs.SelectedIndex = 0
			}
		}
	})

	$WPFcmdOpenConsole.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			consoleVMRC -ItemIndex $WPFlvVMs.SelectedIndex
		}
	})

	$WPFcmdPowerOn.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			ActionStartVM -VMname "$(($WPFlvVMs.SelectedItem).GuestVM)" -RunAsync $false
			updatePowerStateGuestVM -ItemIndex $WPFlvVMs.SelectedIndex -VMname ($WPFlvVMs.SelectedItem).GuestVM
			enableButtonsOnPowerState -PowerState ($WPFlvVMs.SelectedItem).GuestVMPowerState
		}
	})

	$WPFcmdPowerOff.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			ActionStopKillVM -VMname "$(($WPFlvVMs.SelectedItem).GuestVM)"

			updatePowerStateGuestVM -ItemIndex $WPFlvVMs.SelectedIndex -VMname ($WPFlvVMs.SelectedItem).GuestVM
			enableButtonsOnPowerState -PowerState ($WPFlvVMs.SelectedItem).GuestVMPowerState 
		}
	})

	$WPFcmdReset.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			ActionResetVM -VMname "$(($WPFlvVMs.SelectedItem).GuestVM)"
			updatePowerStateGuestVM -ItemIndex $WPFlvVMs.SelectedIndex -VMname ($WPFlvVMs.SelectedItem).GuestVM
		}
	})

	$WPFcmdShutdownGuest.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			Stop-VMGuest -VM "$(($WPFlvVMs.SelectedItem).GuestVM)" -Confirm:$false | Out-Null
			updatePowerStateGuestVM -ItemIndex $WPFlvVMs.SelectedIndex -VMname ($WPFlvVMs.SelectedItem).GuestVM
			enableButtonsOnPowerState -PowerState ($WPFlvVMs.SelectedItem).GuestVMPowerState 
		}
	})

	$WPFcmdRestartGuest.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			Restart-VMGuest -VM "$(($WPFlvVMs.SelectedItem).GuestVM)" -Confirm:$false | Out-Null
		}
	})

	$WPFtxtVMSearch.add_TextChanged({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.Controls.TextChangedEventArgs]$e
		)

		[void]$dtSnapshotList.Clear()

		$find = $WPFtxtVMSearch.text


		$dvVMlist.RowFilter = "GuestVM LIKE '$find*'"

		[void]$WPFlvVMs.UnselectAll()
	})

	$WPFlvVMs.Add_SelectionChanged({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.Controls.SelectionChangedEventArgs]$e
		)
		if ($WPFlvVMs.SelectedIndex -gt -1){
			updatePowerStateGuestVM -ItemIndex $WPFlvVMs.SelectedIndex -VMname ($WPFlvVMs.SelectedItem).GuestVM  
			createSnapshotList -vmname ($WPFlvVMs.SelectedItem).GuestVM -ClearDataSet $true
			enableButtonsOnPowerState -PowerState ($WPFlvVMs.SelectedItem).GuestVMPowerState
		}
	})

	$WPFcmdSnapshotCreate.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			if(Get-VM -Name ($WPFlvVMs.SelectedItem).GuestVM | Where-Object{$_.PowerState -eq "PoweredOff"}){
				if($WPFtxtSnapshotName.Text.Length -gt 0){
					$WPFcmdSnapshotCreate.Content = "Creating Snapshot..."
					$WPFcmdSnapshotCreate.IsEnabled = $false
					newSnapshot -vmname ($WPFlvVMs.SelectedItem).GuestVM -newSnaphsotName $WPFtxtSnapshotName.Text.Trim()
					$dtSnapshotList.Clear()
					createSnapshotList -vmname ($WPFlvVMs.SelectedItem).GuestVM -ClearDataSet $true
					$WPFcmdSnapshotCreate.Content = "Create Snapshot..."
					$WPFcmdSnapshotCreate.IsEnabled = $true
					$WPFtxtSnapshotName.Text = ""
				}
			} else {

			}
		}
	})

	$WPFcmlvSnapshotListDeleteSelected.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if (($WPFlvSnapshotList.SelectedIndex -gt -1) -and ($WPFlvVMs.SelectedIndex -gt -1)){
			deleteSelectedSnapshot -ItemIndex $WPFlvSnapshotList.SelectedIndex -vmname ($WPFlvVMs.SelectedItem).GuestVM
			createSnapshotList -vmname ($WPFlvVMs.SelectedItem).GuestVM -ClearDataSet $true
		}
	})

	$WPFcmlvSnapshotListDeleteAll.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFlvVMs.SelectedIndex -gt -1){
			deleteAllSnapshots -vmname ($WPFlvVMs.SelectedItem).GuestVM 
			createSnapshotList -vmname ($WPFlvVMs.SelectedItem).GuestVM -ClearDataSet $true
		} 
	})

	$WPFcmlvSnapshotListRevertSnapshot.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if (($WPFlvSnapshotList.SelectedIndex -gt -1) -and ($WPFlvVMs.SelectedIndex -gt -1)){
			revertToSelectedSnapshot -ItemIndex $WPFlvSnapshotList.SelectedIndex -vmname ($WPFlvVMs.SelectedItem).GuestVM
			createSnapshotList -vmname ($WPFlvVMs.SelectedItem).GuestVM -ClearDataSet $true
		}
	})

	$WPFcmlvSnapshotListRefresh.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)
		if ($WPFlvVMs.SelectedIndex -gt -1){
			createSnapshotList -vmname ($WPFlvVMs.SelectedItem).GuestVM -ClearDataSet $true
		}
	})

	$WPFchkbUseVCCredentials.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFchkbUseVCCredentials.IsChecked -eq $false){
			$WPFlblVCUsername.IsEnabled = $false
			$WPFlblVCPasswd.IsEnabled = $false
			$WPFtxtVCUsername.IsEnabled = $false
			$WPFtxtVCPasswd.IsEnabled = $false
		}

		if ($WPFchkbUseVCCredentials.IsChecked -eq $true){
			$WPFlblVCUsername.IsEnabled = $true
			$WPFlblVCPasswd.IsEnabled = $true
			$WPFtxtVCUsername.IsEnabled = $true
			$WPFtxtVCPasswd.IsEnabled = $true
		}
	})

	$WPFtxtVCPasswd.Add_KeyUp({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
		)
		
		if($e.Key -eq [System.Windows.Input.Key]::Return){
			$Form.Cursor = [System.Windows.Input.Cursors]::Wait
			connectVIServer -UseADCredentials:$WPFchkbUseVCCredentials.isChecked -vSphereConnection $WPFtxtvSphereConnection.Text.trim()
			$Form.Cursor = [System.Windows.Input.Cursors]::Arrow
		}

	})
	
	$Form.ShowDialog() | out-null

	