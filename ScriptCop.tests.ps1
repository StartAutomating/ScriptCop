#requires -Module Pester, ScriptCop

describe ScriptCop {
    context 'Static Analysis' {
        it 'Can enforce rules' {
            function foo {

            }

            Get-command foo |
                Test-Command -Rule Test-CommandNamingConvention |
                Select-Object -ExpandProperty Problem |
                should -BeLike *StandardVerb-CustomNoun*
        }

        it 'Can exlcude rules' {
            function foo {

            }

            Get-command foo |
                Test-Command -Rule Test-CommandNamingConvention -ExcludedRule Test-CommandNamingConvention |
                should -be $null
        }

        it 'Can run groups of rules, or Patrols' {
            function foo {
            }

            Get-Command foo |
                Test-Command -Patrol Test-Documentation |
                    Select-Object -First 1 -ExpandProperty Problem |
                    should -BeLike *examples*
        }
    }

    context 'Auto-Repair' {
        it 'Will automatically fix some problems' {
            $tempModulePsd1 = @'
@{
    ModuleVersion = '0.1'
    Description = 'A Module'
}
'@

            $tempModuleName = "TempModule$(Get-Random)"

            $tempModuleRoot =
                if ($PSVersionTable.OS -and $PSVersionTable.OS -notlike '*Windows*') {
                    Join-Path '/tmp' $tempModuleName
                } else {
                    Join-Path $env:Temp $tempModuleName
                }

            $tempModulePath = Join-Path $tempModuleRoot "$tempModuleName.psd1"
            $null = New-item -ItemType File -Force -Path $tempModulePath
            $tempModulePsd1 | Set-Content $tempModulePath

            $importedModule = Import-Module $tempModulePath -Force -PassThru
            $importedModule|
                Test-Command |
                Repair-Command -WarningAction SilentlyContinue

            $newText = [IO.File]::ReadAllText($tempModulePath) #  | should -Not -Be $tempModulePsd1
            if ($newText -eq $tempModulePath) {
                throw "Expected Repair-Command to change things.  $tempModulePath was unchanged."
            }
            $importedModule | Remove-Module
            Remove-Item $tempModulePath -Recurse -Force
        }
    }


    context 'Dynamic Registration' {
        it 'Can remove a registered rule' {
            Unregister-ScriptCopRule -Name Test-DocumentationQuality
            $(Get-ScriptCopRule |
                Where-Object Name -EQ Test-DocumentationQuality) | should -Be $null
        }

        it 'Can remove a registered fixer' {
            Unregister-ScriptCopFixer -Name Repair-ModuleManifest
            $(Get-ScriptCopFixer |
                Where-Object Name -EQ Repair-ModuleManifest) | should -Be $null

        }

        it 'Can remove a registered patrol' {
            Unregister-ScriptCopPatrol -Name Test-Documentation
            $(Get-ScriptCopPatrol |
                Where-Object Name -EQ Test-Documentation) | should -Be $null
        }
    }


    context 'Self-Testing' {
        it 'Can reload and test itself' {
            $theModule = Get-Module ScriptCop
            $theModuleRoot = $theModule.Path.Substring(0, $theModule.Path.LastIndexOf([IO.Path]::DirectorySeparatorChar))
            $theModuleRoot = $theModuleRoot + [IO.Path]::DirectorySeparatorChar + 'ScriptCop.psd1'
            Import-Module $theModuleRoot -Global -Force -PassThru |
                   Test-Module -GetCommandCoverage
        }
    }

}
