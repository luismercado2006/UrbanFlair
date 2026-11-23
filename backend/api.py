"""API que consume la app Flutter.  Ejecutar:  uvicorn api:app --port 8000"""
import os
import threading
import time
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from modelo import Predictor, TOTAL

app = FastAPI(title="Urban Flair - Predicción de ventas")
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_methods=["*"], allow_headers=["*"])

predictor = Predictor()  # arranca al instante; no entrena aquí

INTERVALO_REVISION = int(os.environ.get("REVISION_SEGUNDOS", "60"))


def _vigilar_datos():
    """Al iniciar y luego cada cierto tiempo: si falta el modelo o el CSV
    cambió, reentrena en segundo plano sin bloquear el servidor."""
    while True:
        try:
            predictor.reentrenar_si_cambio()
        except Exception as e:  # nunca tumbar el servidor por esto
            print(f"Error al revisar/reentrenar: {e}")
        time.sleep(INTERVALO_REVISION)


@app.on_event("startup")
def _iniciar_vigilancia():
    threading.Thread(target=_vigilar_datos, daemon=True).start()


def _requiere_modelo():
    if not predictor.listo:
        raise HTTPException(503, "El modelo se está entrenando por primera vez, "
                                 "intenta de nuevo en un momento.")


def _metricas(categoria: Optional[str] = None):
    """Métricas de la categoría pedida. Para 'Ventas totales' (o si no hay
    métricas de esa categoría) se devuelven las globales."""
    i = predictor.info
    pc = i.get("metricas_por_categoria", {}).get(categoria)
    return {
        "arquitectura": i["arquitectura_elegida"],
        "error_medio": pc["mae"] if pc else i["mae_validacion"],
        "mape": pc["mape"] if pc else i["mape_validacion"],
        "error_referencia": pc["mae_referencia"] if pc else i["mae_referencia_mes_anterior"],
        "meses_historia": i.get("meses_historia_por_categoria", {}).get(
            categoria, i["meses_historia"]),
        "muestras_entrenamiento": i["muestras_entrenamiento"],
        "iteraciones": i["iteraciones"],
        "curva_perdida": i["curva_perdida"],
    }


@app.get("/salud")
def salud():
    return {"ok": True, "modelo_listo": predictor.listo,
            "entrenando": predictor.entrenando}


@app.get("/categorias")
def categorias():
    _requiere_modelo()
    return [TOTAL] + predictor.info["categorias"]


@app.get("/predecir")
def predecir(categoria: str, meses: int = Query(6, ge=1, le=24)):
    _requiere_modelo()
    try:
        pred = predictor.predecir(categoria, meses)
    except KeyError:
        raise HTTPException(404, f"Categoría desconocida: {categoria}")
    return {"categoria": categoria,
            "historial": predictor.historial(categoria),
            "prediccion": pred,
            "total_unidades": round(sum(p["unidades"] for p in pred), 1),
            "metricas": _metricas(categoria)}


@app.post("/reentrenar")
def reentrenar():
    predictor.reentrenar()
    return _metricas()