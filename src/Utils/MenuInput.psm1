$ErrorActionPreference = "Stop"


function Test-VolScriptMenuChoice
{
    param(
        [Parameter(Mandatory)]
        [string]$Choice,

        [Parameter(Mandatory)]
        [string[]]$ValidChoices
    )

    if ([string]::IsNullOrWhiteSpace($Choice))
    {
        return $false
    }

    $Normalized =
        $Choice.Trim().ToUpper()

    $Valid = @(
        $ValidChoices |
        ForEach-Object { $_.ToUpper() }
    )

    return ($Valid -contains $Normalized)
}


function Read-VolScriptMenuChoice
{
    param(
        [Parameter(Mandatory)]
        [string[]]$ValidChoices,

        [string]$Prompt = "  Select option"
    )

    Write-Host $Prompt -NoNewline
    Write-Host ": " -NoNewline

    while ($true)
    {
        $Key =
            [Console]::ReadKey($true)

        if ($Key.Key -eq [ConsoleKey]::Enter)
        {
            Write-Host ""

            continue
        }

        $Choice = [string]$Key.KeyChar

        if (-not (Test-VolScriptMenuChoice `
            -Choice $Choice `
            -ValidChoices $ValidChoices))
        {
            [Console]::Beep()

            continue
        }

        $Normalized = $Choice.ToUpper()

        Write-Host $Normalized

        return $Normalized
    }
}


Export-ModuleMember -Function `
    Test-VolScriptMenuChoice, `
    Read-VolScriptMenuChoice
