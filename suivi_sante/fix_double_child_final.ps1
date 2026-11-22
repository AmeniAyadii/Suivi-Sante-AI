# Script pour corriger les doubles "child: child:"
$files = @(
    "lib\screens\vital_tracker\widgets\add_measurement_dialog.dart",
    "lib\screens\vital_tracker\widgets\vital_card.dart"
)

Write-Host "Correction des doubles child:..." -ForegroundColor Yellow

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $original = $content
        
        # 1. Supprimer les doubles "child: child:"
        $content = $content -replace 'child:\s*child:', 'child:'
        
        # 2. Nettoyer "Flexible(flex: 1, child: child:" en "Flexible(flex: 1, child:"
        $content = $content -replace 'Flexible\(flex:\s*1,\s*child:\s*child:', 'Flexible(flex: 1, child:'
        
        # 3. Nettoyer les cas avec "child: child:" suivi d'un widget
        $content = $content -replace 'child:\s*child:\s*OutlinedButton', 'child: OutlinedButton'
        $content = $content -replace 'child:\s*child:\s*Text', 'child: Text'
        $content = $content -replace 'child:\s*child:\s*Container', 'child: Container'
        $content = $content -replace 'child:\s*child:\s*Column', 'child: Column'
        $content = $content -replace 'child:\s*child:\s*Row', 'child: Row'
        
        if ($content -ne $original) {
            Set-Content $file $content
            Write-Host "OK: $file" -ForegroundColor Green
        } else {
            Write-Host "Aucun changement: $file" -ForegroundColor Gray
        }
    } else {
        Write-Host "Fichier non trouve: $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Termine !" -ForegroundColor Green