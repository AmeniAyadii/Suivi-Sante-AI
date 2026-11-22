# Script FINAL pour corriger les derniers Expanded
$filesToFix = @(
    "lib\screens\health_assessment_form_screen.dart",
    "lib\screens\signes\health_dashboard.dart",
    "lib\screens\vital_tracker\widgets\add_measurement_dialog.dart",
    "lib\screens\vital_tracker\widgets\vital_card.dart",
    "lib\services\chatbot\permission_service.dart"
)

Write-Host "Correction des derniers Expanded..." -ForegroundColor Yellow

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $original = $content
        
        # Remplacer Expanded( par Flexible(
        $content = $content -replace 'Expanded\(', 'Flexible('
        
        # Ajouter flex: 1 si besoin
        $content = $content -replace 'Flexible\(([^,)]*)\)', 'Flexible(flex: 1, child: $1)'
        
        if ($content -ne $original) {
            Set-Content $file $content
            Write-Host "OK: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "Fichier non trouve: $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Tous les fichiers ont ete corriges !" -ForegroundColor Green
Write-Host ""
Write-Host "Relancez l'application:" -ForegroundColor Yellow
Write-Host "flutter clean" -ForegroundColor Cyan
Write-Host "flutter run" -ForegroundColor Cyan