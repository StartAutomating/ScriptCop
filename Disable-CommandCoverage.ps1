function Disable-CommandCoverage
{
    <#
    .Synopsis
        Disables command coverage for a module
    .Description
        Disables command coverage tracing for a module
    .Example
        Disable-CommandCoverage
    .Link
        Enable-CommandCoverage
    #>
    [OutputType([Nullable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Justification="This needs to be global")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This clears a global")]
    param(
    # The name of the module that will be instrumented for command coverage
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Alias('Name')]
    [string]
    $Module
    )

    process {
        #region Get Commands and Remove Breakpoints
        $moduleCommands = Get-Command -Module $module -commandType Function | ForEach-Object { $_.Name }
        Get-PSBreakpoint -Command $moduleCommands |
            Remove-PSBreakpoint
        $Global:CommandCoverage = $null
        #endregion Get Commands and Remove Breakpoints
    }
}
