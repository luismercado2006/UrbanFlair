@echo off
cd /d %~dp0

REM Entrena el modelo solo si todavia no existe
if not exist backend\modelo_guardado (
  echo Entrenando modelo...
  cd backend
  call .venv\Scripts\activate
  python modelo.py
  cd ..
)

REM Backend en una ventana aparte
start "Backend" cmd /k "cd backend && .venv\Scripts\activate && uvicorn api:app --reload --port 8000"

REM Espera unos segundos a que arranque la API
timeout /t 6 >nul

REM Flutter
flutter run -d chrome --web-port=5000