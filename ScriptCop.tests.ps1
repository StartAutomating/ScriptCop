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
    }

    context 'Dynamic Registration' {
        it 'Can remove a registered rule' {
            Unregister-ScriptCopRule -Name Test-DocumentationQuality
            $(Get-ScriptCopRule |
                Where-Object Name -EQ Test-DocumentationQuality) | should be $null
        }

        it 'Can remove a registered fixer' {
            Unregister-ScriptCopFixer -Name Repair-ModuleManifest
            $(Get-ScriptCopFixer |
                Where-Object Name -EQ Repair-ModuleManifest) | should be $null

        }

        it 'Can remove a registered patrol' {
            Unregister-ScriptCopPatrol -Name Test-Documentation
            $(Get-ScriptCopPatrol |
                Where-Object Name -EQ Test-Documentation) | should be $null
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
