"""
Red neuronal (Keras / TensorFlow) que predice las unidades vendidas por
categoría en los meses siguientes.

La red aprende SOLA a partir de los datos de entrada y de salida:
  - Entrada : categoría + ventas de los 2 meses anteriores
  - Salida  : unidades vendidas del mes

El script prueba varias arquitecturas (número de capas y neuronas), las VALIDA
con los últimos meses y se queda con la mejor. Además guarda el MAE/MAPE
(global y POR CATEGORÍA) y la curva de pérdida del entrenamiento final.

Datos: datos/ventas_mensuales.csv
  columnas: categoria, marca, color, talla, valor_producto, porcentaje_ganancia,
            stock, mes, ventas_mes_anterior, rotacion
  La columna 'ventas_mes_anterior' de las filas de un mes M contiene las ventas
  del mes M-1. Por eso se suma por categoría y se desplaza un mes atrás:
  filas de "febrero" -> ventas de enero, ..., filas de "noviembre" -> octubre.
"""
import hashlib
import json
import os
import threading
from datetime import date
from pathlib import Path

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras

BASE = Path(__file__).parent
RUTA_DATOS = BASE / "datos" / "ventas_mensuales.csv"
RUTA_MODELO = BASE / "modelo_guardado"

TOTAL = "Ventas totales"
ANIO = 2026           # el CSV no trae año
N_LAGS = 2            # meses anteriores que ve la red
MESES_VALIDACION = 2  # últimos meses de cada categoría reservados para validar
ARQUITECTURAS = [(4,), (8,), (16,), (8, 4)]
EPOCAS = 200          # iteraciones de entrenamiento (candidatas y modelo final)
BATCH = 16
MESES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
         "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
NUM_MES = {"enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5,
           "junio": 6, "julio": 7, "agosto": 8, "septiembre": 9,
           "setiembre": 9, "octubre": 10, "noviembre": 11, "diciembre": 12}


def etiqueta_mes(fecha: str) -> str:
    return MESES[int(fecha.split("-")[1]) - 1]


def siguiente_mes(fecha: str) -> str:
    anio, mes = map(int, fecha.split("-"))
    anio, mes = (anio + 1, 1) if mes == 12 else (anio, mes + 1)
    return f"{anio:04d}-{mes:02d}"


def mes_actual() -> str:
    hoy = date.today()
    return f"{hoy.year:04d}-{hoy.month:02d}"


def cargar_datos() -> pd.DataFrame:
    """Devuelve la serie mensual: fecha (YYYY-MM), categoria, unidades_vendidas."""
    df = pd.read_csv(RUTA_DATOS, encoding="utf-8")
    df["mes_num"] = df["mes"].astype(str).str.strip().str.lower().map(NUM_MES)
    if df["mes_num"].isna().any():
        raros = df.loc[df["mes_num"].isna(), "mes"].unique().tolist()
        raise ValueError(f"Meses no reconocidos en el CSV: {raros}")
    # Las ventas de las filas del mes M corresponden al mes M-1
    df["mes_ventas"] = df["mes_num"] - 1
    df = df[df["mes_ventas"] >= 1]
    serie = (df.groupby(["categoria", "mes_ventas"], as_index=False)
               ["ventas_mes_anterior"].sum())
    serie["fecha"] = serie["mes_ventas"].map(lambda m: f"{ANIO:04d}-{m:02d}")
    serie = serie.rename(columns={"ventas_mes_anterior": "unidades_vendidas"})
    serie = serie[["fecha", "categoria", "unidades_vendidas"]]
    return serie.sort_values(["categoria", "fecha"]).reset_index(drop=True)


def _huella() -> str:
    """Identifica los datos + la configuración del entrenamiento. Si cambia el
    CSV o algún parámetro, el modelo guardado ya no corresponde y se reentrena."""
    h = hashlib.sha256()
    h.update(RUTA_DATOS.read_bytes())
    h.update(repr((ARQUITECTURAS, EPOCAS, N_LAGS, MESES_VALIDACION, BATCH)).encode())
    return h.hexdigest()


def _codificar(categoria: str, lags, categorias, mu, sd) -> np.ndarray:
    uno = [1.0 if c == categoria else 0.0 for c in categorias]
    return np.array(uno + [(v - mu) / sd for v in lags], dtype="float32")


def _muestras(df: pd.DataFrame, categorias, mu, sd):
    """Una muestra por (categoría, mes): entradas = categoría + N_LAGS meses
    previos; salida = ventas del mes. 'orden' es la posición del mes (0..)."""
    X, y, orden, cat = [], [], [], []
    for c in categorias:
        v = df[df.categoria == c].unidades_vendidas.tolist()
        for t in range(N_LAGS, len(v)):
            X.append(_codificar(c, v[t - N_LAGS:t], categorias, mu, sd))
            y.append((v[t] - mu) / sd)
            orden.append(t)
            cat.append(c)
    return np.array(X), np.array(y, dtype="float32"), np.array(orden), cat


