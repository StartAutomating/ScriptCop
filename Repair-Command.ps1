function Repair-Command
{
    <#
    .Synopsis
        Repair-Command attempts to fix your scripts.
    .Description
        Repair-Command will use a set of repair scripts to attempt to automatically
        resolve an issue uncovered with ScriptCop.

        Repair-Command will take all issues thru the pipeline, and will output
        an object with the Rule, Problem, ItemWithProblem, and WasFixed.
    .Link
        Test-Command
    .Example
        Get-Module MyModule | Test-Command | Repair-Command
    #>
    [OutputType([Nullable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "holdup", Justification="PSScriptAnalyzer false positive.")]
    param(
    # The Rule that flagged the problem
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        if ($_ -is [Management.Automation.CommandInfo]) {
            return $true
        }
        if ($_ -is [Management.Automation.PSModuleInfo]) {
            return $true
        }

        throw 'Must be a CommandInfo or a PSModuleInfo'
    })]
    [PSObject]$Rule,

    # The Problem
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.ErrorRecord]
    $Problem,

    # The Item with the Problem
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        if ($_ -is [Management.Automation.CommandInfo]) {
            return $true
        }
        if ($_ -is [Management.Automation.PSModuleInfo]) {
            return $true
        }

        throw 'Must be a CommandInfo or a PSModuleInfo'
    })]
    [PSObject]$ItemWithProblem,

    # If set, only fixers which have indicated they will not require user interaction will be run.
    [Switch]$NotInteractive
    )

    #region Initialize The List of Problems
    begin {

        # Make a quick pair of functions to help people output the right thing
        function CouldNotFixProblem
        {
            param([string]$ErrorId)

            $info = @{
                WasIdentified=$false
                CouldFix=$false
                WasFixed=$false
                ErrorId = $errorID
                Problem=$Problem
                ItemWithProblem=$ItemWithProblem
                Rule=$Rule
                FixRequiresRescan=$false
            }

            New-Object PSObject -Property $Info
        }

        function TriedToFixProblem
        {
            param([string]$ErrorId,
            [Switch]$FixRequiresRescan)

            $stillHasThisProblem = $ItemWithProblem |
                Test-Command -Rule "$Rule" |
                Where-Object {
                    $_.Problem.FullyQualifiedErrorId -like "$ErrorId*"
                }

            New-Object PSObject -Property @{
                WasIdentified = $true
                CouldFix = $true
                WasFixed = -not ($stillHasThisProblem -as [bool])
                ErrorId = $errorId
                Problem=$Problem
                ItemWithProblem=$ItemWithProblem
                Rule=$Rule
                FixRequiresRescan=$FixRequiresRescan
            }
        }


        # Declare a list to hold the problems (for speed)
        $problems = New-Object Collections.ArrayList


    }
    #endregion

    #region Add Each Problem to the List
    process {
        $null = $problems.Add((New-Object PSObject -Property $psBoundParameters))
        Write-Verbose "Processing
$($_ | Out-String)
"
    }
    #endregion


    end {
        try {
            #region Fix the Problems That You Can
            $script:ScriptCopFixers |
                ForEach-Object -Begin {
                    $holdUp = $false
                } {
                    $fixer = $_

                    $problems |
                        & $fixer |
                        ForEach-Object {
                            $fix = $_
                            if ($fix.FixRequiresRescan) {
                                $holdUp = $true
                            }
                            throw $holdup
                        }

                    trap
                    {
                        if (-not (Get-Variable -Scope 1 -Name holdUp -ErrorAction SilentlyContinue)) {
                            throw $_
                        } else { break }
                    }
                }
        } catch {
            if ($_.InvocationInfo.Line -like '*throw $holdup*') {
                Write-Warning "Fixed $($fix.Problem) on $($Fix.ItemWithProblem), but that fix changed files, so you must rescan"
                return
            } else {
                Write-Error -ErrorRecord $_
                return
            }
        }
        #endregion
    }
}
