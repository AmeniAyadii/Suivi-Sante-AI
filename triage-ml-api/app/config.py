# app/config.py
"""
Configuration centralisée de l'application.
"""
import os
from pathlib import Path

# ============================================
# Chemins du projet
# ============================================
BASE_DIR = Path(__file__).resolve().parent.parent
MODELS_DIR = BASE_DIR / "models"

# ============================================
# Chemins des modèles
# ============================================
# Modèle XGBoost — Format JSON (robuste, prioritaire)
MODEL_PATH_JSON = MODELS_DIR / "xgboost_triage_optimized.json"

# Modèle XGBoost — Format PKL (fallback, peut être corrompu)
MODEL_PATH_PKL = MODELS_DIR / "xgboost_triage_optimized.pkl"

# Ancien chemin (compatibilité)
MODEL_PATH = MODELS_DIR / "best_xgb_optimized.pkl"

# Préprocesseur et encodeur (PKL uniquement, robustes)
PREPROCESSOR_PATH = MODELS_DIR / "preprocessor.pkl"
LABEL_ENCODER_PATH = MODELS_DIR / "label_encoder.pkl"

# ============================================
# Informations de l'API
# ============================================
API_TITLE = "Triage ML API"
API_DESCRIPTION = """
## 🏥 API de Classification Intelligente du Triage

Cette API permet de prédire le niveau de triage d'un patient 
à son arrivée aux urgences, à partir de données cliniques structurées.

### 🎯 Niveaux de triage

| Niveau | Description | Délai de prise en charge |
|--------|-------------|--------------------------|
| 1 🚨 | Réanimation | Immédiat |
| 2 ⚠️ | Urgent | 15-30 min |
| 3 🟡 | Semi-urgent | 30-60 min |
| 4 🔵 | Standard | 1-2 heures |
| 5 🟢 | Non-urgent | Peut attendre |

### 📊 Performance du modèle

- **Modèle** : XGBoost optimisé
- **F1-score** : 0.85 (validation)
- **Features** : 47 variables cliniques
- **Entraîné sur** : 80 000 patients
"""

API_VERSION = "1.0.0"

# ============================================
# CORS (autorisations cross-origin)
# ============================================
# ⚠️ En production, remplacer "*" par les domaines autorisés
# Ex: "https://monapp.com,https://api.monapp.com"
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

# ============================================
# Logging
# ============================================
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# ============================================
# Utilitaires
# ============================================
def get_model_path() -> Path:
    """
    Retourne le chemin du meilleur modèle disponible.
    Priorité : JSON > PKL > Ancien PKL
    """
    if MODEL_PATH_JSON.exists():
        return MODEL_PATH_JSON
    elif MODEL_PATH_PKL.exists():
        return MODEL_PATH_PKL
    elif MODEL_PATH.exists():
        return MODEL_PATH
    else:
        raise FileNotFoundError(
            f"Aucun modèle trouvé. Chemins testés :\n"
            f"  - {MODEL_PATH_JSON}\n"
            f"  - {MODEL_PATH_PKL}\n"
            f"  - {MODEL_PATH}"
        )


def check_files() -> dict:
    """
    Vérifie la présence de tous les fichiers requis.
    Retourne un dict avec le statut de chaque fichier.
    """
    files_to_check = {
        "model_json": MODEL_PATH_JSON,
        "model_pkl": MODEL_PATH_PKL,
        "model_old_pkl": MODEL_PATH,
        "preprocessor": PREPROCESSOR_PATH,
        "label_encoder": LABEL_ENCODER_PATH,
    }
    
    return {
        name: {
            "path": str(path),
            "exists": path.exists(),
            "size_mb": round(path.stat().st_size / (1024 * 1024), 2) if path.exists() else 0,
        }
        for name, path in files_to_check.items()
    }