# app/main.py
"""
API FastAPI pour la classification intelligente du triage.
"""
import logging
import time
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import (
    API_TITLE,
    API_DESCRIPTION,
    API_VERSION,
    ALLOWED_ORIGINS,
    LOG_LEVEL,
)
from app.constants import MODEL_VERSION
from app.schemas import TriageInput, TriageResponse, HealthResponse
from app.predictor import get_predictor, predict_triage_full


# ============================================
# Configuration du logging
# ============================================
logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


# ============================================
# Cycle de vie de l'application
# ============================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Chargement et nettoyage des ressources."""
    # Startup
    logger.info("🚀 Démarrage de l'API Triage ML...")
    try:
        predictor = get_predictor()
        if predictor.is_loaded():
            logger.info("✅ Modèles chargés avec succès")
        else:
            logger.error("❌ Échec du chargement des modèles")
    except Exception as e:
        logger.error(f"❌ Erreur au démarrage : {e}")
    
    yield
    
    # Shutdown
    logger.info("🛑 Arrêt de l'API Triage ML...")


# ============================================
# Création de l'application FastAPI
# ============================================
app = FastAPI(
    title=API_TITLE,
    description=API_DESCRIPTION,
    version=API_VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    contact={
        "name": "Projet PFE - Triagegeist",
        "email": "votre.email@example.com",
    },
    license_info={
        "name": "MIT",
    },
)


# ============================================
# Middleware CORS (pour Flutter et autres clients)
# ============================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


# ============================================
# Middleware de logging des requêtes
# ============================================
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log toutes les requêtes avec leur durée."""
    start_time = time.time()
    
    # Log entrée
    logger.info(f"📥 {request.method} {request.url.path}")
    
    # Traiter la requête
    try:
        response = await call_next(request)
    except Exception as e:
        logger.error(f"❌ Erreur lors du traitement : {e}")
        raise
    
    # Log sortie
    duration = time.time() - start_time
    logger.info(
        f"📤 {request.method} {request.url.path} "
        f"→ {response.status_code} ({duration*1000:.2f}ms)"
    )
    
    # Ajouter le temps de traitement dans les headers
    response.headers["X-Process-Time-Ms"] = f"{duration*1000:.2f}"
    
    return response


# ============================================
# Gestion globale des erreurs
# ============================================
@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    """Gestion des erreurs de validation."""
    logger.warning(f"⚠️ Erreur de validation : {exc}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Données invalides",
            "detail": str(exc),
            "timestamp": datetime.now().isoformat(),
        }
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Gestion des erreurs générales."""
    logger.error(f"❌ Erreur interne : {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Erreur interne du serveur",
            "detail": str(exc),
            "timestamp": datetime.now().isoformat(),
        }
    )


# ============================================
# ROUTES
# ============================================

@app.get(
    "/",
    tags=["Informations"],
    summary="Racine de l'API",
    description="Retourne les informations générales sur l'API.",
)
def root():
    """Endpoint racine."""
    return {
        "name": API_TITLE,
        "version": API_VERSION,
        "model_version": MODEL_VERSION,
        "description": "API de classification du niveau de triage aux urgences",
        "status": "running",
        "endpoints": {
            "health": "GET /health",
            "predict": "POST /predict",
            "model_info": "GET /model-info",
            "docs": "GET /docs",
            "redoc": "GET /redoc",
        },
    }


@app.get(
    "/health",
    response_model=HealthResponse,
    tags=["Monitoring"],
    summary="Vérification de l'état du serveur",
    description="Vérifie que le serveur et le modèle sont opérationnels.",
)
def health():
    """Health check endpoint."""
    try:
        predictor = get_predictor()
        is_loaded = predictor.is_loaded()
    except Exception:
        is_loaded = False
    
    return HealthResponse(
        status="ok" if is_loaded else "degraded",
        model_loaded=is_loaded,
        version=API_VERSION,
    )


@app.get(
    "/model-info",
    tags=["Informations"],
    summary="Informations sur le modèle",
    description="Retourne les métadonnées du modèle ML.",
)
def model_info():
    """Informations détaillées sur le modèle."""
    return {
        "model_name": "XGBoost optimisé",
        "model_version": MODEL_VERSION,
        "n_features": 47,
        "n_classes": 5,
        "classes": [1, 2, 3, 4, 5],
        "class_labels": {
            1: "Réanimation",
            2: "Urgent",
            3: "Semi-urgent",
            4: "Standard",
            5: "Non-urgent",
        },
        "training_info": {
            "dataset_size": 80000,
            "validation_size": 12000,
            "test_size": 12000,
            "f1_score_validation": 0.8495,
            "hyperparameters": {
                "n_estimators": 300,
                "max_depth": 3,
                "learning_rate": 0.1,
                "subsample": 0.7,
                "colsample_bytree": 0.7,
                "gamma": 0.2,
            },
        },
        "performance": {
            "f1_weighted": 0.8361,
            "accuracy": 0.8353,
        },
    }


@app.post(
    "/predict",
    response_model=TriageResponse,
    tags=["Prédiction"],
    summary="Prédire le niveau de triage",
    description="""
    Prédit le niveau de triage (1-5) pour un patient donné
    en fonction de ses données cliniques et démographiques.
    
    **Retourne :**
    - Le niveau de triage (1-5)
    - La confiance du modèle
    - Les probabilités par classe
    - Le libellé et la couleur pour l'affichage
    - Une recommandation clinique
    """,
)
def predict(data: TriageInput) -> TriageResponse:
    """
    Endpoint de prédiction du triage.
    
    Args:
        data: Données du patient validées par Pydantic
        
    Returns:
        TriageResponse avec la prédiction complète
    """
    try:
        # Log
        logger.info(f"🩺 Prédiction demandée pour patient de {data.age} ans")
        
        # Prédiction
        result = predict_triage_full(data.model_dump())
        
        # Log résultat
        logger.info(
            f"✅ Prédiction : Niveau {result['triage_acuity']} "
            f"({result['label']}) — Confiance : {result['confidence']*100:.1f}%"
        )
        
        return TriageResponse(**result)
    
    except Exception as e:
        logger.error(f"❌ Erreur de prédiction : {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la prédiction : {str(e)}"
        )


# ============================================
# Point d'entrée pour le développement
# ============================================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level=LOG_LEVEL.lower(),
    )