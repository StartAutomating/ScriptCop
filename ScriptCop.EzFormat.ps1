[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Formatters can Write-Hosts")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="PSScriptAnalyzer can't see the reference")]
param()
$moduleRoot = Get-Module "ScriptCop" | Split-Path

if (-not $moduleRoot) { return }


$formatting = @()

$formatting += Write-FormatView -TypeName ScriptCopError -Property Problem, ItemWithProblem -Wrap -GroupByProperty Rule
<#$formatting += Write-FormatView -TypeName ScriptCop.Test.Pass.Output -Action {
$writeColor = if ($_.Passed) {
    "DarkGreen"
} else {
    "Red"
}
$testStatus = if ($_.Passed) {
    "--- Passed --- "
} else {
    "*** Failed *** "
}

if (-not ($request -and $response)) {


$msg = " $($_.TestPass)"

$testStatus = $testStatus.PadLeft($host.ui.RawUI.BufferSize.Width - $msg.Length)
Write-Host " "
Write-Host "${Msg}$testStatus" -ForegroundColor $writeColor -NoNewline
Write-Host " "
$null= ($_.Results | Out-String)


''
} else {
"<div style='background-color:$writeColor;color:#ffffff'>
    <div style='float:left;width:20%;font-size:1.22em'>
        <h3>
          $($_.TestPass)
        </h3>
    </div>
    <div style='float:right;width:20%;text-align:right;'>
        <span style='color:#ffffff;font-size:1.22em'>$testStatus</span>
    </div>
    <br style='clear:both'/>
    <div style='width:80%;margin-left:20%'>
        $($_.Results | Out-html)
    </div>
</div>
"
}
}
$formatting += Write-FormatView -TypeName ScriptCop.Test.Output  -action {
    $writeColor = if ($_.Passed) {
        "DarkGreen"
    } else {
        "Red"
    }
    $testStatus = if ($_.Passed) {
        "--- Passed --- "
    } else {
        "*** Failed *** "
    }

if (-not ($Request -and $response)) {

    $msg = "   $($_.TestCase)"
    $testStatus = $testStatus.PadLeft($host.ui.RawUI.BufferSize.Width - $msg.Length)
    Write-Host "${Msg}$testStatus" -ForegroundColor $writeColor -NoNewline

    if ($_.Errors) {
Write-Host "$($_.Errors |Out-String)" -ForegroundColor $writeColor
    }
    ''

} else {
"
<div style='float:left;width:80%;font-size:1.11em'>
    <h4>
        $($_.TestCase)
    </h4>
    $(if ($_.Errors) {
"<pre>
$($_.Errors | Out-String)
</pre>"
    })
</div>
<div style='float:right;width:20%;font-size:1.11em;text-align:right'>
    <span style='font-size:1.11em'>$testStatus</span>
</div>
<br style='clear:both' />
"
}
}
#>
$formatting += Write-FormatView -TypeName ScriptCop.Test.Pass.Summary -Action {
$writeColor = if ($_.PercentPassingTestCases -eq 100) {
    "DarkGreen"
} elseif ($_.PercentPassingTestCases -ge 75)  {
    "DarkYellow"
} else {
    "Red"
}
    if (-not ($request -and $response)) {

$msg = "$($_.Module)"

$testStatus = [Math]::round($_.PercentPassingTestCases, 2) + " % Passed (Test Cases)"
$testStatus = $testStatus.PadLeft($host.ui.RawUI.BufferSize.Width - $msg.Length)
Write-Host "$msg{$testStatus}" -ForegroundColor $writecolor
Write-Host " "

$totalTestCasesMsg = "Total Test Cases    : $($_.TotalTestCases)".PadRight(($host.ui.Length.rawui.buffersize / 2) -1 )
$passingTestCasesMsg = "$($_.PassingTestCases) ( $([Math]::Round($_.PercentPassingTestCases,2))% Passed".PadLeft(($host.ui.Length.rawui.buffersize / 2) -1)
$totalTestPassesMsg = "Total Test Passes : $($_.TotalTestPasses)".PadRight(($host.ui.Length.rawui.buffersize / 2) -1)
$passingTestPassesMsg = "$($_.PassingTestPasses) $([Math]::Round($_.PercentPassingTestPasses,2))% Passed".PadLeft(($host.ui.Length.rawui.buffersize / 2) -1)


Write-Host "${totalTestCasesMsg}${PassingTestCasesMsg}" -ForegroundColor $writecolor
Write-Host "${totalTestPassesMsg}${PassingTestPassesMsg}" -ForegroundColor $writecolor
Write-Host " "

    } else {
$summary = $_
$passingTestCasesGraphObject = New-Object PSObject |
Add-Member NoteProperty Passed $($summary.PassingTestCases) -Force -PassThru |
Add-Member NoteProperty Failed $($summary.TotalTestCases - $summary.PassingTestCases) -Force -PassThru


$passingTestPassesGraphObject =
New-Object PSObject |
Add-Member NoteProperty Passed $($summary.PassingTestPasses) -Force -PassThru |
Add-Member NoteProperty Failed $($summary.TotalTestPasses - $summary.PassingTestPasses) -Force -PassThru
"
<div>
    <h2>$($_.Module)</h2>
    <div style='width:40%;margin-left:5%;margin-right:5%;float:left;'>
        $($passingTestCasesGraphObject | Out-HTML -AsPieGraph -ColorList "#006400", "#800000" -GraphWidth 250 -GraphHeight 250 -Header "Test Cases")
    </div>
    <div style='width:40%;margin-left:5%;margin-right:5%;float:left;'>
        $($passingTestCasesGraphObject | Out-HTML -AsPieGraph -ColorList "#006400", "#800000" -GraphWidth 250 -GraphHeight 250 -Header "Test Passes")
    </div>
    <br style='clear:both' />
</div>
"
    }
}
$formatting += Write-FormatView -TypeName ScriptCop.Command.Coverage.Report -Action {
    if (-not ($request -and $response)) {
        $_ | Select-Object -Property PercentageCommandCoverage,
            NumberOfCommandsCovered,
            TotalNumberOfCommands,
            OverallParameterCoverage,
            ParameterCoverageInCoveredCommands,
            NumberOfParametersCovered,
            TotalNumberOfParameters |
            Out-Host
        ''
    } else {
$summary = $_
$overallCommandCoverage = New-Object PSObject |
Add-Member NoteProperty Covered $($summary.NumberOfCommandsCovered) -Force -PassThru |
Add-Member NoteProperty Uncovered $($summary.TotalNumberOfCommands - $summary.NumberOfCommandsCovered) -Force -PassThru


$coveredCommandParameterCoverage =
New-Object PSObject |
Add-Member NoteProperty Covered $($summary.NumberOfParametersCovered) -Force -PassThru |
Add-Member NoteProperty Uncovered $($summary.CoveredParameterTotal - $summary.NumberOfParametersCovered) -Force -PassThru


$totalParameterCoverage =
New-Object PSObject |
Add-Member NoteProperty Covered $($summary.NumberOfParametersCovered) -Force -PassThru |
Add-Member NoteProperty Uncovered $($summary.TotalNumberOfParameters - $summary.NumberOfParametersCovered) -Force -PassThru
"
<div>
    <h3>$($_.Module) - Command Coverage</h3>
    <div style='width:30%;margin-left:2.5%;margin-right:2.5%;float:left;'>
        $($overallCommandCoverage | Out-HTML -AsPieGraph -ColorList "#006400", "#800000" -GraphWidth 200 -GraphHeight 200 -Header "Overall Command Coverage")
    </div>
    <div style='width:30%;margin-left:2.5%;margin-right:2.5%;float:left;'>
        $($coveredCommandParameterCoverage | Out-HTML -AsPieGraph -ColorList "#006400", "#800000" -GraphWidth 200 -GraphHeight 200 -Header "Parameter Coverage (of Covered commands)")
    </div>
    <div style='width:30%;margin-left:2.5%;margin-right:2.5%;float:left;'>
        $($totalParameterCoverage | Out-HTML -AsPieGraph -ColorList "#006400", "#800000" -GraphWidth 200 -GraphHeight 200 -Header "Overall Parameter Coverage")
    </div>
    <br style='clear:both' />
</div>
"
    }
}

$formatting += @(Get-ChildItem -Path (Join-Path $moduleRoot 'Formatting') | Import-FormatView)

$formatting | Out-FormatData | Set-Content "$moduleRoot\ScriptCop.Format.ps1xml"

