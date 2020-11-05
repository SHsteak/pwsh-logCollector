param (
    [String]$path = "D:\개인자료\업무\서버관리\10.Scripts\01.Windows\Powershell\08.Log_Collector",
    $config = (Select-Xml -Path "$($path)\conf.xml" -XPath "/"  | Select-Object -ExpandProperty Node).default,
    [String]$destPath = "$($path)\logs",
    $list = $config.servers.server,
    [String]$username = "$($config.ad.id)@$($config.ad.domain)",
    [securestring]$password = (ConvertTo-SecureString $config.ad.pw -AsPlainText -Force)
)

$now = Get-Date
$fileDate = Get-Date -Format "yyyyMMdd"



if ([int]$now.Day -lt 15) {
    $start_time = Get-Date -Month ($now.Month - 1) -Day 15 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $end_time = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0    
}
else {
    $start_time = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $end_time = Get-Date -Day 15 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
}

$term = (Get-Date -Date $start_time -Format "yyyyMMdd") + "-" + (Get-Date -Date ($end_time.AddDays(-1))  -Format "dd")


function run() {
    $scriptBlock = {
        param($c)
        invoke-expression $c
    }
    
    

    $list | ForEach-Object {
        $server = $_.hostname
        try {
            # AD에 Join 안된 서버일 경우, LocalAccount\ID와 별도 PW로 Setting
            if ($null -ne $_.id) {
                $username = "LocalAccount\$($_.id)"
                $password = (ConvertTo-SecureString $_.pw -AsPlainText -Force)
            }
            $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
            $session = New-PSSession -Credential $cred -ComputerName $server
        }
        catch {
            exceptionHandler $server $_.Exception
        }
        Get-ChildItem -Path "$path\scripts" | ForEach-Object {
            try {
                IF (!(Test-Path "$destPath\$server")) {
                    New-Item -Path "$destPath\$server" -ItemType Directory -Force
                }
                
                if ($_ -like "*app*") {
                    $fileNm = "app"
                }
                else {
                    $fileNm = "system"
                }

                $command = (Get-Content -Path "$path\scripts\$($_.Name)").ToString() -replace "start_time", $start_time -replace "end_time", $end_time

                Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $command | Out-File -FilePath ("$destPath\$server\$term" + "_" + "$fileNm")
            }
            catch {
                exceptionHandler $server $_.Exception
            }
        }
    }
}

function exceptionHandler {
    param (
        $server,
        $message
    )

    if (!(Test-Path "$path\error")) {
        New-Item -Path "$path\error" -ItemType Directory -Force
    }
    
    $message >> $path\error\$server"_"error"_"$fileDate
}

run