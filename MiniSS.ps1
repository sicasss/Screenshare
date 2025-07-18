$esc = [char]27  # Secuencia de escape

# Definir colores ANSI
$red = "${esc}[31m"
$yellow = "${esc}[33m"
$green = "${esc}[32m"
$reset = "${esc}[0m"

Write-Output ""
Write-Output ""
Write-Output "${Cyan}By wxymi${reset}"
Write-Output ""
Write-Host -ForegroundColor Blue  " __  __  _        _        ___  ___"
Write-Host -ForegroundColor Blue  "|  \/  |(_) _ _  (_)      / __|/ __|"
Write-Host -ForegroundColor Blue  "| |\/| || || ' \ | |      \__ \\__ \"
Write-Host -ForegroundColor Blue  "|_|  |_||_||_||_||_|      |___/|___/"
Write-Output ""
Write-Output "${White}            https://discord.gg/KuMnDSR7wT${reset}"
Write-Output ""
# Extensiones de archivos a buscar
$extensions = "*.exe","*.dll","*.jar","*.bat"

# Cadenas de texto a buscar en los archivos
$strings = @("mouse_event","AutoClicker","[...]","[NONE]","[Bind: ","exelon","AimAssist","Nametags",
             "SelfDestruct","mouse_button","uiAccess='false'","Reeach","AutoClicker","[Bind:","key_key.",
             "autoclicker","killaura.killaura","dreamagent","VeraCrypt","makecert","start /MIN cmd.exe ",
             "vape.gg","Aimbot","aimbot","Tracers","tracers","LeftMinCPS","[Bind","LCLICK","RCLICK",
             "fastplace","self destruct","sc stop","reg delete","misc","hide bind","iUW#Xd",
             "Waiting for minecraft process...","Autoclicker->","MoonDLL.pdb","slinky_init","m#!WO","4<|C/p",
             "Sapphire LITE","Toggle Left Clicker","W0#!&", "cmd.exe", "powershell")

# Cadenas a ignorar en archivos DLL
$ignoreStringsForDll = @("Misc", "mouse_event", "uiAccess='false'", "rEACH", "SelfDestruct", "mouse_button", "DoubleClick")

$path = "C:\Users"
$i = 0
$files = @()
$foldersAccessErrors = [System.Collections.Generic.List[PSCustomObject]]::new()
$fileAccessErrors = [System.Collections.Generic.List[PSCustomObject]]::new()

try {
    $files = Get-ChildItem -Path $path -Include $extensions -Recurse -File -ErrorAction SilentlyContinue
} catch {
    $foldersAccessErrors.Add($_)
}

$folders = Get-ChildItem -Path $path -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
foreach ($folder in $folders) {
    try {
        Get-ChildItem -Path $folder.FullName -Include $extensions -Recurse -File -ErrorAction Stop | Out-Null
    } catch {
        $errorDetail = [PSCustomObject]@{
            Path  = $folder.FullName
            Error = $_.Exception.Message
        }
        $foldersAccessErrors.Add($errorDetail)
    }
}

$total = $files.Count
Write-Progress -Activity "Expanding subdirectories..." -Status "Analyzing" -PercentComplete 0 -Id 1
$ErrorActionPreference = 'SilentlyContinue'

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($file in $files) {
    try {
        $content = Get-Content $file.FullName -Raw
        $filteredStrings = if ($file.Extension -eq ".dll") {
            $strings | Where-Object { $_ -notin $ignoreStringsForDll }
        } else {
            $strings
        }
        
        foreach ($string in $filteredStrings) {
            if ($content -match [regex]::Escape($string)) {
                $result = [PSCustomObject]@{
                    FileName      = $file.FullName
                    StringMatched = $string
                }
                $results.Add($result)
            }
        }
    } catch {
        $errorDetail = [PSCustomObject]@{
            FileName = $file.FullName
            Error    = $_.Exception.Message
        }
        $fileAccessErrors.Add($errorDetail)
    }
    $i++
    Write-Progress -Activity "Searching for files" -Status "Processing" -PercentComplete (($i / $total) * 100) -Id 1
}

$ErrorActionPreference = 'Continue'
Write-Progress -Activity "Completed" -Status "Done" -PercentComplete 100 -Id 1 -Completed

# Mostrar resultados en una vista de rejilla
$results | Out-GridView -Title "Resultados de la búsqueda de cadenas"

$allAccessErrors = $fileAccessErrors + $foldersAccessErrors
if ($allAccessErrors.Count -gt 0) {
    $allAccessErrors | Out-GridView -Title "Errores de acceso a archivos y carpetas"
} else {
    Write-Host "No se encontraron errores de acceso a archivos o carpetas." -ForegroundColor Green
}
