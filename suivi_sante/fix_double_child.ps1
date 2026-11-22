# Script pour corriger les doubles "child: child:"
$files = Get-ChildItem -Path lib -Recurse -Filter *.dart

Write-Host "Correction des doubles 'child: child:'..." -ForegroundColor Yellow

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Corriger "child: child:" en "child:"
    $content = $content -replace 'child:\s*child:', 'child:'
    
    # Corriger "child: child: " en "child: "
    $content = $content -replace 'child:\s*child:\s*', 'child: '
    
    # Corriger "Flexible(flex: 1, child: child:" en "Flexible(flex: 1, child:"
    $content = $content -replace 'Flexible\(flex:\s*1,\s*child:\s*child:', 'Flexible(flex: 1, child:'
    
    # Corriger les cas où il y a "child: child: Text" en "child: Text"
    $content = $content -replace 'child:\s*child:\s*Text', 'child: Text'
    $content = $content -replace 'child:\s*child:\s*Container', 'child: Container'
    $content = $content -replace 'child:\s*child:\s*Column', 'child: Column'
    $content = $content -replace 'child:\s*child:\s*Row', 'child: Row'
    $content = $content -replace 'child:\s*child:\s*SingleChildScrollView', 'child: SingleChildScrollView'
    $content = $content -replace 'child:\s*child:\s*ListView', 'child: ListView'
    $content = $content -replace 'child:\s*child:\s*Center', 'child: Center'
    $content = $content -replace 'child:\s*child:\s*GestureDetector', 'child: GestureDetector'
    $content = $content -replace 'child:\s*child:\s*Padding', 'child: Padding'
    $content = $content -replace 'child:\s*child:\s*OutlinedButton', 'child: OutlinedButton'
    $content = $content -replace 'child:\s*child:\s*ElevatedButton', 'child: ElevatedButton'
    $content = $content -replace 'child:\s*child:\s*TextButton', 'child: TextButton'
    $content = $content -replace 'child:\s*child:\s*_build', 'child: _build'
    
    if ($content -ne $original) {
        Set-Content $file.FullName $content
        Write-Host "OK: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Termine !" -ForegroundColor Green