# Configuration
$listFile = "scp-files.list"
$remotePath = "ameyk@auto.ece.pdx.edu:/u/ameyk/ECE593_Codes/ECE593_AHB2APB_Bridge/AHB2APB_Brdg_MS2_Class/"
$checkInterval = 2 

$fileTimestamps = @{}

Write-Host "Monitoring files and folders in $listFile..." -ForegroundColor Cyan

while ($true) {
    if (Test-Path $listFile) {
        $paths = Get-Content $listFile
        
        foreach ($originPath in $paths) {
            $originPath = $originPath.Trim()
            if (-not (Test-Path $originPath)) { continue }

            # 1. Get all files (if it's a folder, get everything inside recursively)
            $itemsToCheck = Get-ChildItem -Path $originPath -Recurse | Where-Object { -not $_.PSIsContainer }

            foreach ($item in $itemsToCheck) {
                $filePath = $item.FullName
                $currentWriteTime = $item.LastWriteTime

                # 2. Check for changes
                if (-not $fileTimestamps.ContainsKey($filePath) -or $currentWriteTime -gt $fileTimestamps[$filePath]) {
                    Write-Host "Syncing: $($item.Name) - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
                    
                    # 3. Use -r just in case, though we are sending specific files here
                    scp -r $filePath $remotePath

                    $fileTimestamps[$filePath] = $currentWriteTime
                }
            }
        }
    }
    Start-Sleep -Seconds $checkInterval
}
