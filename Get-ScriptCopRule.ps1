function Get-ScriptCopRule
{
    <#
    .Synopsis
        Gets all of the script cop rules.
    .Description
        Gets all of the script cop rules, and the relative path to the file defining the rule
    .Example
        Get-ScriptCopRule
    .Link
        Test-Command
    #>

    [OutputType('ScriptCopRule')]
    param()
    
    begin {
        #region Initialize Collection
        if (-not $script:ScriptCopRules) {
            $script:ScriptCopRules = @{
                TestCommandInfo = @()
                TestCmdletInfo = @()
                TestScriptInfo = @()
                TestFunctionInfo = @()
                TestApplicationInfo=  @()
                TestModuleInfo = @()
                TestScriptToken = @()
                TestHelpContent = @()
            }
        }
        #endregion Initialize Collection
    }
    
    process {
        #region Walk Collection
        $script:ScriptCopRules | 
            Select-Object -ExpandProperty Values | 
            Select-Object -Unique |
            ForEach-Object { $_ } |
            ForEach-Object { $_ } |
            Select-Object Name, @{
                Label='File'
                Expression={
                    if ($_.Path){ $_.Path.Replace("$psScriptRoot$([IO.Path]::DirectorySeparatorChar)", "") } else { $_.ScriptBlock.File.Replace("$psScriptRoot$([IO.Path]::DirectorySeparatorChar)", "") } 
                    
                }
            } | 
            ForEach-Object {
                $_.psObject.typenames.clear()
                $null = $_.psObject.typenames.Add('ScriptcopRule')
                $_
            }
        #endregion Walk Collection
    }
} 
 
