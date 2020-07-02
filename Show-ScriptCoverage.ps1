function Show-ScriptCoverage
{
    <#
    .Synopsis
        Shows script coverage for a file or series of files
    .Description
        This adds a breakpoint to each line of a script file and then runs the files or runs a command
        This will output what lines within the file were hit
    .Example
        # Start out by making en empty directory
        New-Item .\TestDirectory -ItemType Directory -Force

        # Now let's create two scripts.  The first script has
        # a 50/50 chance of saying "Hello World" or "Goodbye World"
        '
        if ((0,1 | Get-Random)) {
            "Hello World"
        } else {
            "Goodbye World"
        }
        ' |
            Out-File .\TestDirectory\Chance.ps1

        # The second script will say Hello World or Goodbye World depending
        # on if it was passed a parameter
        '
        param ($a)
        if ($a) {
            "Hello World"
        } else {
            "Goodbye World"
        }
        ' > .\TestDirectory\Parameter.ps1

        # We pipe the output of Get-ChildItem into Show-ScriptCoverage.  This will run
        # each of the scripts, and return a property bag containing:
        # - The name of the file that is being instrumented
        # - The output of the script
        # - Any errors encountered running the script
        # - A visual representation of what lines in the script were hit
        # By Piping it into Select-Object and expanding the coverage property, we'll
        # just see what lines were hit
        Get-ChildItem .\TestDirectory |
            Show-ScriptCoverage |
            Select-Object -ExpandProperty Coverage

        # Cool.  Now let's be polite and clean up the files we created
        Remove-Item .\TestDirectory -Recurse -Force
    .Link
        Test-Module
    .Link
        Enable-CommandCoverage
    .Link
        Disable-CommadCoverage
    #>
    [CmdletBinding(DefaultParameterSetName="NoArguments")]
    [OutputType([PSObject])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Justification="This needs to be global")]
    param(
    # The file to instrument
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Alias('FullName')]
    [Alias('Path')]
    [String]
    $File,

    # The arguments to pass to the script file or command
    [Parameter(ParameterSetName='ArgumentList',
        HelpMessage='The arguments to pass to the script',
        ValueFromRemainingArguments=$true)]
    [PSObject[]]
    $Args,

    # A dictionary of parameters to pass to the file
    [Parameter(ParameterSetName='ParameterDictionary',
        HelpMessage='A hashtable of parameters to to pass to the script')]
    [Hashtable]
    $Parameter,

    # If this is set, the scripts will not be dot-sourced.  Otherwise, all scripts
    # will be dot-sourced
    [Switch]
    $DoNotDotSource,

    # The command you are going to run.
    [ScriptBlock]
    $Command = {}
    )


    begin {
        $breakpoints = New-Object System.Collections.ArrayList
        $ScriptContents = @{}
    }

    process {
        $WarningPreference = "SilentlyContinue"

        $scriptContent = @(Get-Content -ErrorAction SilentlyContinue $file)
        $realFile = Resolve-Path $file
        $ScriptContents["$RealFile"] = $ScriptContent
        #region Prepare Breakpoints
        for ($i = 1; $i -le $scriptContent.Count; $i++)
        {
            if ($scriptContent[$i - 1].Trim())
            {
                $sb = [ScriptBLock]::Create({
if (-not ($global:ScriptCoverageProfiler)) {
    $global:ScriptCoverageProfiler = @{}
}
                }.ToString() + "
if (-not (`$global:ScriptCoverageProfiler[`"$file.$i`"])) {
    `$global:ScriptCoverageProfiler[`"$file.$i`"] = @()
}
`$global:ScriptCoverageProfiler[`"$file.$i`"] += Get-Date
continue
")
                $breakpoints +=
                    Set-PSBreakpoint -ErrorAction SilentlyContinue -Script $file -Line $i -action $sb

            }
        }
        #endregion Prepare Breakpoints
        if (-not "$Command") {
            # This section must remain in this area, even though the code is duplicated in end
            # If it is not, then the arguments will not be correctly passed down to the script files
            # you are instrumenting
            if ($DoNotDotSource) {
                if ($psCmdlet.ParameterSetName -eq "ArgumentList") {
                    $error.Clear()
                    $output = & $realFile @args
                    $errors = @($error)
                } elseif ($psCmdlet.ParameterSetName -eq "ParameterDictionary") {
                    $error.Clear()
                    $output = & $realFile @parameter
                    $errors = @($error)
                } else {
                    $error.Clear()
                    $output = & $realFile
                    $errors = @($error)
                }
            } else {
                if ($psCmdlet.ParameterSetName -eq "ArgumentList") {
                    $error.Clear()
                    $output = . $realFile @args
                    $errors = @($error)
                } elseif ($psCmdlet.ParameterSetName -eq "ParameterDictionary") {
                    $error.Clear()
                    $output = . $realFile @parameter
                    $errors = @($error)
                } else {
                    $error.Clear()
                    $output = . $realFile
                    $errors = @($error)
                }
            }
            $linesHit = @{}

            Get-PSBreakpoint -Script $realFile |
                Where-Object { $_.HitCount -and $_.Line} |
                ForEach-Object {
                    $LinesHit[$_.Line] = '*'
                }

            $PercentCovered = $linesHit.Count * 100/ $scriptContent.Count


            $scriptCoverageObject =
                New-Object PSObject -Property @{
                    Output = $Output
                    Errors = $Errors
                    File = "$RealFile"
                    PercentCovered = $PercentCovered
                    Coverage = for ($i = 1; $i -le $scriptContent.Count; $i++) {
                        "{0,2} : {1,1} : {2}" -f $i,$linesHit[$i],$scriptContent[$i -1]
                    }
                }
            $scriptCoverageObject.pstypenames.clear()
            $scriptCoverageObject.pstypenames.add('ScriptCoverage')
            $scriptCoverageObject
        } else {

        }

    }
    end {
        if ("$command") {
            # This section must remain in this area, even though the code is duplicated in end
            # If it is not, then the arguments will not be correctly passed down to the script files
            # you are instrumenting

            if (-not $DoNotDotSource) {
                foreach ($realFile in $ScriptContents.Keys) {
                    . $realFile
                }
            }
            if ($psCmdlet.ParameterSetName -eq "ArgumentList") {
                $error.Clear()
                $output = & $Command @args
                $errors = @($error)
            } elseif ($psCmdlet.ParameterSetName -eq "ParameterDictionary") {
                $error.Clear()
                $output = & $Command @parameter
                $errors = @($error)
            } else {
                $error.Clear()
                $output = & $Command
                $errors = @($error)
            }

            foreach ($realFile in $ScriptContents.Keys) {
                $linesHit = @{}

                Get-PSBreakpoint -Script $realFile |
                    Where-Object { $_.HitCount -and $_.Line} |
                    ForEach-Object {
                        $LinesHit[$_.Line] = '*'
                    }

                New-Object PSObject -Property @{
                    Output = $Output
                    Errors = $Errors
                    File = "$realFile"
                    Coverage = for ($i = 1; $i -le $scriptContents["$realFile"].Count; $i++) {
                        "{0,4} : {1,1} : {2}" -f $i,$linesHit[$i],$scriptContents["$realFile"][$i -1]
                    }
                }
            }
        } else {


        }


        $WarningPreference = "Continue"
        $breakpoints |
             Remove-PSBreakpoint -ErrorAction SilentlyContinue

    }
}
