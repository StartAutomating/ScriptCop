function Get-CommandCoverage
{
    <#
    .Synopsis
        Gets Command Coverage
    .Description
        Gets code coverage of the commands within a module.
    .Example
        Get-CommandCoverage
    .Link
        Test-Module
    .Link
        Enable-CommandCoverage
    .Link
        Disable-CommandCoverage
    #>
    [OutputType([PSObject])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Justification="This needs to be global")]
    param(
    # The name of the module that will be instrumented for command coverage
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Alias('Name')]
    [string]
    $Module
    )


    process {
        #region Caculate Command Coverage
        # First, get all functions from the module.
        $moduleCommands = Get-Command -Module $module -commandType Function
        # Then, find the commands that were hit.
        $commandsCovered = @($moduleCommands | Where-Object { $global:CommandCoverage.Contains("$_") } ) # Get the commands
        # Then, find the commands that were not hit.
        $missingCommands = @($moduleCommands | Where-Object { -not $global:CommandCoverage.Contains("$_") } )
        $percentageCommandsCovered = # calculate the % command coverage.
            $commandsCovered.Count / $moduleCommands.Count

        #endregion Caculate Command Coverage

        #region Caculate Parameter Coverage
        $totalParameterCount = # Next, total up the number of parameters
            $moduleCommands |
                ForEach-Object { ([Management.Automation.CommandMetaData]$_).Parameters.Count} |
                Measure-Object -Sum |
                Select-Object -ExpandProperty Sum

        $coveredParameterTotal =
            $commandsCovered |
                ForEach-Object { ([Management.Automation.CommandMetaData]$_).Parameters.Count} |
                Measure-Object -Sum |
                Select-Object -ExpandProperty Sum

        $totalMissedParameters = 0
        $totalCoveredParameters = 0
        $specificCommandCoverage = $commandsCovered | # Next, walk thru each command
            ForEach-Object {
                $params = ([Management.Automation.CommandMetaData]$_).Parameters
                $coverageData = @($global:CommandCoverage["$_"]) # find coverage data related to that command
                # and see what parameters were missed.
                $missedParameters = @($params.Keys | Where-Object { -not ($coverageData -eq $_) })
                $totalMissedParameters += $missedParameters.Count
                $coveredParams = @($coverageData | Group-Object -NoElement |
                        Select-Object Name, @{
                            Expression={$_.Count}
                            Name='TimesHit'
                        }) # Then summarize how often each parameter was used.
                $totalCoveredParameters += $coveredParams.Count
                # Pack all of this information into a property bag for the command.
                $o = New-Object PSOBject -Property @{
                    Command = $_
                    CoveredParameters = $coveredParams
                    MissedParameters = $missedParameters
                    PercentageParameterCoverage =
                        try {
                            $coveredParams.Count * 100 / ($coveredParams.Count + $missedParameters.Count )
                        } catch { 1 }
                }

                # and decorate it as a 'ScriptCop.Command.Coverage'
                $o.pstypenames.clear()
                $o.pstypenames.add('ScriptCop.Command.Coverage')

                $o
            }
        #endregion Caculate Parameter Coverage


        $commandCoverageOutput = New-Object PSObject -Property @{
            CommandsCovered = $commandsCovered
            CoveredParameterTotal = $coveredParameterTotal
            CoverageData = $specificCommandCoverage
            PercentageCommandCoverage = $percentageCommandsCovered * 100
            NumberOfCommandsCovered = $commandsCovered.Count
            TotalNumberOfCommands = $moduleCommands.Count
            NumberOfParametersCovered = $totalCoveredParameters
            OverallParameterCoverage = $totalCoveredParameters * 100 / $totalParameterCount
            ParameterCoverageInCoveredCommands = $totalCoveredParameters * 100 / $coveredParameterTotal
            MissingCommands = $missingCommands
            TotalNumberOfParameters = $totalParameterCount
        }

        $commandCoverageOutput.pstypenames.clear()
        $commandCoverageOutput.pstypenames.add('ScriptCop.Command.Coverage.Report')
        $commandCoverageOutput

    }
}
