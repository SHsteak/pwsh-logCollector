param (
    [String]$path = "D:\개인자료\업무\서버관리\10.Scripts\01.Windows\08.Log_Collector",
    [String]$destPath = "D:\개인자료\업무\서버관리\10.Scripts\01.Windows\08.Log_Collector",
    [System.Collections.ArrayList]$list = (Get-Content -Path "$path\server_list"),
    [String]$username = "administrator@torayamk.com",
    [securestring]$password = (ConvertTo-SecureString "skdmstkfkd!@" -AsPlainText -Force)
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
        $server = $_
        try {
            $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
            $session = New-PSSession -Credential $cred -ComputerName $_
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