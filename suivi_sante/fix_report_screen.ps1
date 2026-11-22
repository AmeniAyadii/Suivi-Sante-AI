# Script pour corriger report_screen.dart
$file = "lib\screens\report_screen.dart"

if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $original = $content
    
    # Remplacer tous les Expanded par Flexible dans les Rows
    $content = $content -replace '(?<=Row\([\s\S]*?)Expanded\(', 'Flexible('
    
    # Nettoyer les doubles child:
    $content = $content -replace 'child:\s*child:', 'child:'
    
    # Ajouter flex: 1
    $content = $content -replace 'Flexible\(([^,)]*)\)', 'Flexible(flex: 1, child: $1)'
    
    if ($content -ne $original) {
        Set-Content $file $content
        Write-Host "OK: report_screen.dart corrige" -ForegroundColor Green
    }
}

Write-Host "Termine !" -ForegroundColor Green