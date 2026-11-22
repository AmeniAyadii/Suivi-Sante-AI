# Script pour corriger les Expanded problématiques
$filesToFix = @(
    "lib\screens\dashboard_screen.dart",
    "lib\screens\chatbot\chat_screen.dart",
    "lib\screens\health_goals_page.dart",
    "lib\screens\login_screen.dart",
    "lib\screens\medicaments_screen.dart",
    "lib\screens\rendezvous_screen.dart",
    "lib\screens\report_screen.dart",
    "lib\screens\scan_screen.dart",
    "lib\screens\settings_screen.dart",
    "lib\screens\statistiques_screen.dart",
    "lib\screens\symptomes_screen.dart",
    "lib\screens\symptome_form_screen.dart",
    "lib\screens\vital_tracker\alert_banner.dart",
    "lib\screens\vital_tracker\vital_tracker_screen.dart",
    "lib\screens\welcome\onboarding_screen.dart",
    "lib\widgets\chatbot\message_input.dart",
    "lib\widgets\chatbot\symptom_analysis_card.dart",
    "lib\widgets\chatbot\warning_banner.dart",
    "lib\widgets\goal_card.dart",
    "lib\widgets\health_recommendation_card.dart",
    "lib\widgets\premium_banner.dart",
    "lib\widgets\quick_actions.dart",
    "lib\widgets\report_card.dart"
)

Write-Host "Correction des Expanded..." -ForegroundColor Yellow

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $original = $content
        
        # Remplacer Expanded( par Flexible(
        $content = $content -replace 'Expanded\(', 'Flexible('
        
        # Corriger les doubles child:
        $content = $content -replace 'child:\s*child:', 'child:'
        
        # Ajouter flex: 1 si besoin
        $content = $content -replace 'Flexible\(([^,)]*)\)', 'Flexible(flex: 1, child: $1)'
        
        # Nettoyer les cas speciaux
        $content = $content -replace 'Flexible\(flex:\s*1,\s*child:\s*child:', 'Flexible(flex: 1, child:'
        
        if ($content -ne $original) {
            Set-Content $file $content
            Write-Host "OK: $file" -ForegroundColor Green
        }
    }
}

Write-Host "Termine !" -ForegroundColor Green