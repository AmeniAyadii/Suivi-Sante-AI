# app/schemas.py
"""
Schémas Pydantic pour la validation des données.
"""
from pydantic import BaseModel, Field, ConfigDict
from typing import Dict


class TriageInput(BaseModel):
    """
    Données d'entrée pour la prédiction du triage.
    Toutes les features cliniques et démographiques du patient.
    """
    
    # ============ Données démographiques ============
    age: int = Field(
        ...,
        ge=0,
        le=120,
        description="Âge du patient en années",
        examples=[45]
    )
    arrival_hour: int = Field(
        ...,
        ge=0,
        le=23,
        description="Heure d'arrivée (0-23)",
        examples=[14]
    )
    arrival_month: int = Field(
        ...,
        ge=1,
        le=12,
        description="Mois d'arrivée (1-12)",
        examples=[6]
    )
    
    # ============ Historique de consultations ============
    num_prior_ed_visits_12m: int = Field(
        ..., ge=0, le=100,
        description="Nombre de visites aux urgences dans les 12 derniers mois"
    )
    num_prior_admissions_12m: int = Field(
        ..., ge=0, le=100,
        description="Nombre d'hospitalisations dans les 12 derniers mois"
    )
    num_active_medications: int = Field(
        ..., ge=0, le=50,
        description="Nombre de médicaments actifs"
    )
    num_comorbidities: int = Field(
        ..., ge=0, le=30,
        description="Nombre de comorbidités"
    )
    
    # ============ Signes vitaux ============
    systolic_bp: float = Field(
        ..., ge=0, le=300,
        description="Tension artérielle systolique (mmHg)",
        examples=[120.0]
    )
    diastolic_bp: float = Field(
        ..., ge=0, le=200,
        description="Tension artérielle diastolique (mmHg)",
        examples=[80.0]
    )
    mean_arterial_pressure: float = Field(
        ..., ge=0, le=200,
        description="Pression artérielle moyenne (mmHg)"
    )
    pulse_pressure: float = Field(
        ..., ge=-100, le=200,
        description="Pression pulsée (mmHg)"
    )
    heart_rate: float = Field(
        ..., ge=0, le=300,
        description="Fréquence cardiaque (bpm)",
        examples=[80.0]
    )
    respiratory_rate: float = Field(
        ..., ge=0, le=100,
        description="Fréquence respiratoire (resp/min)",
        examples=[16.0]
    )
    temperature_c: float = Field(
        ..., ge=30, le=45,
        description="Température corporelle (°C)",
        examples=[37.0]
    )
    spo2: float = Field(
        ..., ge=0, le=100,
        description="Saturation en oxygène (%)",
        examples=[98.0]
    )
    
    # ============ Évaluation clinique ============
    gcs_total: int = Field(
        ..., ge=3, le=15,
        description="Score de Glasgow (3-15)",
        examples=[15]
    )
    pain_score: float = Field(
        ..., ge=-1, le=10,
        description="Score de douleur (0-10, -1 = non évalué)",
        examples=[3.0]
    )
    weight_kg: float = Field(
        ..., ge=0, le=300,
        description="Poids en kg",
        examples=[75.0]
    )
    height_cm: float = Field(
        ..., ge=0, le=250,
        description="Taille en cm",
        examples=[175.0]
    )
    bmi: float = Field(
        ..., ge=0, le=100,
        description="Indice de masse corporelle",
        examples=[24.5]
    )
    shock_index: float = Field(
        ..., ge=0, le=10,
        description="Indice de choc (FC/TAS)"
    )
    news2_score: int = Field(
        ..., ge=0, le=20,
        description="Score NEWS2 (0-20)",
        examples=[2]
    )
    
    # ============ Antécédents médicaux ============
    hx_hypertension: int = Field(..., ge=0, le=1, description="Hypertension")
    hx_diabetes_type2: int = Field(..., ge=0, le=1, description="Diabète type 2")
    hx_diabetes_type1: int = Field(..., ge=0, le=1, description="Diabète type 1")
    hx_asthma: int = Field(..., ge=0, le=1, description="Asthme")
    hx_copd: int = Field(..., ge=0, le=1, description="BPCO")
    hx_heart_failure: int = Field(..., ge=0, le=1, description="Insuffisance cardiaque")
    hx_atrial_fibrillation: int = Field(..., ge=0, le=1, description="Fibrillation auriculaire")
    hx_ckd: int = Field(..., ge=0, le=1, description="Maladie rénale chronique")
    hx_liver_disease: int = Field(..., ge=0, le=1, description="Maladie hépatique")
    hx_malignancy: int = Field(..., ge=0, le=1, description="Cancer")
    hx_obesity: int = Field(..., ge=0, le=1, description="Obésité")
    hx_depression: int = Field(..., ge=0, le=1, description="Dépression")
    hx_anxiety: int = Field(..., ge=0, le=1, description="Anxiété")
    hx_dementia: int = Field(..., ge=0, le=1, description="Démence")
    hx_epilepsy: int = Field(..., ge=0, le=1, description="Épilepsie")
    hx_hypothyroidism: int = Field(..., ge=0, le=1, description="Hypothyroïdie")
    hx_hyperthyroidism: int = Field(..., ge=0, le=1, description="Hyperthyroïdie")
    hx_hiv: int = Field(..., ge=0, le=1, description="VIH")
    hx_coagulopathy: int = Field(..., ge=0, le=1, description="Coagulopathie")
    hx_immunosuppressed: int = Field(..., ge=0, le=1, description="Immunodéprimé")
    hx_pregnant: int = Field(..., ge=0, le=1, description="Grossesse")
    hx_substance_use_disorder: int = Field(..., ge=0, le=1, description="Trouble lié aux substances")
    hx_coronary_artery_disease: int = Field(..., ge=0, le=1, description="Maladie coronarienne")
    hx_stroke_prior: int = Field(..., ge=0, le=1, description="AVC antérieur")
    hx_peripheral_vascular_disease: int = Field(..., ge=0, le=1, description="Artériopathie périphérique")
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "age": 72,
                "arrival_hour": 3,
                "arrival_month": 11,
                "num_prior_ed_visits_12m": 2,
                "num_prior_admissions_12m": 1,
                "num_active_medications": 8,
                "num_comorbidities": 5,
                "systolic_bp": 85.0,
                "diastolic_bp": 55.0,
                "mean_arterial_pressure": 65.0,
                "pulse_pressure": 30.0,
                "heart_rate": 125.0,
                "respiratory_rate": 28.0,
                "temperature_c": 36.8,
                "spo2": 89.0,
                "gcs_total": 14,
                "pain_score": 9.0,
                "weight_kg": 78.0,
                "height_cm": 172.0,
                "bmi": 26.4,
                "shock_index": 1.47,
                "news2_score": 10,
                "hx_hypertension": 1,
                "hx_diabetes_type2": 1,
                "hx_diabetes_type1": 0,
                "hx_asthma": 0,
                "hx_copd": 0,
                "hx_heart_failure": 1,
                "hx_atrial_fibrillation": 0,
                "hx_ckd": 1,
                "hx_liver_disease": 0,
                "hx_malignancy": 0,
                "hx_obesity": 0,
                "hx_depression": 0,
                "hx_anxiety": 0,
                "hx_dementia": 0,
                "hx_epilepsy": 0,
                "hx_hypothyroidism": 0,
                "hx_hyperthyroidism": 0,
                "hx_hiv": 0,
                "hx_coagulopathy": 0,
                "hx_immunosuppressed": 0,
                "hx_pregnant": 0,
                "hx_substance_use_disorder": 0,
                "hx_coronary_artery_disease": 1,
                "hx_stroke_prior": 0,
                "hx_peripheral_vascular_disease": 0,
            }
        }
    )


class TriageResponse(BaseModel):
    """
    Réponse enrichie de la prédiction du triage.
    """
    triage_acuity: int = Field(..., ge=1, le=5, description="Niveau de triage (1-5)")
    confidence: float = Field(..., ge=0, le=1, description="Confiance du modèle (0-1)")
    probabilities: Dict[str, float] = Field(..., description="Probabilités par classe")
    label: str = Field(..., description="Libellé du niveau")
    color: str = Field(..., description="Couleur hex pour l'affichage")
    emoji: str = Field(..., description="Emoji pour l'affichage")
    urgency: str = Field(..., description="Niveau d'urgence (critical, high, medium, low, non-urgent)")
    recommendation: str = Field(..., description="Recommandation clinique")
    max_wait_minutes: int = Field(..., description="Délai maximal d'attente en minutes")
    timestamp: str = Field(..., description="Horodatage de la prédiction")


class HealthResponse(BaseModel):
    """Réponse du endpoint /health."""
    status: str
    model_loaded: bool
    version: str