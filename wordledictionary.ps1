$dictionary = ((Invoke-RestMethod "https://gist.githubusercontent.com/dracos/dd0668f281e685bad51479e5acaadb93/raw/6bfa15d263d6d5b63840a8e5b64e04b382fdb079/valid-wordle-words.txt") -split "`\n")
[System.Text.StringBuilder]$log = [System.Text.StringBuilder]::new()
[string[]]$yellows = @("", "", "", "", "")
[string]$greens
[string]$grays
[System.Collections.BitArray]$flags = [System.Collections.BitArray]::new(5, $false)
function Get-OrdinalPostfix {
    param (
        [System.Numerics.BigInteger]$n
    )
    if ($n -ge 1)
    {
        if (($n % 100) / 10 -ne 1) {
            switch ($n % 10) {
                1 {
                    return "st"
                }
                2 {
                    return "nd"
                }
                3 {
                    return "rd"
                }
            }
        }
    }
    return "th"
}

while ($true) {
    $log.Append("Enter a letter for green letter or a _ for place that is not decided")
    do {
        Clear-Host
        $greens = Read-Host $log.ToString()
    } until ($greens -match "^[_a-z]{5}$" -and $greens -notmatch "^[a-z]{5}$")
    $log.Append(": ${greens}")
    for ($i = 0; $i -lt 5; $i++) {
        $log.Append("`nEnter yellow letters that is $($i + 1)$(Get-OrdinalPostfix ($i + 1)) letter")
        do {
            Clear-Host
            $yellows[$i] = Read-Host $log
        } until ($yellows[$i] -match "^[a-z]*$")
        $log.Append(": $($yellows[$i])")
    }
    $log.Append("`nEnter gray letters")
    do {
        Clear-Host
        $grays = Read-Host $log
    } until ($grays -match "^[a-z]*$")
    $log.Append(": ${grays}`n")
    Clear-Host
    Write-Host $log
    foreach ($first in [char[]]"abcdefghijklmnopqrstuvwxyz") {
        if ($grays -match $first) {
            continue
        }
        foreach ($second in [char[]]"abcdefghijklmnopqrstuvwxyz") {
            if ($grays -match $second) {
                continue
            }
            foreach ($third in [char[]]"abcdefghijklmnopqrstuvwxyz") {
                if ($grays -match $third) {
                    continue
                }
                foreach ($forth in [char[]]"abcdefghijklmnopqrstuvwxyz") {
                    if ($grays -match $forth) {
                        continue
                    }
                    foreach ($fifth in [char[]]"abcdefghijklmnopqrstuvwxyz") {
                        if ($grays -match $fifth) {
                            continue
                        }
                        $word = "$([string]$first)$([string]$second)$([string]$third)$([string]$forth)$([string]$fifth)"
                        if ($word -in $dictionary)
                        {
                            $flags.SetAll($false)
                            for ($i = 0; $i -lt 5; $i++) {
                                if ($word.Substring($i, 1) -eq $greens.Substring($i, 1) -or ($greens.Substring($i, 1) -eq "_" -and $yellows[$i] -notmatch $word.Substring($i, 1))) {
                                    $flags[$i] = $true
                                    Write-Host "`$flags[$i] became true"
                                }
                            }
                            if ($flags.HasAllSet()) {
                                $null = $log.AppendLine($word)
                            }
                        }
                    }
                }
            }
        }
    }
    $log.Append("Done")
    Clear-Host
    Read-Host $log
    $log.Clear()
    $flags.SetAll($false)
}

<#
__d__
e



oy
auimpt
#>