$Script:bamMgmt = $null
$Script:bamQuery = $null

function Connect-WebServices {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$ComputerName
    )
    process {
        $Script:bamMgmt = New-WebServiceProxy -Uri "http://$ComputerName/BAM/BAMManagementService/BAMManagementService.asmx" -UseDefaultCredential -ErrorAction Stop
        $Script:bamQuery = New-WebServiceProxy -Uri "http://$ComputerName/BAM/BAMQueryService/BamQueryService.asmx" -UseDefaultCredential -ErrorAction Stop
    }
}

function Get-InstanceData {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$View,
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Activity,
        [Parameter(Mandatory = $true)]
        [string[]]$Columns,
        [Parameter()]
        [int]$Timeout = 15
    )
    process {
        $query = [Microsoft.PowerShell.Commands.NewWebserviceProxy.AutogeneratedTypes.WebServiceProxy3ryService_BamQueryService_asmx.InstanceQuery]::new()
        $query.SelectClauses = $Columns
        return $Script:bamQuery.GetInstanceData($View, $Activity, $query, $Timeout)
    }
}

function Get-ViewActivities {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$View
    )
    begin {
        $activity = @{Name = "Activity"; Expression = {$xml.SelectSingleNode("//*[local-name()='Activity'][@`ID='$($_.ActivityRef)']/@`Name")."#text"}}
        $columns = @{Name = "Columns"; Expression = {$_.ChildNodes.Name}}
    }
    process {
        $xml = [xml]$Script:bamMgmt.GetViewDetailsAsXml($View)
        return $xml.BAMDefinition.View.ActivityView | Select-Object -Property $activity, $columns
    }
}

function Get-ViewsSummary {
    [CmdletBinding()]
    param ()
    process {
        return $Script:bamMgmt.GetViewSummaryForCurrentUser().View
    }
}

Connect-WebServices