
param (
    [String]$scriptHome = "D:\개인자료\업무\서버관리\10.Scripts\01.Windows\08.Log_Collector"
)
Get-Content -Path "$scriptHome\server_list" | ForEach-Object -Parallel {
    param(
        $scriptHome = $Using:scriptHome,
        [String]$destPath = "$($scriptHome)\logs",
        [String]$username = "administrator@torayamk.com",
        [securestring]$password = (ConvertTo-SecureString "skdmstkfkd!@" -AsPlainText -Force),
        [datetime]$now = (Get-Date),
        [String]$fileDate = (Get-Date -Format "yyyyMMdd")
    )

    $server = $_

    if ([int]$now.Day -lt 15) {
        $start_time = Get-Date -Month ($now.Month - 1) -Day 15 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
        $end_time = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0    
    }
    else {
        $start_time = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
        $end_time = Get-Date -Day 15 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    }

    $term = (Get-Date -Date $start_time -Format "yyyyMMdd") + "-" + (Get-Date -Date ($end_time.AddDays(-1))  -Format "dd")
    
    try {
        $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
        $session = New-PSSession -Credential $cred -ComputerName $server
    }
    catch {
        if (!(Test-Path "$scriptHome\error")) {
            New-Item -Path "$scriptHome\error" -ItemType Directory -Force
        }
        $_.Exception >> $scriptHome\error\$server"_"error"_"$fileDate
    }

    $scriptBlock = {
        param($c)
        invoke-expression $c
    }

    Get-ChildItem -Path "$scriptHome\scripts" | ForEach-Object {
        try {
            if (!(Test-Path "$destPath\$server")) {
                New-Item -Path "$destPath\$server" -ItemType Directory -Force
            }
                
            if ($_ -like "*app*") {
                $fileNm = "app"
            }
            else {
                $fileNm = "system"
            }

            $command = (Get-Content -Path "$scriptHome\scripts\$($_.Name)").ToString() -replace "start_time", $start_time -replace "end_time", $end_time

            Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $command | Out-File -FilePath ("$destPath\$server\$term" + "_" + "$fileNm")
        }
        catch {
            if (!(Test-Path "$scriptHome\error")) {
                New-Item -Path "$scriptHome\error" -ItemType Directory -Force
            }
            $_.Exception >> $scriptHome\error\$server"_"error"_"$fileDate
        }
    }
}

exit 0