# Multi-stage build for optimized Docling API image
# Stage 1: Build stage with all build dependencies
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/install -r requirements.txt

# Stage 2: Runtime image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install runtime system dependencies required by Docling/OpenCV
# Using libgl1-mesa-dev as fallback for OpenGL support
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    curl \
    && (apt-get install -y --no-install-recommends libgl1 || apt-get install -y --no-install-recommends libgl1-mesa-glx || apt-get install -y --no-install-recommends libgl1-mesa-dev) \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local/lib/python3.11/site-packages

# Copy application code
COPY app/ ./app/

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DOCLING_ARTIFACTS_PATH=/models
ENV HF_HOME=/models/.cache
ENV HUGGINGFACE_HUB_CACHE=/models/.cache

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
