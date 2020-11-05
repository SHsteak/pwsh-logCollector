
param (
    [String]$path = "D:\개인자료\업무\서버관리\10.Scripts\01.Windows\Powershell\08.Log_Collector",
    $config = (Select-Xml -Path "$($path)\conf.xml" -XPath "/"  | Select-Object -ExpandProperty Node).default
)
$config.servers.server | ForEach-Object -Parallel {
    param(
        $scriptHome = $Using:path,
        [String]$destPath = "$($scriptHome)\logs",
        [String]$username = "$($Using:config.ad.id)@$($Using:config.ad.domain)",
        [securestring]$password = (ConvertTo-SecureString $Using:config.ad.pw -AsPlainText -Force),
        [datetime]$now = (Get-Date),
        [String]$fileDate = (Get-Date -Format "yyyyMMdd")
    )

    $server = $_.hostname


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
        # AD에 Join 안된 서버일 경우, LocalAccount\ID와 별도 PW로 PSSession 생성
        if ($null -ne $_.id) {
            $username = "LocalAccount\$($_.id)"
            $password = (ConvertTo-SecureString $_.pw -AsPlainText -Force)
            $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
            $session = New-PSSession -Credential $cred -ComputerName $_.ipAddress
        }
        # AD Join 된 경우, AD 계정으로 PSSession 생성
        else {
            $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
            $session = New-PSSession -Credential $cred -ComputerName $server
        }
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