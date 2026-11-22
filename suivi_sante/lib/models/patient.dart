// lib/models/patient.dart
// Modèle représentant les données d'un patient

class Patient {
  final int age;
  final int arrivalHour;
  final int arrivalMonth;
  final int numPriorEdVisits12m;
  final int numPriorAdmissions12m;
  final int numActiveMedications;
  final int numComorbidities;
  final double systolicBp;
  final double diastolicBp;
  final double meanArterialPressure;
  final double pulsePressure;
  final double heartRate;
  final double respiratoryRate;
  final double temperatureC;
  final double spo2;
  final int gcsTotal;
  final double painScore;
  final double weightKg;
  final double heightCm;
  final double bmi;
  final double shockIndex;
  final int news2Score;
  
  // Antécédents
  final int hxHypertension;
  final int hxDiabetesType2;
  final int hxDiabetesType1;
  final int hxAsthma;
  final int hxCopd;
  final int hxHeartFailure;
  final int hxAtrialFibrillation;
  final int hxCkd;
  final int hxLiverDisease;
  final int hxMalignancy;
  final int hxObesity;
  final int hxDepression;
  final int hxAnxiety;
  final int hxDementia;
  final int hxEpilepsy;
  final int hxHypothyroidism;
  final int hxHyperthyroidism;
  final int hxHiv;
  final int hxCoagulopathy;
  final int hxImmunosuppressed;
  final int hxPregnant;
  final int hxSubstanceUseDisorder;
  final int hxCoronaryArteryDisease;
  final int hxStrokePrior;
  final int hxPeripheralVascularDisease;

  Patient({
    required this.age,
    required this.arrivalHour,
    required this.arrivalMonth,
    required this.numPriorEdVisits12m,
    required this.numPriorAdmissions12m,
    required this.numActiveMedications,
    required this.numComorbidities,
    required this.systolicBp,
    required this.diastolicBp,
    required this.meanArterialPressure,
    required this.pulsePressure,
    required this.heartRate,
    required this.respiratoryRate,
    required this.temperatureC,
    required this.spo2,
    required this.gcsTotal,
    required this.painScore,
    required this.weightKg,
    required this.heightCm,
    required this.bmi,
    required this.shockIndex,
    required this.news2Score,
    this.hxHypertension = 0,
    this.hxDiabetesType2 = 0,
    this.hxDiabetesType1 = 0,
    this.hxAsthma = 0,
    this.hxCopd = 0,
    this.hxHeartFailure = 0,
    this.hxAtrialFibrillation = 0,
    this.hxCkd = 0,
    this.hxLiverDisease = 0,
    this.hxMalignancy = 0,
    this.hxObesity = 0,
    this.hxDepression = 0,
    this.hxAnxiety = 0,
    this.hxDementia = 0,
    this.hxEpilepsy = 0,
    this.hxHypothyroidism = 0,
    this.hxHyperthyroidism = 0,
    this.hxHiv = 0,
    this.hxCoagulopathy = 0,
    this.hxImmunosuppressed = 0,
    this.hxPregnant = 0,
    this.hxSubstanceUseDisorder = 0,
    this.hxCoronaryArteryDisease = 0,
    this.hxStrokePrior = 0,
    this.hxPeripheralVascularDisease = 0,
  });

  /// Convertit le patient en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      "age": age,
      "arrival_hour": arrivalHour,
      "arrival_month": arrivalMonth,
      "num_prior_ed_visits_12m": numPriorEdVisits12m,
      "num_prior_admissions_12m": numPriorAdmissions12m,
      "num_active_medications": numActiveMedications,
      "num_comorbidities": numComorbidities,
      "systolic_bp": systolicBp,
      "diastolic_bp": diastolicBp,
      "mean_arterial_pressure": meanArterialPressure,
      "pulse_pressure": pulsePressure,
      "heart_rate": heartRate,
      "respiratory_rate": respiratoryRate,
      "temperature_c": temperatureC,
      "spo2": spo2,
      "gcs_total": gcsTotal,
      "pain_score": painScore,
      "weight_kg": weightKg,
      "height_cm": heightCm,
      "bmi": bmi,
      "shock_index": shockIndex,
      "news2_score": news2Score,
      "hx_hypertension": hxHypertension,
      "hx_diabetes_type2": hxDiabetesType2,
      "hx_diabetes_type1": hxDiabetesType1,
      "hx_asthma": hxAsthma,
      "hx_copd": hxCopd,
      "hx_heart_failure": hxHeartFailure,
      "hx_atrial_fibrillation": hxAtrialFibrillation,
      "hx_ckd": hxCkd,
      "hx_liver_disease": hxLiverDisease,
      "hx_malignancy": hxMalignancy,
      "hx_obesity": hxObesity,
      "hx_depression": hxDepression,
      "hx_anxiety": hxAnxiety,
      "hx_dementia": hxDementia,
      "hx_epilepsy": hxEpilepsy,
      "hx_hypothyroidism": hxHypothyroidism,
      "hx_hyperthyroidism": hxHyperthyroidism,
      "hx_hiv": hxHiv,
      "hx_coagulopathy": hxCoagulopathy,
      "hx_immunosuppressed": hxImmunosuppressed,
      "hx_pregnant": hxPregnant,
      "hx_substance_use_disorder": hxSubstanceUseDisorder,
      "hx_coronary_artery_disease": hxCoronaryArteryDisease,
      "hx_stroke_prior": hxStrokePrior,
      "hx_peripheral_vascular_disease": hxPeripheralVascularDisease,
    };
  }
}