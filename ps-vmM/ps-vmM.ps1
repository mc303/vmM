<#

	Context Menu HowTO https://learn-powershell.net/2014/07/24/building-a-clipboard-history-viewer-using-powershell/
	Clone Info http://www.vmdev.info/?p=202

	param input
	https://learn-powershell.net/2014/02/04/using-powershell-parameter-validation-to-make-your-day-easier/
#>

$inputXML = @"

"@
	$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
	$inputXML = Get-Content "$(Split-Path -Parent $PSScriptRoot)\gui-deploy-lc-vdi\gui-deploy-lc-vdi.xaml"

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

	$currentdomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
	$WPFtxtDNSRoot.text = $env:USERDNSDOMAIN.ToLower()
	$WPFtxtNetBIOSName.text = $env:USERDOMAIN
	$WPFtxtADDNSSuffix.text = "eu.$($env:USERDNSDOMAIN.ToLower())"
	$WPFtxtADDomainController.Text = "$($currentdomain.PdcRoleOwner.Name)"

	#Extra AD info
	$WPFtxtADDistinguishedName.Text = $currentdomain.Forest.Schema.Name.Replace("CN=Schema,CN=Configuration,","")
	$WPFtxtADComputersContainery.Text = "CN=Computers,{0}" -f $currentdomain.Forest.Schema.Name.Replace("CN=Schema,CN=Configuration,","")

	#vSphere ssl Thumbprint
	$thumbprintSSL = ""

	$WPFcbbVMHostnameNumbering.Items.Add("1") | Out-Null
	$WPFcbbVMHostnameNumbering.Items.Add("01") | Out-Null
	$WPFcbbVMHostnameNumbering.Items.Add("001") | Out-Null
	$WPFcbbVMHostnameNumbering.Items.Add("0001") | Out-Null
	$WPFcbbVMHostnameNumbering.Items.Add("00001") | Out-Null
	$WPFcbbVMHostnameNumbering.Items.Add("000001") | Out-Null
	$WPFcbbVMHostnameNumbering.Items.Add("0000001") | Out-Null


	$WPFcbbVMMemoryInGB.Items.Add("1") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("2") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("4") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("6") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("8") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("10") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("12") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("16") | Out-Null
	$WPFcbbVMMemoryInGB.Items.Add("32") | Out-Null

	$WPFcbbVMMemoryInGB.Text = 8

	$WPFcbbVMMemoryReservationInGB.Items.Add("0") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("1") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("2") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("4") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("6") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("8") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("10") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("12") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("16") | Out-Null
	$WPFcbbVMMemoryReservationInGB.Items.Add("32") | Out-Null

	$WPFcbbVMMemoryReservationInGB.Text = 6

	#Set predefined settings
	$WPFcbbVMHostnameNumbering.SelectedIndex = 0 

	$WPFcmdSnapshotCreate.IsEnabled = $false
	$WPFcmdOpenConsole.IsEnabled = $false
	$WPFcmdPowerOn.IsEnabled = $false
	$WPFcmdPowerOff.IsEnabled = $false
	$WPFcmdReset.IsEnabled = $false
	$WPFcmdShutdownGuest.IsEnabled = $false
	$WPFcmdRestartGuest.IsEnabled = $false

	$WPFcmdDisconnect.IsEnabled = $false
	
	$WPFcbbADOU.IsEnabled = $false
	$WPFlblADOU.IsEnabled = $false
	$WPFcbbXenHypervisorConnection.IsEnabled = $false
	$WPFcbbXDHyp.IsEnabled = $false
	$WPFlblXenHypervisorConnection.IsEnabled = $false
	$WPFlblXenXDHyp.IsEnabled = $false

	$WPFlblXenDeliveryGroup.IsEnabled = $false
	$WPFcbbXenDeliveryGroup.IsEnabled = $false
	$WPFlblXenMachineCatalog.IsEnabled = $false
	$WPFcbbXenMachineCatalog.IsEnabled = $false
	$WPFcmdRefreshXDhyp.IsEnabled = $false
	$WPFcmdRefreshHypervisorConnection.IsEnabled = $false
	$WPFcmdRefreshMachineCatalog.IsEnabled = $false
	$WPFcmdRefreshDeliveryGroup.IsEnabled = $false

	$WPFcmdRefreshADOU.IsEnabled = $false

	$WPFchkbADCreateComputerAccount.IsChecked = $false

	$WPFchkbGuestinfoHostname.IsChecked = $true
	$WPFchkbRemoveMachine.IsChecked = $true
	$WPFchkbPurgeKerberos.IsChecked = $true

	$WPFlblVCUsername.IsEnabled = $false
	$WPFlblVCPasswd.IsEnabled = $false
	$WPFtxtVCUsername.IsEnabled = $false
	$WPFtxtVCPasswd.IsEnabled = $false

	$WPFlblADUsername.IsEnabled = $false
	$WPFlblADPasswd.IsEnabled = $false
	$WPFtxtADUsername.IsEnabled = $false
	$WPFtxtADPasswd.IsEnabled = $false

	$WPFchkbVMCreatePooledVM.IsChecked = $true

	$WPFcbbParentVM.IsEnabled = $True
	$WPFcbbVMFolders.IsEnabled = $True
	$WPFcbbVMDatastores.IsEnabled = $True
	$WPFcmdRefreshParentVM.IsEnabled = $True
	$WPFcmdRefreshDatastore.IsEnabled = $True
	$WPFcmdRefreshFolder.IsEnabled = $True

	#Disable buttons on Linked Clone Tab
	$WPFcmdDeployLinkedCloneVM.IsEnabled = $false
	$WPFcmdDeployLinkedCloneVMRefresh.IsEnabled = $false

	$WPFlblHostnameCount.content = """=0"" NetBIOS Name max 15 characters"
	
	#Set tabindex for the tab1 controls 
	$WPFtxtvSphereConnection.TabIndex = 0
	$WPFtxtAdminServer.TabIndex = 1
	$WPFtxtDNSRoot.TabIndex = 2
	$WPFtxtNetBIOSName.TabIndex = 3
	$WPFtxtVCUsername.TabIndex = 4
	$WPFtxtVCPasswd.TabIndex = 5  
	$WPFcmdConnect.TabIndex = 6
	
	# Create DataSet
	$dtVMList = New-Object System.Data.DataTable("VMList")
	$dtSnapshotList = New-Object System.Data.DataTable("SnapshotList")
	$dtVMParentVM  = New-Object System.Data.DataTable("VMParentVM")
	$dtVMSnapshots  = New-Object System.Data.DataTable("VMSnapshots")
	$dtVMFolders = New-Object System.Data.DataTable("VMFolders")
	$dtVMDatastores = New-Object System.Data.DataTable("VMDatastores")
	$dtADorganizationalUnit = New-Object System.Data.DataTable("ADorganizationalUnit")
	$dtXenHypervisorConnection= New-Object System.Data.DataTable("XenHypervisorConnection")
	$dtXenMachineCatalog = New-Object System.Data.DataTable("XenMachineCatalog")
	$dtXenDeliveryGroup = New-Object System.Data.DataTable("XenDeliveryGroup")

	$dvVMlist	= New-Object System.Data.DataView($dtVMList)
	$dvSnapshotList	= New-Object System.Data.DataView($dtSnapshotList)
	$dvVMParentVM	= New-Object System.Data.DataView($dtVMParentVM)
	$dvVMSnapshots	= New-Object System.Data.DataView($dtVMSnapshots)
	$dvVMFolders	= New-Object System.Data.DataView($dtVMFolders)
	$dvVMDatastores	= New-Object System.Data.DataView($dtVMDatastores)
	$dvADorganizationalUnit	= New-Object System.Data.DataView($dtADorganizationalUnit)
	$dvXenHypervisorConnection	= New-Object System.Data.DataView($dtXenHypervisorConnection)
	$dvXenMachineCatalog = New-Object System.Data.DataView($dtXenMachineCatalog)
	$dvXenDeliveryGroup	= New-Object System.Data.DataView($dtXenDeliveryGroup)

	$colsVMList = @("GuestVM","GuestVMPowerState","VMHost","MoRef","GuestVMID")
	$colsSnapshotList = @("IsCurrent","SnapshotName","DateCreated","ParentSnapshot","SnapshotID","ParentSnapshotID")
	$colsVMParentVM	= @("GuestVM","GuestVMID")
	$colsVMSnapshots = @("Snapshot","SnapshotID")
	$colsVMFolders = @("Folder","FolderID")
	$colsVMDatastores = @("Datastore","DatastoreID")
	$colsADorganizationalUnit = @("CanonicalName","DistinguishedName")
	$colsXenHypervisorConnection = @("HypervisorConnection","Uid")
	$colsXenMachineCatalog = @("MachineCatalog","Uid")
	$colsXenDeliveryGroup = @("DeliveryGroup","Uid")

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

	foreach ($colADorganizationalUnit in $colsADorganizationalUnit) {
		$dtADorganizationalUnit.Columns.Add($colADorganizationalUnit) | Out-Null
	}

	foreach ($colXenHypervisorConnection in $colsXenHypervisorConnection) {
		$dtXenHypervisorConnection.Columns.Add($colXenHypervisorConnection) | Out-Null
	}

	foreach ($colXenMachineCatalog in $colsXenMachineCatalog) {
		$dtXenMachineCatalog.Columns.Add($colXenMachineCatalog) | Out-Null
	}

	foreach ($colXenDeliveryGroup in $colsXenDeliveryGroup) {
		$dtXenDeliveryGroup.Columns.Add($colXenDeliveryGroup) | Out-Null
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

	$WPFcbbADOU.ItemsSource = $dvADorganizationalUnit
	$WPFcbbADOU.DisplayMemberPath = 'CanonicalName'
	$WPFcbbADOU.SelectedValuePath = 'DistinguishedName'

	$WPFcbbXenHypervisorConnection.ItemsSource = $dvXenHypervisorConnection
	$WPFcbbXenHypervisorConnection.DisplayMemberPath = 'HypervisorConnection'
	$WPFcbbXenHypervisorConnection.SelectedValuePath = 'Uid'

	$WPFcbbXenMachineCatalog.ItemsSource = $dvXenMachineCatalog
	$WPFcbbXenMachineCatalog.DisplayMemberPath = 'MachineCatalog'
	$WPFcbbXenMachineCatalog.SelectedValuePath = 'Uid'

	$WPFcbbXenDeliveryGroup.ItemsSource = $dvXenDeliveryGroup
	$WPFcbbXenDeliveryGroup.DisplayMemberPath = 'DeliveryGroup'
	$WPFcbbXenDeliveryGroup.SelectedValuePath = 'Uid'

	#Disables Tabs 
	($WPFtabControl.Items[1]).IsEnabled = $false 
	($WPFtabControl.Items[2]).IsEnabled = $false

	function loadSettingsXML{

		[xml]$ConfigSettings = Get-Content "$PSScriptRoot\settings.xml"

		if($ConfigSettings.settings.main.vsphereconnection){$WPFtxtvSphereConnection.Text = $ConfigSettings.settings.main.vsphereconnection}
		if($ConfigSettings.settings.main.vcusername){$WPFtxtVCUsername.Text = $ConfigSettings.settings.main.vcusername}
		if($ConfigSettings.settings.main.vcpasswd){$WPFtxtVCPasswd.Password = $ConfigSettings.settings.main.vcpasswd}
		if($ConfigSettings.settings.main.adminserver){$WPFtxtAdminServer.text = $ConfigSettings.settings.main.adminserver}
		if($ConfigSettings.settings.main.vmhostnameprefix){$WPFtxtVMHostnamePrefix.Text = $ConfigSettings.settings.main.vmhostnameprefix}
		if($ConfigSettings.settings.main.vmstartnumber){$WPFtxtVMStartNumber.Text = $ConfigSettings.settings.main.vmstartnumber}
		if($ConfigSettings.settings.main.vmsdeploy){$WPFtxtVMSDeploy.Text = $ConfigSettings.settings.main.vmsdeploy}
		if($ConfigSettings.settings.main.vmhostnamenumbering){$WPFcbbVMHostnameNumbering.SelectedIndex = $ConfigSettings.settings.main.vmhostnamenumbering}

		if($ConfigSettings.settings.main.dnssuffix){$WPFtxtADDNSSuffix.text = $ConfigSettings.settings.main.dnssuffix}
		if($ConfigSettings.settings.main.domaincontroller){$WPFtxtADDomainController.Text = $ConfigSettings.settings.main.domaincontroller}

		$WPFlblHostnameCount.content = """=$($WPFcbbVMHostnameNumbering.Text.Length + $WPFtxtVMHostnamePrefix.Text.Length)"" NetBIOS Name max 15 characters"
		$WPFtxtVMHostnamePrefix.MaxLength = 15 - $WPFcbbVMHostnameNumbering.Text.Length
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

	function executeKlist(){
		# delete all the tickets of the specified logon session.
		Write-Host "klist -li 0x3e4 purge"
		& klist -li 0x3e4 purge
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

	function addItemADorganizationalUnit{
		param($CanonicalName,
			  $DistinguishedName
		)

		$dtADorganizationalUnit.Rows.Add("$CanonicalName","$DistinguishedName")
	}

	function addItemXenHypervisorConnection(){
		param(
			$HypervisorConnection,
			$Uid
		)

		$dtXenHypervisorConnection.Rows.Add("$HypervisorConnection","$Uid")
	}
	
	function addItemXenMachineCatalog(){
		param(
			$MachineCatalog,
			$Uid
		)

		$dtXenMachineCatalog.Rows.Add("$MachineCatalog","$Uid")
	}
	
	function addItemXenDeliveryGroup(){
		param(
			$DeliveryGroup,
			$Uid
		)

		$dtXenDeliveryGroup.Rows.Add("$DeliveryGroup","$Uid")
	}

	function addItemToSnapshotList(){
		param(
			$IsCurrent,
			$SnapshotName,
			$DateCreated,
			$ParentSnapshot,
			$SnapshotID,
			$ParentSnapshotID
		)

		$dtSnapshotList.Rows.Add("$IsCurrent","$SnapshotName","$DateCreated","$ParentSnapshot","$SnapshotID","$ParentSnapshotID")
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

		$_snapshot = Get-VM -Name $vmname | Get-Snapshot -ErrorAction SilentlyContinue | Sort-Object -Descending
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
	function readRefreshVMwareParentVM{
		$dtVMParentVM.Clear()
		
		Get-VM | Sort-Object Name | ForEach-Object {
			addItemToVMParentVM -GuestVM $_.Name -GuestVMID $_.Id
		}
		
		if($dtVMParentVM.Rows.Count -gt 0){$WPFcbbParentVM.SelectedIndex = 0}
	}

	function readRefreshVMwareFolders(){
		$dtVMFolders.Clear()

		Get-Folder | Get-FolderPath | Sort-Object Path | % {
			addItemToVMFolders -Folder $_.Path -FolderID $_.Id
		}
		
		if($dtVMFolders.Rows.Count -gt 0){$WPFcbbVMFolders.SelectedIndex = 0}
	}

	function readRefreshVMwareDatastores(){
		$dtVMDatastores.Clear()
		
		Get-Datastore | Sort-Object Name | % {
			addItemToVMDatastores -Datastore $_.Name -DatastoreID $_.Id
		}

		if($dtVMDatastores.Rows.Count -gt 0){$WPFcbbVMDatastores.SelectedIndex = 0}
	}

	function readRefreshXenDesktopXDHyp(){
		$WPFcbbXDHyp.Items.Clear()

		Get-ChildItem "XDHyp:\Connections" -Recurse | Where-Object{($_.ObjectType -eq "Cluster")} | Select-Object FullPath | % {
			$WPFcbbXDHyp.items.Add($_.FullPath)
		}
		
		if($WPFcbbXDHyp.Items.Count -gt 0){$WPFcbbXDHyp.SelectedIndex = 0}
	}

	function readRefreshADOUV2(){
		$dtADorganizationalUnit.Clear()
		$_rootDistinguishedName = $WPFtxtADDistinguishedName.Text.Trim()
		$_computerOU =  $WPFtxtADComputersContainery.Text.Trim()

		$strFilter = "(objectCategory=organizationalUnit)"

		$objDomain = New-Object System.DirectoryServices.DirectoryEntry

		$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
		$objSearcher.SearchRoot = $objDomain
		$objSearcher.PageSize = 1000
		$objSearcher.Filter = $strFilter
		$objSearcher.SearchScope = "Subtree"

        $objSearcher.PropertiesToLoad.Add("distinguishedName") > $Null
        $objSearcher.PropertiesToLoad.Add("Name") > $Null

        $colResults = $objSearcher.FindAll()

		addItemADorganizationalUnit -CanonicalName "Computers" -DistinguishedName $_computerOU

        foreach ($objResult in $colResults){
            $_ous = $objResult.Properties.Item("distinguishedName")
            $_ous_split = $_ous.Replace(",$($WPFtxtADDistinguishedName.Text)","").Replace("OU=","").Split(",")
			
            $_x = $_ous_split.Count

            for($i=$_x; $i -ge 0;$i--){ 
                $_connacial += "$($_ous_split[$i])/"
            }
			$_connacial = $_connacial.TrimStart("/").TrimEnd("/")

			addItemADorganizationalUnit -CanonicalName $_connacial -DistinguishedName $_ous
            $_connacial = $null
        }

		if($WPFcbbADOU.Items.Count -gt 0){$WPFcbbADOU.SelectedIndex = 0}

		$dvADorganizationalUnit.Sort = "CanonicalName"
	}

	function readHypervisorConnections(){
		$dtXenHypervisorConnection.Clear()

		Get-BrokerHypervisorConnection -AdminAddress $WPFtxtAdminServer.Text | % {
			addItemXenHypervisorConnection -HypervisorConnection $_.Name -Uid $_.Uid
		}
		if($WPFcbbXenHypervisorConnection.Items.Count -gt 0){$WPFcbbXenHypervisorConnection.SelectedIndex = 0}
	}

	function readRefreshXenBrokerCatalog(){
		$dtXenMachineCatalog.Clear()

		Get-BrokerCatalog -AdminAddress $WPFtxtAdminServer.Text  | Where-Object {$_.ProvisioningType -eq "Manual"} | % {
			addItemXenMachineCatalog -MachineCatalog $_.Name -Uid $_.Uid
		}
		if($WPFcbbXenMachineCatalog.Items.Count -gt 0){$WPFcbbXenMachineCatalog.SelectedIndex = 0}
	}

	function readRefreshXenBrokerDesktopGroup(){
		$dtXenDeliveryGroup.Clear()

		Get-BrokerDesktopGroup -AdminAddress $WPFtxtAdminServer.Text  | % {
			addItemXenDeliveryGroup -DeliveryGroup $_.Name -Uid $_.Uid
		}
		if($WPFcbbXenDeliveryGroup.Items.Count -gt 0){$WPFcbbXenDeliveryGroup.SelectedIndex = 0}
	}

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


	function actionCreateNewADComputerAccountV2{
        param(
			$ADComputerName,
			$OU,
            $DNSSuffix,
            $DomainController,
			[switch]$ADCredentials,
			$Username,
			$Passwd
		)

        $_dNSHostName = "$ADComputerName.$DNSSuffix"
        $_ldap = "LDAP://$DomainController/$OU"
        $_username = "$($env:USERDOMAIN)\$Username"
		$_objDomain = $null

		if(!(actionFindADComputerV2 -ADComputerName $ADComputerName)){
			if($ADCredentials){
				$_objDomain = New-Object System.DirectoryServices.DirectoryEntry($_ldap,$_username,$Passwd)
			} else {
				$_objDomain = New-Object System.DirectoryServices.DirectoryEntry($_ldap)
			}

			$objComputer = $_objDomain.Create("computer", "CN=$ADComputerName") 
			$objComputer.Put("sAMAccountName",$ADComputerName + "$") # A dollar sign must be appended to the end of every computer sAMAccountName. 
			$objComputer.Put("dNSHostName", $_dNSHostName) 
			$objComputer.Put("userAccountControl", 4128) 
			$objComputer.SetInfo()
		}
    }

	function actionFindADComputerV2{
		param(
			$ADComputerName
		)


		Add-Type -AssemblyName System.DirectoryServices.AccountManagement | out-null
		$_ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain          
		$_computer = [System.DirectoryServices.AccountManagement.Principal]::FindByIdentity($_ct, $ADComputerName)    

		if ($_computer.name){
            return $true       
        } else {
            return $false  
        }
	}

	function waitUntilADComputerAccountsExists{
		param(
			$ADComputerNames,
			$WaitFor5SecCount
		)

		[System.Collections.ArrayList]$_ad_exists = @()
		$_ad_exists_all = $true
		do {
			foreach($ADComputerName in $ADComputerNames){
				$_exists = actionFindADComputerV2 -ADComputerName $ADComputerName
				$_ad_exists.Add($_exists)
			}
			#Write-Host $_exists 
			$_ad_exists | ForEach-Object{
				if (!$_){
					$_ad_exists_all = $false
				}
			} | Out-Null
            $_ad_exists.Clear()
			Start-Sleep 5
			$x+=1
		}until (($_ad_exists_all) -or ($x -eq $WaitFor5SecCount)) # End of 'Do'

		if ($x -eq $WaitFor5SecCount){
			return $false
		} else {
			return $true
		}
	}

	
    Function actionValidateADCredentials {
		Param(
			$username, 
			$passwd
		)
        
        $_username_old = "$($env:USERDOMAIN)\$username"
        $_username_new = "$username@$($env:USERDNSDOMAIN.ToLower())"
		$_username_new2 = "$username@$($env:USERDOMAIN.ToLower())"
		$_username_new3 = "$username"
        write-host $_username_new3

		Add-Type -AssemblyName System.DirectoryServices.AccountManagement

		$ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
		$pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ct, $env:USERDOMAIN)
            
		$_exists = $pc.ValidateCredentials($_username_new3, $passwd).ToString()
		Write-Host $_exists
		#return $_exists
		
		switch ($_exists){
			'True' {
				return $true
			}
			'False' {
				return $false
			}
		}
	}

	function waitUntilVMIsOnline{
        param(
            $__destfolder
        )

        #Check if the vmware tools are running and then go on
        [System.Collections.ArrayList]$_toolsrunningstatus = @()

       # Write-Host "Waiting for VMware tools to start...."
        do{
            Get-VM -Location $__destfolder | Sort-Object name | ForEach-Object{
                $_toolsrunningstatus_all = $true
                    if($_.Guest.OSFullName){
                        # $_.Guest.OSFullName
                        if ($_.Guest.ExtensionData.ToolsRunningStatus -eq "guestToolsRunning"){
                            $_toolsrunningstatus.Add($true) | Out-Null
                        } else {
                            $_toolsrunningstatus.Add($false) | Out-Null
                        }
                    } else {
                        $_toolsrunningstatus_all = $false
                    } 
            } | Out-Null

         
             $_toolsrunningstatus | ForEach-Object{
             #$_
                if (!$_){
                    $_toolsrunningstatus_all = $false
          
                }
             } | Out-Null
             Start-Sleep 2
             $_toolsrunningstatus.Clear()
        }until ($_toolsrunningstatus_all -eq $true)
    }

	function waitForXenHostMachineIDIsFound{
		param(
			$VMname,
			$XDHyp
		)
		
		Do {
			$_hostmachineid = Get-ChildItem $XDHyp | Where-Object{$_.ObjectType -eq "vm" } | Where-Object{ $_.Name -eq $VMname} | Select-Object name,id
			if ($_hostmachineid -ne $null){
				#Write-Host "Start-Sleep 2" 
				Start-Sleep 2
			}
			$x+=1
			} # End of 'Do'
		Until (($_hostmachineid -ne $null) -or ($x -eq 30))
		return $_hostmachineid
	}

	function updateOrAddVMtoBrokerMachine(){
		 param(
			$AdminAddress,
			$XDHyp,
			$DeployedLinkedCloneVMs,
			$HypervisorConnectionUID,
			$DesktopDeliveryGroupUID,
			$MachineCatalogUID,
			$NetBIOSDomain,
			[switch]$TurnOnMaintenanceMode,
			$Tag
        )	

		$_hostmachineids = $null

		#Link new Linked CLone to Broker Machine in XenDesktop
		$_hostmachineids = Get-ChildItem $XDHyp | Where-Object{$_.ObjectType -eq "vm" } | Select-Object name,id

		foreach ($DeployedLinkedCloneVM in $DeployedLinkedCloneVMs){
			$_vdiitem = Get-BrokerMachine -AdminAddress $AdminAddress -MachineName ("$NetBIOSDomain\$DeployedLinkedCloneVM").ToUpper() -ErrorAction SilentlyContinue
			$_hostmachineid = $_hostmachineids | Where-Object{ $_.Name -eq $DeployedLinkedCloneVM} 

			if ($_vdiitem){
				# Reset connection between VM en VDI in XenDesktop
				# Get machine host id from XenDesktop
				# Update Host Machine ID
				if ($_hostmachineid -eq $null){
					$_hostmachineid = waitForXenHostMachineIDIsFound -VMname $DeployedLinkedCloneVM -XDHyp $XDHyp
				}
					
				$_vdiitem | Set-BrokerMachine -AdminAddress $AdminAddress -HostedMachineId $_hostmachineid.Id -HypervisorConnectionUid $HypervisorConnectionUID 

				#Check if Machine is in a DesktopGroup
				if ($_vdiitem.DesktopGroupUid -eq $null){
					write-host "Not in DesktopGroup"
					$_desktopgroup = (Get-BrokerDesktopGroup -Uid $DesktopDeliveryGroupUID).Name
					$_machineuuid = $_vdiitem.Uid
					
					Add-BrokerMachine -AdminAddress $_adminserver -DesktopGroup $_desktopgroup -InputObject @($_machineuuid) | Out-Null

				# Move to selected DesktopGroup
				} elseif ($_vdiitem.DesktopGroupUid -ne $DesktopDeliveryGroupUID){
					$_associatedusernames = $_vdiitem.AssociatedUserNames
					$_desktopgroup = (Get-BrokerDesktopGroup -Uid $DesktopDeliveryGroupUID).Name
					$_machineuuid = $_vdiitem.Uid

					$_vdiitem | Remove-BrokerMachine -AdminAddress $_adminserver -DesktopGroup $_vdiitem.DesktopGroupUid  -Force:$true #| Out-Null
					Add-BrokerMachine -AdminAddress $_adminserver -DesktopGroup $_desktopgroup -InputObject @($_machineuuid) | Out-Null

					foreach($_associatedusername in $_associatedusernames){
						Add-BrokerUser -AdminAddress $AdminAddress -Machine ("$NetBIOSDomain\$DeployedLinkedCloneVM").ToUpper() -Name $_associatedusername
					}
				}

			} else {
				#Machine not found. Create new Machine and add to delivery controller
				$_desktopDeliveryGroup = (Get-BrokerDesktopGroup -Uid $DesktopDeliveryGroupUID).Name

				if ($_hostmachineid -eq $null){
					$_hostmachineid = waitForXenHostMachineIDIsFound -VMname $DeployedLinkedCloneVM -XDHyp $XDHyp
				}

				#write-host "$AdminAddress, $MachineCatalogUID, $HypervisorConnectionUID, $($_hostmachineid.id), $NetBIOSDomain, $DeployedLinkedCloneVM"
				New-BrokerMachine `
					-AdminAddress $AdminAddress `
					-CatalogUid $MachineCatalogUID `
					-HypervisorConnectionUid $HypervisorConnectionUID `
					-HostedMachineId $_hostmachineid.id `
					-MachineName ("$NetBIOSDomain\$DeployedLinkedCloneVM").ToUpper() `
					| Out-Null

				$x=0
				Do {
					$_machineuuid = (Get-BrokerMachine -AdminAddress $AdminAddress -MachineName "$NetBIOSDomain\$DeployedLinkedCloneVM" -ErrorAction SilentlyContinue).Uid
					Start-Sleep 2
					$x+=1
					} # End of 'Do'
				Until (($_machineuuid -ne $null) -or ($x -eq 30))
						
				Add-BrokerMachine -AdminAddress $AdminAddress -DesktopGroup $_desktopDeliveryGroup -InputObject @($_machineuuid) | Out-Null

			}

			if ($TurnOnMaintenanceMode){
				actionSetMachineInMaintenanceMode -AdminAddress $AdminAddress -MachineName $DeployedLinkedCloneVM -NetBIOSDomain $NetBIOSDomain
			}
		}
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

	function actionSetMachineInMaintenanceMode{
		param(
			$AdminAddress,
			$MachineName,
			$NetBIOSDomain
			
		)

		Get-BrokerMachine -AdminAddress $AdminAddress -MachineName ("$NetBIOSDomain\$MachineName") | Set-BrokerMachine -InMaintenanceMode:$true | Out-Null
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

	function credentialsAD{
		$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @("$($WPFtxtADUsername.Text)",$WPFtxtADPasswd.SecurePassword)
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


			try{
				if (!(Get-PSSnapin Citrix.Broker.Admin.V2 -ErrorAction SilentlyContinue)){
					write-host "Citrix.Broker.Admin.V2"
					Add-PSSnapin Citrix.Broker.Admin.V2  | Out-Null
					$CB = $true
				} Else {
					$CB = $true
				}
			} catch [Exception]{
				write-host "Error Message: $($_.Exception.Message)"
				write-host "Error ItemName: $($_.Exception.ItemName)"
				Write-Host "Error"
				$CB = $false
			}

			try{
				if (!(Get-PSSnapin Citrix.Host.Admin.V2 -ErrorAction SilentlyContinue)){
					write-host "Citrix.Host.Admin.V2"
					Add-PSSnapin Citrix.Host.Admin.V2  | Out-Null
					$CH = $true
				} Else {
					$CH = $true
				}
			} catch [Exception] {
				write-host "Error Message: $($_.Exception.Message)"
				write-host "Error ItemName: $($_.Exception.ItemName)"
				Write-Host "Error"
				$CH = $false
			} 

			if ($WPFchkbADCredToCreateADComputer.IsChecked){
				TRY{
					$_exists = actionValidateADCredentials -username $WPFtxtADUsername.Text.trim() -passwd $WPFtxtADPasswd.Password
					if ($_exists){
						write-host "AD Credentials Validated"
						$ADCred = $true
					} Else {
						$ADCred = $false
						$_errmsg = "Cannot validate AD credentials due to an`r`nincorrect user name or password."
						actionMessageBox -MBMessage $_errmsg -MBTitle "InvalidLogin" -MBButtons "OK" -MBIcon "Error"
					}				
				} catch [Exception] {
					write-host "Error Message: $($_.Exception.Message)"
					write-host "Error ItemName: $($_.Exception.ItemName)"
					Write-Host "Error"
					$ADCred = $false
				}
			} else {
				$ADCred = $true
			}

			if($VC -and $CH -and $CB -and $ADCred ){
				Write-Host "$VC -and $CH -and $CB -and $ADCred"
				$WPFcmdConnect.IsEnabled = $False
				$WPFcmdDisconnect.IsEnabled = $true
				$WPFcmdConnect.Content = "Connected"
				$WPFcmdDisconnect.Visibility = [System.Windows.Visibility]::Visible

				#Enable Tabs 2 and 3
				($WPFtabControl.Items[1]).IsEnabled = $true
				($WPFtabControl.Items[2]).IsEnabled = $true
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

	$WPFcmdDeployLinkedCloneVM.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		deployLinkedCloneVMs `
			-ParentVM  $WPFcbbParentVM.SelectedItem.Row.GuestVM `
			-FullConeVM $WPFcbbParentVM.SelectedItem.Row.GuestVM `
			-DeleteVMBeforeDeploy:$WPFchkbRemoveMachine.IsChecked  `
			-StartVMAfterDeploy:$WPFchkbDLCVMPowerOn.IsChecked `
			-LinkVMtoXenDesktop:$WPFchkbUpdateHostedMachineID.IsChecked `
			-NewADComputerAccount:$WPFchkbADCreateComputerAccount.IsChecked `
			-CreatePooledVM:$WPFchkbVMCreatePooledVM.IsChecked
				
	})

	$WPFcmdDeployLinkedCloneVMRefresh.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)
		$_vmoptions = $false
		$_xenoptions = $false
		$_adoptions = $false

		readRefreshVMwareParentVM 

		readRefreshVMwareFolders

		readRefreshVMwareDatastores

		$_vmoptions = $true

		if($WPFchkbUpdateHostedMachineID.IsChecked){
			readRefreshXenDesktopXDHyp

			readHypervisorConnections

			readRefreshXenBrokerCatalog

			readRefreshXenBrokerDesktopGroup

			$_xenoptions = $true
		} else {
			$WPFcbbXDHyp.Items.Clear()
			$dtXenHypervisorConnection.clear()
			$dtXenMachineCatalog.Clear()
			$dtXenDeliveryGroup.Clear()
		}

		if($WPFchkbADCreateComputerAccount.IsChecked){

			readRefreshADOUV2

			$_adoptions =$true
		} else {
			$dtADorganizationalUnit.Clear()
		}

		if($_vmoptions -or $_xenoptions -or $_adoptions){
			$WPFcmdDeployLinkedCloneVM.IsEnabled = $true
		} else {
			$WPFcmdDeployLinkedCloneVM.IsEnabled = $false
		}
	})

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


	$WPFchkbVMCreatePooledVM.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFchkbVMCreatePooledVM.IsChecked -eq $false){
			$WPFcbbVMFolders.IsEnabled = $false
			$WPFcbbVMDatastores.IsEnabled = $false
			$WPFcmdRefreshDatastore.IsEnabled = $false
			$WPFcmdRefreshFolder.IsEnabled = $false
			$WPFlblDatastores.IsEnabled = $false
			$WPFlblVMFolders.IsEnabled = $false
			$WPFlblVMMemoryInGB.IsEnabled = $false
			$WPFcbbVMMemoryInGB.IsEnabled = $false
			$WPFlblVMMemoryInGBGB.IsEnabled = $false
			$WPFlblVMMemoryReservationInGB.IsEnabled = $false
			$WPFcbbVMMemoryReservationInGB.IsEnabled = $false
			$WPFlblVMMemoryReservationInGBGB.IsEnabled = $false
			$WPFchkbDLCVMPowerOn.IsEnabled = $false
			$WPFchkbRemoveMachine.IsEnabled = $false
			$WPFchkbDLCVMPowerOn.IsChecked = $false
			$WPFchkbRemoveMachine.IsChecked = $false
		}

		if ($WPFchkbVMCreatePooledVM.IsChecked -eq $true){
			$WPFcbbVMFolders.IsEnabled = $true
			$WPFcbbVMDatastores.IsEnabled = $True
			$WPFcmdRefreshDatastore.IsEnabled = $true
			$WPFcmdRefreshFolder.IsEnabled = $true
			$WPFlblDatastores.IsEnabled = $true
			$WPFlblVMFolders.IsEnabled = $true
			$WPFlblVMMemoryInGB.IsEnabled = $true
			$WPFcbbVMMemoryInGB.IsEnabled = $true
			$WPFlblVMMemoryInGBGB.IsEnabled = $true
			$WPFlblVMMemoryReservationInGB.IsEnabled = $true
			$WPFcbbVMMemoryReservationInGB.IsEnabled = $true
			$WPFlblVMMemoryReservationInGBGB.IsEnabled = $true

			$WPFchkbDLCVMPowerOn.IsEnabled = $true
			$WPFchkbRemoveMachine.IsEnabled = $true

			$WPFcbbParentVM.SelectedIndex = 0
			
		}
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

	$WPFtxtVMHostnamePrefix.Add_TextChanged({
		#TextChangedEventArgs
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.Controls.TextChangedEventArgs]$e
		)

		$_txtLength = $WPFtxtVMHostnamePrefix.Text.Length + $WPFcbbVMHostnameNumbering.Text.Length
		$WPFlblHostnameCount.Content = """=$_txtLength"" NetBIOS Name max 15 characters"
		$WPFtxtVMHostnamePrefix.MaxLength = 15 - $WPFcbbVMHostnameNumbering.Text.Length
	})

	$WPFtxtVMHostnamePrefix.Add_GotFocus({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		$_txtLength = $WPFtxtVMHostnamePrefix.Text.Length + $WPFcbbVMHostnameNumbering.Text.Length
		$WPFlblHostnameCount.Content = """=$_txtLength"" NetBIOS Name max 15 characters"
		$WPFtxtVMHostnamePrefix.MaxLength = 15 - $WPFcbbVMHostnameNumbering.Text.Length
		
	})

	$WPFcbbVMHostnameNumbering.Add_SelectionChanged({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.Controls.SelectionChangedEventArgs]$e
		)
		$_txtLength = $WPFtxtVMHostnamePrefix.Text.Length + $WPFcbbVMHostnameNumbering.Text.Length
		$WPFlblHostnameCount.Content = """=$_txtLength"" NetBIOS Name max 15 characters"
		$WPFtxtVMHostnamePrefix.MaxLength = 15 - $WPFcbbVMHostnameNumbering.Text.Length
	})

	$WPFcbbVMHostnameNumbering.Add_GotFocus({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		$_txtLength = $WPFtxtVMHostnamePrefix.Text.Length + $WPFcbbVMHostnameNumbering.Text.Length
		$WPFlblHostnameCount.Content = """=$_txtLength"" NetBIOS Name max 15 characters"
		$WPFtxtVMHostnamePrefix.MaxLength = 15 - $WPFcbbVMHostnameNumbering.Text.Length

	})

	$WPFchkbUpdateHostedMachineID.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFchkbUpdateHostedMachineID.IsChecked -eq $false){
			$WPFcbbXenHypervisorConnection.IsEnabled = $false
			$WPFcbbXDHyp.IsEnabled = $false
			$WPFlblXenHypervisorConnection.IsEnabled = $false
			$WPFlblXenXDHyp.IsEnabled = $false
			$WPFlblXenDeliveryGroup.IsEnabled = $false
			$WPFcbbXenDeliveryGroup.IsEnabled = $false
			$WPFlblXenMachineCatalog.IsEnabled = $false
			$WPFcbbXenMachineCatalog.IsEnabled = $false
			$WPFcmdRefreshXDhyp.IsEnabled = $false
			$WPFcmdRefreshHypervisorConnection.IsEnabled = $false
			$WPFcmdRefreshMachineCatalog.IsEnabled = $false
			$WPFcmdRefreshDeliveryGroup.IsEnabled = $false
		}

		if ($WPFchkbUpdateHostedMachineID.IsChecked -eq $true){
			$WPFcbbXenHypervisorConnection.IsEnabled = $true
			$WPFcbbXDHyp.IsEnabled = $true
			$WPFlblXenHypervisorConnection.IsEnabled = $true
			$WPFlblXenXDHyp.IsEnabled = $true
			$WPFlblXenDeliveryGroup.IsEnabled = $true
			$WPFcbbXenDeliveryGroup.IsEnabled = $true
			$WPFlblXenMachineCatalog.IsEnabled = $true
			$WPFcbbXenMachineCatalog.IsEnabled = $true
			$WPFcmdRefreshXDhyp.IsEnabled = $true
			$WPFcmdRefreshHypervisorConnection.IsEnabled = $true
			$WPFcmdRefreshMachineCatalog.IsEnabled = $true
			$WPFcmdRefreshDeliveryGroup.IsEnabled = $true
		}
	})

	$WPFchkbADCreateComputerAccount.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFchkbADCreateComputerAccount.IsChecked -eq $false){
			$WPFcbbADOU.IsEnabled = $false
			$WPFlblADOU.IsEnabled = $false
			$WPFcmdRefreshADOU.IsEnabled = $false
		}

		if ($WPFchkbADCreateComputerAccount.IsChecked -eq $true){
			$WPFcbbADOU.IsEnabled = $true
			$WPFlblADOU.IsEnabled = $true
			$WPFcmdRefreshADOU.IsEnabled = $true
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

	$WPFchkbADCredToCreateADComputer.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		if ($WPFchkbADCredToCreateADComputer.IsChecked -eq $false){
			$WPFlblADUsername.IsEnabled = $false
			$WPFlblADPasswd.IsEnabled = $false
			$WPFtxtADUsername.IsEnabled = $false
			$WPFtxtADPasswd.IsEnabled = $false
		}

		if ($WPFchkbADCredToCreateADComputer.IsChecked -eq $true){
			$WPFlblADUsername.IsEnabled = $true
			$WPFlblADPasswd.IsEnabled = $true
			$WPFtxtADUsername.IsEnabled = $true
			$WPFtxtADPasswd.IsEnabled = $true
		}
	})



	$WPFcmdRefreshParentVM.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)
		$_ii = $WPFcbbParentVM.SelectedIndex
		readRefreshVMwareParentVM 
		$WPFcbbParentVM.SelectedIndex = $_ii
	})


	$WPFcmdRefreshDatastore.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		$_ii = $WPFcbbVMDatastores.SelectedIndex
		readRefreshVMwareDatastores
		 $WPFcbbVMDatastores.SelectedIndex = $_ii

	})

	$WPFcmdRefreshFolder.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		$_ii = $WPFcbbVMFolders.SelectedIndex
		readRefreshVMwareFolders
		$WPFcbbVMFolders.SelectedIndex =$_ii
	})

	$WPFcmdRefreshXDhyp.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		readRefreshXenDesktopXDHyp
	})


	$WPFcmdRefreshHypervisorConnection.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		readHypervisorConnections
	})

	$WPFcmdRefreshMachineCatalog.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		readRefreshXenBrokerCatalog
	})

	$WPFcmdRefreshDeliveryGroup.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)
				
		readRefreshXenBrokerDesktopGroup
	})

	$WPFcmdRefreshADOU.Add_Click({
		param(
			[Parameter(Mandatory)][Object]$sender,
			[Parameter(Mandatory)][System.Windows.RoutedEventArgs]$e
		)

		#readRefreshADOU
		readRefreshADOUV2
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

	