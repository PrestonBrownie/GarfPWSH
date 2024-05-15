# GarfTools

A GUI PowerShell multi-tool that can hold all the short scripts/functions you can’t be bothered to memorize. This is heavily WIP, and is my first PowerShell project.

THE BUILT IN FUNCTIONS REQUIRE POWERSHELL 7. YOU CAN ADD FUNCTIONS FOR 5.1 AS YOU SEE FIT.

### Parameter Format
`(PARAMETER NAME)=(VALUE)  (NEXT PARAMETER NAME)=(OTHER VALUE)`

### Adding your own scripts/functions
The naming scheme is `pwsh(CATEGORY).(FUNCTION NAME)`
Large scripts are currently untested

### Hiding the main PowerShell window
Make a shortcut then add this in the target field:

`powershell.exe -NoProfile -WindowStyle Hidden -File "C:\path"`
### Current Goals
* Better response time
* Built-in way to add scripts so you don’t have to touch the code

### Shoutouts
Shoutout to foxdeploy.com for the XAML loader in the beginning of the script, couldn’t have done it in one file without it.