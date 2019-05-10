function Show-Menu
{
     param (
           [string]$Title = 'Schedule Enable/Disable Backup'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "E: Enable Backup."
     Write-Host "D: Disable Backup."
     Write-Host "Q: Press 'Q' to quit."
     Write-Host " "
     
}

function Select-Site
{
    Write-Host "N: HPQ NG2 Cells."
    Write-Host "P: HPQ NG1 Cells"
    Write-Host "R: Remote Sites"
    Write-Host "E: Entsvcs cells"
    Write-Host "S: Softwaregrp cells"
    Write-Host " "
$inputsite = Read-Host "Please Select Cell category"
switch ($inputsite)
    {
    'N'{
    Write-Host " "
    Write-Host "================== NGDC ====================="
    List-Cells .\cells.txt
    $cellnum = Read-Host -Prompt 'Select Cell Server'
    Write-Host " "
    $script:cellname = (gc cells.txt)[$cellnum -1 ]
    write-host "======= $cellname ======="
    }
    'P'{
    Write-Host " "
    Write-Host "================== NGDC ====================="
    List-Cells .\cells-MCS.txt
    $cellnum = Read-Host -Prompt 'Select Cell Server'
    Write-Host " "
    $script:cellname = (gc cells-MCS.txt)[$cellnum -1 ]
    write-host "======= $cellname ======="
    }
    'R'{
    Write-Host " "
    Write-Host "============== RCS/MCS Cells ================"
    List-Cells .\cells-RCS.txt
    $cellnum = Read-Host -Prompt 'Select Cell Server'
    write-host " "
    $script:cellname = (gc cells-RCS.txt)[$cellnum -1 ]
    write-host "======= $cellname ======="
    }
    'E'{
    Write-Host " "
    Write-Host "============== RCS/MCS Cells ================"
    List-Cells .\cells-entsvcs.txt
    $cellnum = Read-Host -Prompt 'Select Cell Server'
    write-host " "
    $script:cellname = (gc cells-entsvcs.txt)[$cellnum -1 ]
    write-host "======= $cellname ======="
    }
    'S'{
    Write-Host " "
    Write-Host "============== RCS/MCS Cells ================"
    List-Cells .\cells-softwaregrp.txt
    $cellnum = Read-Host -Prompt 'Select Cell Server'
    write-host " "
    $script:cellname = (gc cells-softwaregrp.txt)[$cellnum -1 ]
    write-host "======= $cellname ======="
    }
    'q' {
    return
    }
    }
}
function List-Cells
{if ($args.Count -gt 1) { Write-Host 'Only enter one filename'; exit }
if (-not($args)) {
    do { $args = Read-Host 'Please enter a file name' } 
    until (($args -split '\s+').Count -eq 1 -and ($args))
    }
if (Test-Path $args) {
    $text = @(Get-Content $args)
    $newtext = New-Object System.Collections.ArrayList
    for ($i=0;$i -lt $text.count; $i ++) { $newtext += "$($i + 1): " + $text[$i] }
    $newtext
    }
else { Write-Host "$args does not exist" -ForegroundColor Red }
write-host " "

}

function Sched-disable-info
{ 
#write-host "You Selected $script:cellname"
write-host " "
$script:specname = Read-host -Prompt 'Enter spec name. eg : gvu0081_TIAP'
$speclist = (.\plink.exe -ssh -l aqmalscr -i .\aqmalbkp.ppk $script:cellname "ls -d /etc/opt/omni/server/schedules/* |grep -i $script:specname ; ls -d /etc/opt/omni/server/barschedules/oracle8/* |grep -i $script:specname ;ls -d /etc/opt/omni/server/barschedules/mssql/* |grep -i $script:specname") 
if (!$speclist) {Write-Host "Spec not found... Exiting" ; Start-Sleep -s 10 ; exit }
Write-output $speclist |out-file specfile.txt
Import-Csv .\specfile.txt -header c1,c2,c3,c4,c5,c6,c7,c8 -Delimiter "/"  |Select-Object c7,c8 |Format-Table -HideTableHeaders
write-host "==================================="
$script:daysdisable = Read-Host -Prompt 'Type in Days to Disable. p = permanent'
ask-reason
write-host -nonewline "Disable Spec above for $script:daysdisable days?  (Y/N) : "
$response = read-host
if ( $response -ne "Y" ) { exit }
write-host "==================================="
}


function ask-reason
{
Read-Host -Prompt 'Reason' |out-file .\reason.txt
}

function test-date
{
if ($script:daysdisable  -match "p") { disable-backup-permanent }
elseif ($script:daysdisable -match '^[0-9]+$') { disable-backup-day }
elseif (!$script:daysdisable) {Write-Host "null"}
else  {write-host "Unrecognized. exiting"}
}

function disable-backup-permanent
{
$date_now=(Get-Date -UFormat "%m%d%Y_%H%M%p")
gc .\specfile.txt |ForEach-Object{ 'if [ -r ' + $_ + ' ] ; then ' + 'cp' + " " + $_ + " " + '/home/aqmalscr/sched/' +($_.Split("/")[6,7] -join "_") + "_" + $date_now + ' ; else echo " No Read Permission ' + ($_.Split("/")[6,7] -join " ")+ '" ; fi' } |Out-File .\cmd.txt                                                                   #copy schedule to homedir
#gc .\specfile.txt |ForEach-Object{ (gc .\perl.txt)[0] + "/home/aqmalscr/sched/" + ($_.Split("/")[4,5] -join "_") + "_" +$script:date_now + " | tee " + $_ } |Out-File -Append .\cmd.txt                                          #remove existing disable
#gc .\specfile.txt |ForEach-Object{ (gc .\perl.txt)[1] + "/home/aqmalscr/sched/" + ($_.Split("/")[4,5] -join "_") + "_" +$script:date_now + " | tee " + $_ } |Out-File -Append .\cmd.txt                                          #remove existing starting
gc .\specfile.txt |ForEach-Object{ 'if [ -r ' + $_ + ' ] ; then ' + 'cat ' + $_ + (gc .\perl.txt)[7] + " | tee /home/aqmalscr/schedtmp/" + ($_.Split("/")[6,7] -join "_") + "_" +$date_now + ' > /dev/null' + ' ; else echo "Schedule not modified" ; fi ' } | Out-File -Append .\cmd.txt                  #grep -v disable and starting and output to temp file
gc .\specfile.txt |ForEach-Object{ 'if [ -r ' + $_ + ' ] ; then ' + (gc .\perl.txt)[2] + "/home/aqmalscr/schedtmp/" + ($_.Split("/")[6,7] -join "_") + "_" +$date_now + " | /opt/pb/bin/pbrun tee " + $_ + ' > /dev/null 2>&1 ; echo "Disable Successful" '  + ' ; else echo "Please check file permission" ; fi ' } |Out-File -Append .\cmd.txt                                          #add disable to first line
#gc .\specfile.txt |ForEach-Object{ 'if cmp -s ' + $_ + '/home/aqmalscr/sched/' +($_.Split("/")[6,7] -join "_") + "_" + $date_now + ' ; then echo "Modify Success" ; else echo "Modify Failed" ; fi' } | Out-File -Append .\cmd.txt
Add-Content -value "/opt/omni/bin/omnirpt -rep dl_sched -tab |grep $script:specname" -path .\cmd.txt
[System.Environment]::CurrentDirectory = (Get-Location).Path
$MyPath = ".\cmd.txt"
$MyFile = Get-Content $MyPath
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
[System.IO.File]::WriteAllLines($MyPath, $MyFile, $Utf8NoBomEncoding)
(.\plink.exe -ssh -l aqmalscr -i .\aqmalbkp.ppk $script:cellname -m .\cmd.txt)
}


function disable-backup-day
{
$script:newdate = get-date((get-date).addDays($daysdisable)) -uformat "%d %m %Y"
$date_now=(Get-Date -UFormat "%m%d%Y_%H%M%p")
Write-Output $script:newdate | Out-File .\newdate.txt
gc .\specfile.txt |ForEach-Object{ 'if [ -r ' + $_ + ' ] ; then ' + 'cp' + " " + $_ + " " + '/home/aqmalscr/sched/' +($_.Split("/")[6,7] -join "_") + "_" + $date_now + ' ; else echo " No Read Permission ' + ($_.Split("/")[6,7] -join " ")+ '" ; fi' } |Out-File .\cmd.txt                                                                   #copy schedule to homedir
#gc .\specfile.txt |ForEach-Object{ (gc .\perl.txt)[0] + "/home/aqmalbkp/sched/" + ($_.Split("/")[4,5] -join "_") + "_" +$script:date_now + " | tee " + $_ } |Out-File -Append .\cmd.txt                                          #remove existing disable
#gc .\specfile.txt |ForEach-Object{ (gc .\perl.txt)[1] + "/home/aqmalbkp/sched/" + ($_.Split("/")[4,5] -join "_") + "_" +$script:date_now + " | tee " + $_ } |Out-File -Append .\cmd.txt                                          #remove existing starting
gc .\specfile.txt |ForEach-Object{'if [ -r ' + $_ + ' ] ; then ' + 'cat ' + $_ + (gc .\perl.txt)[7] + " | tee /home/aqmalscr/schedtmp/" + ($_.Split("/")[6,7] -join "_") + "_" +$date_now + ' > /dev/null'  + ' ; else echo "Schedule not modified" ; fi ' } | Out-File -Append .\cmd.txt                  #grep -v disable and starting and output to temp file
gc .\specfile.txt |ForEach-Object{'if [ -r ' + $_ + ' ] ; then ' + (gc .\perl.txt)[5] + $script:newdate + (gc .\perl.txt)[6] + "/home/aqmalscr/schedtmp/" + ($_.Split("/")[6,7] -join "_") + "_" + $date_now + " | /opt/pb/bin/pbrun tee " + $_  + ' > /dev/null 2>&1 ; echo "Disable Successful" '  + ' ; else echo "Please check file permission" ; fi '} |Out-File -Append .\cmd.txt    #adding starting from temp file to original file
Add-Content -value "/opt/omni/bin/omnirpt -rep dl_sched -tab |grep $script:specname" -path .\cmd.txt
[System.Environment]::CurrentDirectory = (Get-Location).Path
$MyPath = ".\cmd.txt"
$MyFile = Get-Content $MyPath
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
[System.IO.File]::WriteAllLines($MyPath, $MyFile, $Utf8NoBomEncoding)
(.\plink.exe -ssh -l aqmalscr -i .\aqmalbkp.ppk $script:cellname -m .\cmd.txt)
}

function enable-backup
{
#write-host "You Selected $script:cellname"
write-host " "
$script:specname = Read-host -Prompt 'Spec name'
$speclist = (.\plink.exe -ssh -l aqmalscr -i .\aqmalbkp.ppk $script:cellname "ls -d /etc/opt/omni/server/schedules/* |grep -i $script:specname ; ls -d /etc/opt/omni/server/barschedules/oracle8/* |grep -i $script:specname ;ls -d /etc/opt/omni/server/barschedules/mssql/* |grep -i $script:specname ") 
if (!$speclist) {Write-Host "Spec not found. Exiting "; Start-Sleep -s 5 ; exit }
Write-output $speclist |out-file specfile.txt
Import-Csv .\specfile.txt -header c1,c2,c3,c4,c5,c6,c7,c8 -Delimiter "/"  |Select-Object c7,c8 |Format-Table -HideTableHeaders
write-host "==================================="
ask-reason
write-host -nonewline "Enable All Spec above? (Y/N) "
$response = read-host
if ( $response -ne "Y" ) { exit }
write-host "==================================="

$date_now=(Get-Date -UFormat "%m%d%Y_%H%M%p")
gc .\specfile.txt |ForEach-Object{ 'if [ -r ' + $_ + ' ] ; then ' + 'cp' + " " + $_ + " " + '/home/aqmalscr/sched/' +($_.Split("/")[6,7] -join "_") + "_" + $date_now + ' ; else echo " No Read Permission ' + ($_.Split("/")[6,7] -join " ")+ '" ; fi' } |Out-File .\cmd.txt                                                                   #copy schedule to homedir
#gc .\specfile.txt |ForEach-Object{ (gc .\perl.txt)[0] + "/home/aqmalbkp/sched/" + ($_.Split("/")[4,5] -join "_") + "_" + $script:date_now + " | tee " + $_  } |Out-File -Append .\cmd.txt                                          #remove existing disable
#gc .\specfile.txt |ForEach-Object{ (gc .\perl.txt)[1] + "/home/aqmalbkp/sched/" + ($_.Split("/")[4,5] -join "_") + "_" + $script:date_now + " | tee " + $_  } |Out-File -Append .\cmd.txt                                          #remove existing starting
gc .\specfile.txt |ForEach-Object{ 'if [ -r ' + $_ + ' ] ; then ' + 'cat ' + '/home/aqmalscr/sched/' + ($_.Split("/")[6,7] -join "_") + "_" + $:date_now + (gc .\perl.txt)[7] + " | /opt/pb/bin/pbrun tee " + $_ + ' > /dev/null 2>&1 ; echo "Enable Successful" '  + ' ; else echo "Schedule not modified" ; fi ' } | Out-File -Append .\cmd.txt
Add-Content -value "/opt/omni/bin/omnirpt -rep dl_sched -tab |grep $script:specname" -path .\cmd.txt
[System.Environment]::CurrentDirectory = (Get-Location).Path
$MyPath = ".\cmd.txt"
$MyFile = Get-Content $MyPath
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
[System.IO.File]::WriteAllLines($MyPath, $MyFile, $Utf8NoBomEncoding)
(.\plink.exe -ssh -l aqmalscr -i .\aqmalbkp.ppk $script:cellname -m .\cmd.txt)
}


function check-schedule
{
$time_out = 15 # seconds
}

function send-email
{
Write-Output "Backup $script:action by user $env:USERNAME for $script:daysdisable days" |Out-File .\email.txt
Import-Csv .\specfile.txt -header c1,c2,c3,c4,c5,c6,c7,c8 -Delimiter "/"  |Select-Object c7, c8 |Format-Table -HideTableHeaders |  Out-File -Append .\email.txt
gc .\reason.txt |Out-File -Append .\email.txt
Send-MailMessage -to "aqmal@hpe.com" -Subject "Test Email - Backup Schedule" -From "BackupReporting@hpe.com" -SmtpServer "smtp3.hpe.com" -body (gc .\email.txt |Out-String)
}

function post-action
{
Import-Csv .\specfile.txt -header c1,c2,c3,c4,c5,c6,c7,c8 -Delimiter "/"  |Select-Object @{name='Date'; Expression = { Get-Date -UFormat "%d %m %Y" }}, @{name='Cell Server'; Expression = { $script:cellname }}, c7,c8 ,@{name='Action'; Expression = { $script:action }}, @{name='Days'; Expression = { $script:daysdisable }}, @{name='Until'; Expression = { $script:newdate }}, @{name='User'; Expression = { $env:USERNAME }},@{name='Reason'; Expression = { (gc .\reason.txt) }}  |Export-Csv -Append  Schedlist.csv
#Remove-Item .\specfile.txt, .\email.txt, .\cmd.txt, .\reason.txt
}

do
{ 
     $scriptpath = $MyInvocation.MyCommand.Path
     $dir = Split-Path $scriptpath
     Set-Location -Path $scriptpath
     Show-Menu
     $input = Read-Host "Please make a selection"
     Write-host " "
     switch ($input)
     {
           'E' {
                #cls
                Write-Host "============== Schedule Enable =============="
                #List-Cells .\cells.txt
                Select-Site
                enable-backup
                $script:action = "Enable"
                send-email
                post-action
                #Write-Host "Enable Successfull"
           } 'D' {
                #cls
                Write-Host "============== Schedule Disable ============="
                 #List-Cells .\cells.txt
                 Select-Site
                 Sched-disable-info
                 test-date
                 $script:action = "Disable"
                 send-email
                 post-action
                 #Write-Host "Disable Successful"
           } 'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')
