# STAGE 1 : Builder
# On utilise une image Python légère pour installer les dépendances
FROM python:3.12-slim AS builder

WORKDIR /build

# Création d'un environnement virtuel isolé
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Installation des dépendances de production uniquement
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# STAGE 2 : Runtime
# On repart d'une image vierge et légère
FROM python:3.12-slim AS runtime

# Création d'un utilisateur et groupe non-root (appuser)
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# On copie uniquement l'environnement virtuel compilé depuis le stage 1
COPY --from=builder /opt/venv /opt/venv

# On copie le code de l'API et les modèles entraînés en donnant les droits à appuser
COPY --chown=appuser:appgroup app/ ./app/
COPY --chown=appuser:appgroup models/ ./models/

# Configuration des variables d'environnement Python
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Bascule vers l'utilisateur non-root
USER appuser

# Port exposé par FastAPI
EXPOSE 8000

# Lancement du serveur Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]