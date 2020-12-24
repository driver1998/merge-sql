[CmdletBinding()]
param (
    [string][Parameter(Mandatory=$true)]$Database
)

$utf16 = [System.Text.Encoding]::GetEncoding(
        'utf-16', 
        $(New-Object System.Text.EncoderExceptionFallBack), 
        $(New-Object System.Text.DecoderExceptionFallback)
    )
$utf8 = [System.Text.Encoding]::GetEncoding(
        'utf-8', 
        $(New-Object System.Text.EncoderExceptionFallBack), 
        $(New-Object System.Text.DecoderExceptionFallback)
    )
$gbk = [System.Text.Encoding]::GetEncoding(
        'gbk', 
        $(New-Object System.Text.EncoderExceptionFallBack), 
        $(New-Object System.Text.DecoderExceptionFallback)
    )

function Convert-String {
    param (
        $bytes
    )

    if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return $utf16.GetString($bytes)
    }

    try {
        return $utf8.GetString($bytes)
    } catch {
        return $gbk.GetString($bytes)
    }
}

function Merge-Sql {
    Write-Output "USE $database`r`n"
    (Get-Item files/*.sql | ForEach-Object {
        Write-Host $_.Name
        
        $name = $_.BaseName
        $name = $name -replace "'", "_"
        Write-Output "`r`nPRINT N'$($name)'`r`nGO`r`n"
    
        $bytes = [System.IO.File]::ReadAllBytes($_)
        $str = Convert-String($bytes)

    
        if ($str[0] -eq 0xFEFF) {
            $str = $str.TrimStart(0xFEFF)
        }

        $str = $str -replace "`r`n", "`n"
        $str = $str -replace "`r", "`n"
        $str = $str -replace "`n", "`r`n"


        Write-Output $str
        Write-Output "`r`nGO`r`n"
    })
}

$output = $(Merge-Sql)
[System.IO.File]::WriteAllBytes('merged.sql', $utf8.GetBytes($output))