def _construir(entradas: int, capas, lr=0.003) -> keras.Model:
    m = keras.Sequential([keras.layers.Input(shape=(entradas,))])
    for n in capas:
        m.add(keras.layers.Dense(n, activation="relu"))
    m.add(keras.layers.Dense(1))
    m.compile(optimizer=keras.optimizers.Adam(lr), loss="mse")
    return m


def entrenar(verbose: bool = True) -> dict:
    keras.utils.set_random_seed(42)
    df = cargar_datos()
    categorias = sorted(df.categoria.unique().tolist())
    mu = float(df.unidades_vendidas.mean())
    sd = float(df.unidades_vendidas.std()) or 1.0

    X, y, orden, cat = _muestras(df, categorias, mu, sd)
    # Validación "hacia adelante": se valida con los meses MÁS RECIENTES,
    # que es lo que la red tendrá que predecir en la vida real.
    max_orden = {c: max(o for o, k in zip(orden, cat) if k == c) for c in categorias}
    es_val = np.array([o > max_orden[k] - MESES_VALIDACION for o, k in zip(orden, cat)])
    Xtr, ytr, Xva, yva = X[~es_val], y[~es_val], X[es_val], y[es_val]
    if len(Xtr) < 4 or len(Xva) < 2:
        raise ValueError("Hay muy pocos meses de historia para entrenar y validar.")

    # Referencia: repetir el mes anterior (si la red no lo supera, no aporta).
    lag1 = Xva[:, len(categorias) + N_LAGS - 1]
    mae_base = float(np.mean(np.abs(lag1 - yva)) * sd)

    resultados = []
    preds = {}  # predicciones de validación de cada arquitectura candidata
    for capas in ARQUITECTURAS:
        keras.utils.set_random_seed(42)
        m = _construir(X.shape[1], capas)
        m.fit(Xtr, ytr, validation_data=(Xva, yva), epochs=EPOCAS,
              batch_size=BATCH, verbose=0)
        pred = m.predict(Xva, verbose=0)[:, 0] * sd + mu
        real = yva * sd + mu
        preds[tuple(capas)] = (pred, real)
        mae = float(np.mean(np.abs(pred - real)))
        mape = float(np.mean(np.abs(pred - real) / np.maximum(real, 1)) * 100)
        resultados.append({"capas": list(capas),
                           "mae_validacion": round(mae, 2),
                           "mape_validacion": round(mape, 2),
                           "epocas": EPOCAS})
        if verbose:
            print(f"  capas={capas!s:9} MAE={mae:7.2f}  MAPE={mape:5.1f}%  épocas={EPOCAS}")

    mejor = min(resultados, key=lambda r: r["mae_validacion"])

    # Métricas POR CATEGORÍA (con la mejor arquitectura)
    pred_m, real_m = preds[tuple(mejor["capas"])]
    cat_va = np.array(cat)[es_val]
    lag1_orig = lag1 * sd + mu
    por_cat = {}
    for c in categorias:
        mk = cat_va == c
        if not mk.any():
            continue
        err = np.abs(pred_m[mk] - real_m[mk])
        por_cat[c] = {
            "mae": round(float(err.mean()), 2),
            "mape": round(float(np.mean(err / np.maximum(real_m[mk], 1)) * 100), 2),
            "mae_referencia": round(float(np.mean(np.abs(lag1_orig[mk] - real_m[mk]))), 2),
        }

    # Modelo final: misma arquitectura, entrenado con TODOS los meses.
    keras.utils.set_random_seed(42)
    final = _construir(X.shape[1], mejor["capas"])
    h = final.fit(X, y, epochs=EPOCAS, batch_size=BATCH, verbose=0,
                  callbacks=[keras.callbacks.ReduceLROnPlateau(
                      monitor="loss", factor=0.5, patience=10, min_lr=1e-4)])
    curva = [round(float(v), 5) for v in h.history["loss"]]

    RUTA_MODELO.mkdir(exist_ok=True)
    final.save(RUTA_MODELO / "modelo.keras")
    info = {
        "categorias": categorias, "mu": mu, "sd": sd,
        "arquitectura_elegida": mejor["capas"],
        "mae_validacion": mejor["mae_validacion"],
        "mape_validacion": mejor["mape_validacion"],
        "mae_referencia_mes_anterior": round(mae_base, 2),
        "metricas_por_categoria": por_cat,
        "iteraciones": EPOCAS,
        "huella": _huella(),
        "curva_perdida": curva,
        "candidatas": resultados,
        "muestras_entrenamiento": int(len(Xtr)),
        "muestras_validacion": int(len(Xva)),
        "meses_historia": int(df.groupby("categoria").size().min()),
        "meses_historia_por_categoria": {
            k: int(v) for k, v in df.groupby("categoria").size().items()},
    }
    (RUTA_MODELO / "info.json").write_text(json.dumps(info, indent=2))
    if verbose:
        print(f"\nElegida: {mejor['capas']}  MAE={mejor['mae_validacion']}  "
              f"MAPE={mejor['mape_validacion']}%  "
              f"(referencia mes anterior: {mae_base:.2f})")
        for c, mtr in por_cat.items():
            print(f"  {c:10} MAE={mtr['mae']:6.2f}  MAPE={mtr['mape']:5.1f}%")
    return info


