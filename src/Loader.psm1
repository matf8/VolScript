$ErrorActionPreference = "Stop"


# ============================================================
# Session bootstrap
# ============================================================

function Import-VolScriptModules
{
    param(
        [switch]$Reload
    )

    $Params = @{}

    if ($Reload)
    {
        $Params.Force = $true
    }

    $ModulePaths = @(
        "Core\Core.psm1"
        "Config\Config.psm1"
        "Utils\MenuInput.psm1"
        "Utils\ArgValidate.psm1"
        "Utils\Instance.psm1"
        "UI\UI.psm1"
        "Actions\Actions.psm1"
        "Config\ConfigEditor.psm1"
    )

    foreach ($RelativePath in $ModulePaths)
    {
        Import-Module `
            (Join-Path $PSScriptRoot $RelativePath) `
            -Global `
            @Params
    }
}


Export-ModuleMember -Function Import-VolScriptModules
