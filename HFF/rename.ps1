$list1 = @(Get-ChildItem -Name | Where-Object {$_ -match "\.(ogg|wav)$"})
$list2 = @($list1 | ForEach-Object {(ffprobe -hide_banner -select_streams a -of "default=nw=1:nk=1" -show_entries "stream=duration" -v 0 $_).PadLeft(11,"0")})
0..($list1.Count - 1) | ForEach-Object{"Rename-Item ""$($list1[$_])"" ""$($list2[$_]) $($list1[$_])""" | Invoke-Expression}