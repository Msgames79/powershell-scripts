$ErrorActionPreference='SilentlyContinue'
while ((Get-ChildItem ".\random.m3u").Count) {
    Remove-Item ".\random.m3u" -Force
}
if ((Get-ChildItem ".\ncs.m3u").Count) {
    Get-Content ".\ncs.m3u" | Get-random -shuffle | Out-File ".\random.m3u"
}