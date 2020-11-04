Get-EventLog -LogName Application -EntryType Warning,Error -After "start_time" -Before "end_time" -WarningAction SilentlyContinue  -ErrorAction SilentlyContinue | Format-List -Property TimeGenerated,Category,EntryType,Message