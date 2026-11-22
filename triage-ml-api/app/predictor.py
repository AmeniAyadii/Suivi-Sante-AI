# app/predictor.py
"""
Module de prédiction du triage.
Supporte le chargement depuis JSON (robuste) et PKL (fallback).
"""
import joblib
import numpy as np
import pandas as pd
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Optional
import logging

from xgboost import XGBClassifier

from app.constants import TRIAGE_INFO, MODEL_VERSION
from app.config import (
    MODEL_PATH_JSON,
    MODEL_PATH_PKL,
    MODEL_PATH,
    PREPROCESSOR_PATH,
    LABEL_ENCODER_PATH,
    get_model_path,
)

# Logger
logger = logging.getLogger(__name__)


class TriagePredictor:
    """
    Classe de prédiction du triage.
    Charge les modèles au démarrage et effectue les prédictions.
    """

    def __init__(self):
        """Initialise les attributs et charge les modèles."""
        self.model: Optional[XGBClassifier] = None
        self.preprocessor = None
        self.label_encoder = None
        self.model_format: str = "unknown"
        self.model_path_used: Optional[Path] = None
        self._load_models()

    # ============================================
    # CHARGEMENT DES MODÈLES
    # ============================================
    def _load_models(self):
        """
        Charge tous les modèles nécessaires.
        Priorité : JSON > PKL > Ancien PKL
        """
        self._load_xgboost_model()
        self._load_preprocessor()
        self._load_label_encoder()
        
        logger.info("=" * 60)
        logger.info("✅ TOUS LES MODÈLES SONT CHARGÉS")
        logger.info(f"   Modèle      : {self.model_format}")
        logger.info(f"   Chemin      : {self.model_path_used}")
        logger.info("=" * 60)

    def _load_xgboost_model(self):
        """Charge le modèle XGBoost en essayant JSON puis PKL."""
        
        # ----- Tentative 1 : Format JSON (prioritaire) -----
        if MODEL_PATH_JSON.exists():
            try:
                logger.info(f"🔵 Tentative JSON : {MODEL_PATH_JSON.name}")
                self.model = XGBClassifier()
                self.model.load_model(str(MODEL_PATH_JSON))
                self.model_format = "JSON (XGBoost natif)"
                self.model_path_used = MODEL_PATH_JSON
                logger.info(f"✅ Modèle JSON chargé ({MODEL_PATH_JSON.stat().st_size / 1024 / 1024:.2f} MB)")
                return
            except Exception as e:
                logger.warning(f"⚠️ Échec du chargement JSON : {type(e).__name__}: {e}")
                self.model = None

        # ----- Tentative 2 : Format PKL (nouveau nom) -----
        if MODEL_PATH_PKL.exists():
            try:
                logger.info(f"🟡 Tentative PKL : {MODEL_PATH_PKL.name}")
                self.model = joblib.load(MODEL_PATH_PKL)
                self.model_format = "PKL (joblib)"
                self.model_path_used = MODEL_PATH_PKL
                logger.info(f"✅ Modèle PKL chargé ({MODEL_PATH_PKL.stat().st_size / 1024 / 1024:.2f} MB)")
                return
            except Exception as e:
                logger.warning(f"⚠️ Échec du chargement PKL : {type(e).__name__}: {e}")
                self.model = None

        # ----- Tentative 3 : Ancien PKL (fallback) -----
        if MODEL_PATH.exists():
            try:
                logger.info(f"🟠 Tentative ancien PKL : {MODEL_PATH.name}")
                self.model = joblib.load(MODEL_PATH)
                self.model_format = "PKL legacy"
                self.model_path_used = MODEL_PATH
                logger.info(f"✅ Modèle PKL legacy chargé")
                return
            except Exception as e:
                logger.warning(f"⚠️ Échec ancien PKL : {type(e).__name__}: {e}")
                self.model = None

        # ----- Échec total -----
        raise FileNotFoundError(
            f"❌ Impossible de charger le modèle XGBoost.\n"
            f"Fichiers testés :\n"
            f"  - {MODEL_PATH_JSON} (existe: {MODEL_PATH_JSON.exists()})\n"
            f"  - {MODEL_PATH_PKL} (existe: {MODEL_PATH_PKL.exists()})\n"
            f"  - {MODEL_PATH} (existe: {MODEL_PATH.exists()})\n"
            f"Vérifiez que les fichiers ne sont pas corrompus."
        )

    def _load_preprocessor(self):
        """Charge le préprocesseur (imputation + standardisation)."""
        try:
            logger.info(f"🔵 Chargement préprocesseur : {PREPROCESSOR_PATH.name}")
            self.preprocessor = joblib.load(PREPROCESSOR_PATH)
            logger.info(f"✅ Préprocesseur chargé")
        except Exception as e:
            logger.error(f"❌ Erreur préprocesseur : {type(e).__name__}: {e}")
            raise RuntimeError(f"Impossible de charger le préprocesseur : {e}")

    def _load_label_encoder(self):
        """Charge le label encoder."""
        try:
            logger.info(f"🔵 Chargement label encoder : {LABEL_ENCODER_PATH.name}")
            self.label_encoder = joblib.load(LABEL_ENCODER_PATH)
            logger.info(f"✅ Label encoder chargé (classes : {self.label_encoder.classes_})")
        except Exception as e:
            logger.error(f"❌ Erreur label encoder : {type(e).__name__}: {e}")
            raise RuntimeError(f"Impossible de charger le label encoder : {e}")

    # ============================================
    # VÉRIFICATIONS
    # ============================================
    def is_loaded(self) -> bool:
        """Vérifie que tous les modèles sont chargés."""
        return all([
            self.model is not None,
            self.preprocessor is not None,
            self.label_encoder is not None,
        ])

    def get_info(self) -> Dict[str, Any]:
        """Retourne les informations sur les modèles chargés."""
        return {
            "is_loaded": self.is_loaded(),
            "model_format": self.model_format,
            "model_path": str(self.model_path_used) if self.model_path_used else None,
            "classes": [int(c) for c in self.label_encoder.classes_] if self.label_encoder else [],
            "n_features": self.preprocessor.n_features_in_ if hasattr(self.preprocessor, 'n_features_in_') else None,
        }

    # ============================================
    # PRÉDICTION
    # ============================================
    def predict(self, patient_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Prédit le niveau de triage avec réponse enrichie.

        Args:
            patient_data: Dictionnaire des features du patient

        Returns:
            Dictionnaire avec la prédiction complète

        Raises:
            RuntimeError: Si les modèles ne sont pas chargés
            ValueError: Si les données sont invalides
        """
        if not self.is_loaded():
            raise RuntimeError("Les modèles ne sont pas chargés")

        try:
            # ----- Conversion en DataFrame -----
            df = pd.DataFrame([patient_data])

            # ----- Prétraitement -----
            X = self.preprocessor.transform(df)

            # ----- Prédiction -----
            y_pred = self.model.predict(X)[0]
            y_proba = self.model.predict_proba(X)[0]

            # ----- Décodage -----
            niveau = int(self.label_encoder.classes_[y_pred])
            info = TRIAGE_INFO[niveau]

            # ----- Probabilités par classe -----
            probabilities = {
                str(int(cls)): round(float(p), 4)
                for cls, p in zip(self.label_encoder.classes_, y_proba)
            }

            # ----- Résultat enrichi -----
            return {
                "triage_acuity": niveau,
                "confidence": round(float(y_proba.max()), 4),
                "probabilities": probabilities,
                "label": info["label"],
                "color": info["color"],
                "emoji": info["emoji"],
                "urgency": info["urgency"],
                "recommendation": info["recommendation"],
                "max_wait_minutes": info["max_wait_minutes"],
                "timestamp": datetime.now().isoformat(),
                "model_format": self.model_format,
            }

        except Exception as e:
            logger.error(f"❌ Erreur lors de la prédiction : {type(e).__name__}: {e}")
            raise


# ============================================
# SINGLETON
# ============================================
_predictor_instance: Optional[TriagePredictor] = None


def get_predictor() -> TriagePredictor:
    """Retourne l'instance unique du prédicteur (Singleton)."""
    global _predictor_instance
    if _predictor_instance is None:
        _predictor_instance = TriagePredictor()
    return _predictor_instance


# ============================================
# FONCTIONS DE COMPATIBILITÉ
# ============================================
def predict_triage(patient_data: Dict[str, Any]) -> int:
    """
    Fonction de compatibilité (retourne uniquement le niveau).
    Conserve la signature originale pour ne pas casser le code existant.
    """
    result = get_predictor().predict(patient_data)
    return result["triage_acuity"]


def predict_triage_full(patient_data: Dict[str, Any]) -> Dict[str, Any]:
    """Retourne la prédiction complète (avec probabilités et métadonnées)."""
    return get_predictor().predict(patient_data)