class Predictor:
    """Arranca al instante: carga el modelo guardado si existe y, si los datos
    cambiaron, lo actualiza en segundo plano (ver reentrenar_si_cambio)."""

    def __init__(self):
        self._lock = threading.Lock()
        self.entrenando = False
        self.modelo = None
        self.info = None
        self.df = cargar_datos()
        self._intentar_cargar()

    @property
    def listo(self) -> bool:
        return self.modelo is not None and self.info is not None

    def _intentar_cargar(self) -> bool:
        ruta_info = RUTA_MODELO / "info.json"
        ruta_modelo = RUTA_MODELO / "modelo.keras"
        if not ruta_info.exists() or not ruta_modelo.exists():
            return False
        try:
            info = json.loads(ruta_info.read_text())
            modelo = keras.models.load_model(ruta_modelo)
        except Exception:
            return False
        if ("curva_perdida" not in info
                or set(info.get("categorias", [])) != set(self.df.categoria.unique())):
            return False  # modelo de otro dataset: no sirve
        self.df = cargar_datos()
        self.modelo, self.info = modelo, info
        return True

    def reentrenar(self):
        with self._lock:
            self.entrenando = True
            try:
                entrenar(verbose=False)
                if not self._intentar_cargar():
                    raise RuntimeError("No se pudo cargar el modelo recién entrenado")
            finally:
                self.entrenando = False

    def reentrenar_si_cambio(self) -> bool:
        """Entrena solo si no hay modelo o si el CSV/configuración cambió."""
        if self.listo and self.info.get("huella") == _huella():
            return False
        print("Actualizando el modelo en segundo plano (la API ya responde)...")
        self.reentrenar()
        print("Modelo actualizado.")
        return True

    def historial(self, categoria: str):
        if categoria == TOTAL:
            s = self.df.groupby("fecha").unidades_vendidas.sum()
            pares = list(zip(s.index, s.values))
        else:
            d = self.df[self.df.categoria == categoria]
            pares = list(zip(d.fecha, d.unidades_vendidas))
        return [{"fecha": f, "mes": etiqueta_mes(f), "unidades": int(u)}
                for f, u in pares]

    def _predecir_categoria(self, categoria: str, meses: int):
        i = self.info
        d = self.df[self.df.categoria == categoria]
        valores = d.unidades_vendidas.astype(float).tolist()
        fecha = d.fecha.iloc[-1]
        # La predicción que se muestra arranca en el mes actual (hoy). Si el
        # historial termina antes, los meses intermedios se predicen igual
        # (alimentan la red) pero no se devuelven.
        inicio = max(siguiente_mes(fecha), mes_actual())
        salida = []
        while len(salida) < meses:  # cada predicción alimenta la siguiente
            x = _codificar(categoria, valores[-N_LAGS:], i["categorias"], i["mu"], i["sd"])
            p = float(self.modelo.predict(x[None, :], verbose=0)[0, 0]) * i["sd"] + i["mu"]
            p = max(0.0, p)
            valores.append(p)
            fecha = siguiente_mes(fecha)
            if fecha >= inicio:
                salida.append({"fecha": fecha, "mes": etiqueta_mes(fecha),
                               "unidades": round(p, 1)})
        return salida

    def predecir(self, categoria: str, meses: int):
        if categoria == TOTAL:
            por_cat = [self._predecir_categoria(c, meses)
                       for c in self.info["categorias"]]
            return [{"fecha": fila[0]["fecha"], "mes": fila[0]["mes"],
                     "unidades": round(sum(x["unidades"] for x in fila), 1)}
                    for fila in zip(*por_cat)]
        if categoria not in self.info["categorias"]:
            raise KeyError(categoria)
        return self._predecir_categoria(categoria, meses)


if __name__ == "__main__":
    print("Entrenando red neuronal y validando arquitecturas...")
    entrenar()