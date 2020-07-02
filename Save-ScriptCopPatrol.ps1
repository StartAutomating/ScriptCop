function Save-ScriptCopPatrol
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PSScriptAnalyzer False Positives")]
    param(
    # The name of the scriptcop patrol
    [Parameter(Mandatory=$true,
        ParameterSetName='Name',
        ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,

    # If set, will save to a string, instead of the patrols directory
    [switch]$ToString
    )

    process {
        Get-ScriptCopPatrol -Name $Name |
            ForEach-Object {

                $commandRuleChunk = "'" + (($_.CommandRule | Select-Object -Unique) -join "',
        '") + "'"
                $moduleRuleChunk = "'" + (($_.ModuleRule | Select-Object -Unique) -join "',
        '") + "'"


$patrolPsd1 = @"
# ScriptCop Patrol File for $Name
# Generated on $($dt=Get-Date;$dt.ToLongDateString() + " " + $dt.ToLongTimeString())
@{
    CommandRule = $commandRuleChunk
    ModuleRule = $moduleRuleChunk
    Description = '$($_.Description)'
}
"@

                if ($ToString) { return $patrolPsd1 }
                [IO.File]::WriteAllText("$psScriptRoot\Patrols\${Name}.patrol.psd1", $patrolPsd1)
            }
    }
}
