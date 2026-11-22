# Script PowerShell pour corriger tous les Expanded problematiques
# Sauvegardez ce fichier dans le dossier du projet

$filesToFix = @(
    "lib\screens\add_measure_screen.dart",
    "lib\screens\analysis_screen.dart",
    "lib\screens\dashboard_screen.dart",
    "lib\screens\notification_screen.dart",
    "lib\screens\symptomes_screen.dart",
    "lib\screens\chatbot_screen.dart",
    "lib\screens\medicaments_screen.dart",
    "lib\screens\rendezvous_screen.dart",
    "lib\screens\scan_screen.dart",
    "lib\screens\statistiques_screen.dart",
    "lib\screens\profile_screen.dart",
    "lib\screens\register_screen.dart",
    "lib\screens\health_bilan_screen.dart",
    "lib\screens\goals\add_goal_page.dart",
    "lib\screens\goals\goal_detail_page.dart",
    "lib\widgets\challenge_card.dart",
    "lib\widgets\ia_analysis_widget.dart",
    "lib\widgets\custom_snackbar.dart"
)

Write-Host "Correction des Expanded problematiques..." -ForegroundColor Yellow

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        $originalContent = $content
        
        $content = $content -replace '(?<=Row\([\s\S]*?)Expanded\(', 'Flexible('
        
        $content = $content -replace 'Expanded\(child:\s*Text\(', 'Flexible(child: Text('
        
        $content = $content -replace 'Flexible\(([^,)]*)\)', 'Flexible(flex: 1, child: $1)'
        
        $content = $content -replace 'Flexible\(flex:\s*\d+,\s*child:\s*([^)]*)\)', 'Flexible(flex: 1, child: $1)'
        
        if ($content -ne $originalContent) {
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
Write-Host "Tous les fichiers ont ete corriges !" -ForegroundColor Green
Write-Host "N'oubliez pas de verifier manuellement les fichiers suivants :" -ForegroundColor Yellow
Write-Host "   - lib\screens\symptome_form_screen.dart" -ForegroundColor Yellow
Write-Host "   - lib\screens\vital_tracker\*.dart" -ForegroundColor Yellow
Write-Host "   - lib\widgets\*.dart" -ForegroundColor Yellow