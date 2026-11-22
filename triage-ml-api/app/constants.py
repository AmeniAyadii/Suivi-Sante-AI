# app/constants.py
"""
Constantes et métadonnées de l'application.
"""

# Métadonnées des niveaux de triage
TRIAGE_INFO = {
    1: {
        "label": "Réanimation",
        "color": "#e74c3c",
        "emoji": "🚨",
        "urgency": "critical",
        "recommendation": "Prise en charge IMMÉDIATE",
        "max_wait_minutes": 0,
    },
    2: {
        "label": "Urgent",
        "color": "#e67e22",
        "emoji": "⚠️",
        "urgency": "high",
        "recommendation": "Prise en charge dans les 15-30 minutes",
        "max_wait_minutes": 30,
    },
    3: {
        "label": "Semi-urgent",
        "color": "#f39c12",
        "emoji": "🟡",
        "urgency": "medium",
        "recommendation": "Prise en charge dans les 30-60 minutes",
        "max_wait_minutes": 60,
    },
    4: {
        "label": "Standard",
        "color": "#3498db",
        "emoji": "🔵",
        "urgency": "low",
        "recommendation": "Prise en charge dans les 1-2 heures",
        "max_wait_minutes": 120,
    },
    5: {
        "label": "Non-urgent",
        "color": "#27ae60",
        "emoji": "🟢",
        "urgency": "non-urgent",
        "recommendation": "Peut attendre / orientation médecin traitant",
        "max_wait_minutes": 240,
    },
}

# Version de l'API
API_VERSION = "1.0.0"
MODEL_VERSION = "1.0.0"