<#
OST
    1.Clear Sky(ClearSky.ogg)
    2.Footprint in Stone(FootprintInStone.ogg)
    3.Tomorrow(Tomorrow.ogg)
    4.Labour(LaborDay.ogg)
    5.Unknown(Unknown.ogg)
    6.Attitude(Attitude.ogg)
    7.Lockdown(Lockdown.ogg)
    8.Don't Leave(DontLeave.ogg)
    9.Sail Away(SailAway.ogg)
    10.Stand Up(StandUp.ogg)
    11.Test of Time(TestOfTime.ogg)
    12.Dark(LaborDay 5 draftas.ogg)
    13.Steam(13Steam.ogg)
    14.Ice(Ice.ogg)
    15.Thermal(Thermal.ogg)
    16.Factory(Factory.ogg)
    17.Golf(Golf.ogg)
    18.City(City.ogg)
    19.Forest(ForestTwo.ogg)
    20.Laboratory(Laboratory.ogg)
    21.Lumber(Lumber.ogg)
    22.Red Rock(Redrock theme.ogg)
    23.Tower(Tower.ogg)
    24.Copper World(CopperWorld.ogg)
Extra Sounds
    25.IntroDrones
    26.Jonny
    27.Aztec
    28.UnknownArrangement
    29.LockdownArrangement
    30.LabDemo
    31.Naval1
    32.Naval2
    33.Naval3
    34.Candyland A
    35.Candyland B
    36.Test Chamber
    37.BGM2 - cut fast section
Others
    38.Gibberish Conversation
    39.Fiddle BPM 140 12
    40.Military Loudspeaker Broadcast Jibberish
    41.Jazz blues slease sax - B 90 BPM
    42.EndingSoundBOOM_Final_replacement2
    43.Radio_Chatter_Loop
エンコード時間メモ
v1094332 13:22.59(43tracks)
#>
$ext = "ogg"
$filenames = @(
    "ClearSky"
    "FootprintInStone"
    "Tomorrow"
    "LaborDay"
    "Unknown"
    "Attitude"
    "Lockdown"
    "DontLeave"
    "SailAway"
    "StandUp"
    "TestOfTime"
    "LaborDay 5 draftas"
    "13Steam"
    "Ice"
    "Thermal"
    "Factory"
    "Golf"
    "City"
    "ForestTwo"
    "Laboratory"
    "Lumber"
    "Redrock theme"
    "Tower"
    "CopperWorld"
    "IntroDrones"
    "Jonny"
    "Aztec_0"
    "UnknownArrangement"
    "LockdownArrangement"
    "LabDemo"
    "Naval1"
    "Naval2"
    "Naval3"
    "Candyland A"
    "Candyland B"
    "Test Chamber"
    "BGM2 - cut fast section"
    "Gibberish Conversation"
    "Fiddle BPM 140 12"
    "Military Loudspeaker Broadcast Jibberish"
    "Jazz blues slease sax - B 90 BPM"
    "EndingSoundBOOM_Final_replacement2"
    "Radio_Chatter_Loop"
)
$temptitles = @(
    "Clear Sky"
    "Footprint in Stone"
    "Tomorrow"
    "Labour"
    "Unknown"
    "Attitude"
    "Lockdown"
    "Don't Leave"
    "Sail Away"
    "Stand Up"
    "Test of Time"
    "Dark"
    "Steam"
    "Ice"
    "Thermal"
    "Factory"
    "Golf"
    "City"
    "Forest"
    "Laboratory"
    "Lumber"
    "Redrock theme"
    "Tower"
    "CopperWorld"
    "IntroDrones"
    "Jonny"
    "Aztec_0"
    "UnknownArrangement"
    "LockdownArrangement"
    "LabDemo"
    "Naval1"
    "Naval2"
    "Naval3"
    "Candyland A"
    "Candyland B"
    "Test Chamber"
    "BGM2 - cut fast section"
    "Gibberish Conversation"
    "Fiddle BPM 140 12"
    "Military Loudspeaker Broadcast Jibberish"
    "Jazz blues slease sax - B 90 BPM"
    "EndingSoundBOOM_Final_replacement2"
    "Radio_Chatter_Loop"
)
$sections = @(
    "Human Fall Flat OST"
    "Extra Sounds"
    "Others"
)
$titles = @()
$durations = @()
$totalduration = 0
$totaldurations = @()
Set-Location $PSScriptRoot\HFFOST
for ($i = 0; $i -lt $filenames.Count; $i++)
{
    $titles += "$((($i+1).ToString()).PadLeft((($temptitles.Count).ToString()).Length,"0")) $($temptitles[$i])"
    $durations += [Decimal](ffprobe -hide_banner -v 0 -select_streams 0 -of "default=nw=1:nk=1" -show_entries "stream=duration" "$($filenames[$i]).ogg")
    $totalduration += $durations[$i]
    $totaldurations += $totalduration
}
$informations = @()
for ($i = 0; $i -lt $filenames.Count; $i++)
{
    $informations += [ordered]@{
        Section = switch ($i)
        {
            {$_ -in (0..23)}
            {
                $sections[0]
            }
            {$_ -in (24..36)}
            {
                $sections[1]
            }
            default
            {
                $sections[2]
            }
        }
        Title = [regex]::Replace($titles[$i],"'","'\\\''")
        FileName = $filenames[$i]
        Duration = $durations[$i]
        TotalDuration = $totaldurations[$i]
    }
}
$temp = "drawtext=y_align=font:fontfile='C\:/Windows/Fonts/Blogger_Sans.otf':fontsize=95:fontcolor=FFFFFF:x=(w-tw)/2:y=(h-th)/2:text='"
$text = ""
$inputs = ""
$afi = ""
for ($i = 0; $i -lt $informations.Count; $i++)
{
    $text += "${temp}$($informations[$i].Section)`n$($informations[$i].Title)`nFilename\:$([regex]::Replace($informations[$i].Filename,"'","'\\\''"))`nDuration\:%{eif\:floor(floor(abs(t-$(if($i){$informations[$i-1].TotalDuration}else{0})-0.000025))/60)\:d\:2}\:%{eif\:mod(floor(abs(t-$(if($i){$informations[$i-1].TotalDuration}else{0})-0.000025))\,60)\:d\:2}/%{eif\:floor($($informations[$i].Duration)/60)\:d\:2}\:%{eif\:mod($($informations[$i].Duration)\,60)\:d\:2}':enable=gt(abs(t-0.000025)\,$(if($i){$informations[$i-1].TotalDuration}else{0}))*lte(abs(t-0.000025)\,$($informations[$i].TotalDuration)),"
    $inputs += "-i ""$([regex]::Replace($informations[$i].Filename,"'","'\\\''")).$ext"" "
    $afi += "[$($i+1):0]"
}
$text += "null"
Start-Process "ffmpeg" "-hide_banner -y -loop 1 -i image1.png ${inputs}-filter_complex ""[0:0]${text}[v];${afi}concat=n=${i}:v=0:a=1[a]"" -shortest -map ""[v]"" -map ""[a]"" -c:v h264_nvenc -r 10 -c:a aac -b:a 196k ""hffost.mp4""" -NoNewWindow -Wait
Start-Process "ffplay" "-hide_banner -v -8 hffost.mp4" -Wait -NoNewWindow