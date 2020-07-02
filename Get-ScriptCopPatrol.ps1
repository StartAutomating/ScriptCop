function Get-ScriptCopPatrol
{
    <#
    .Synopsis
        Gets the currently defined script cop patrols.
    .Description
        Gets the currently defined script cop patrols.

        A Script Cop patrol groups a number of rules to help easily fix a set of issues.
    .Example
        Get-ScriptCopPatrol
    .Link
        Register-ScriptCopPatrol
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    [OutputType([PSObject])]
    param(
    # The name of the patrol.
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName='Name')]
    [string]
    $Name
    )
    begin {
        # Declare Control Cache if it Doesn't Exist
        if (-not ($script:ScriptCopPatrols)) {
            $script:ScriptCopPatrols = @{}
        }
    }

    process {
        if ($psCmdlet.parameterSetName -eq 'Name' -and $script:ScriptCopPatrols[$name]) {
            #region Create a PSObject to hold the results
            $result = New-Object PSObject
            $result.psObject.Properties.add(
                (New-Object Management.Automation.PSNoteProperty "Name", $Name)
            )
            $result.psObject.Properties.add(
                (New-Object Management.Automation.PSNoteProperty "Description",
                    $script:ScriptCopPatrols[$name].Description)
            )
            $result.psObject.Properties.add(
                (New-Object Management.Automation.PSNoteProperty "CommandRule",
                    $script:ScriptCopPatrols[$name].CommandRule)
            )
            $result.psObject.Properties.add(
                (New-Object Management.Automation.PSNoteProperty "ModuleRule",
                    $script:ScriptCopPatrols[$name].ModuleRule)
            )

            $result
            #endregion
        } elseif ($psCmdlet.parameterSetName -eq 'All') {
            #region Use Recursion to get the PSObject for each patrol
            $script:ScriptCopPatrols.Keys |
                Get-ScriptCopPatrol
            #endregion
        }
    }

}
