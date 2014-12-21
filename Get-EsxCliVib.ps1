﻿<#
.SYNOPSIS
	Get details on a specific ESXi VIB
.DESCRIPTION
	Get details on a specific ESXi VIB.

	This can be usefule if you are looking for version information about a given package on an ESXi host.

	This script/function is best utilized when sending a host object to it via the pipeline; see examples for more detail.
.INPUTS
	VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl
.PARAMETER VMHost
	Name of ESXi host
.PARAMETER VIBName
	Name of vib package you wish to query detail for
.EXAMPLE
	PS C:\> Get-VMHost | .\Get-EsxCliVib -VIBName hp-ams
.EXAMPLE
	PS C:\> Get-VMHost esxihost01.company.com | .\Get-EsxCliVib -VIBName hp-ams

Host             : esxihost01.company.com
Name             : hp-ams
Version          : 550.10.0.1-07.1198610
Vendor           : Hewlett-Packard
InstallDate      : 2014-10-03
ID               : Hewlett-Packard_bootbank_hp-ams_550.10.0.1-07.1198610
CreationDate     : 2014-09-09
Status           :
HostVersion      : 5.5.0
HostVersionBuild : 1892794
HostMfg          : HP
HostModel        : ProLiant BL460c Gen8

.NOTES
	20141002	K. Kirkpatrick		[+] Created
	20141003	K. Kirkpatrick		[+] Added CBH (comment based help)
#>

[CmdletBinding(DefaultParameterSetName = 'Default',
			   PositionalBinding = $true)]
param
(
	[Parameter(ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   Position = 0)]
	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]$VMHost,
	
	[Parameter(Mandatory = $true,
			   ValueFromPipeline = $false,
			   ValueFromPipelineByPropertyName = $false,
			   Position = 1)]
	[string]$VIBName
)

Begin {
	#Requires -Version 3
	
	# clear/set final $result variable
	$result = @()
}# begin

Process {
	
	try {
		Write-Verbose -Message "Working on $($_.Name)..."
		
		# Clear/set variables
		$esxcli = $null
		$softwareList = $null
		
		# Assign vmhost query objects to a variable to be called later
		$esxcli = Get-EsxCli -VMHost $VMHost
		$softwareList = $esxcli.software.vib.list() | Where-Object { $_.Name -like "$VIBName" }
		
		# get uptime details
		$bootTime = ($VMHost | Get-View).runtime.boottime
		$calcUptime = ((Get-Date) - $bootTime)
		
		# Create custom object to store host/vib information - use 'automatic foreach' notation (.) to call the detail for each property
		$objHpVib = [PSCustomObject] @{
			Host = $_.Name
			VibName = $softwareList.Name
			VibVersion = $softwareList.Version
			VibVendor = $softwareList.Vendor
			VibInstallDate = $softwareList.InstallDate
			VibID = $softwareList.ID
			VibCreationDate = $softwareList.CreationDate
			VibStatus = $softwareList.Status
			HostUptimeDays = $calcUptime.Days
			HostVersion = $_.Version
			HostVersionBuild = $_.Build
			HostMfg = $_.Manufacturer
			HostModel = $_.Model
		}# $objHpVib
		
		# Send collection detail for current object to the final $result variable
		$result += $objHpVib
	} catch {
		Write-Warning -Message "Error gathering detail from $VMHost"
		
		# clear/set the $colError array
		$colError = @()
		
		# create new object to store error detail
		$objError = New-Object -TypeName psobject -Property @{
			Host = $_.Name
			Status = "$_"
		}# $objError
		
		# send collection detail to final $result variable
		$result += $objError
		
	}# try/catch
}# process

End {
	# call final result - output from the console can be formatted using regular export cmdlets (Export-Csv; Out-Gridview; Format-Table; etc.)
	$result 
}# end