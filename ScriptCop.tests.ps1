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

    context 'Testing' {
        it 'Can reload and test itself' {
            $theModule = Get-Module ScriptCop
            $theModuleRoot = $theModule.Path.Substring(0, $theModule.Path.LastIndexOf([IO.Path]::DirectorySeparatorChar))
            $theModuleRoot = $theModuleRoot + [IO.Path]::DirectorySeparatorChar + 'ScriptCop.psd1'
            Import-Module $theModuleRoot -Global -Force -PassThru |
                   Test-Module
        }
    }
}
