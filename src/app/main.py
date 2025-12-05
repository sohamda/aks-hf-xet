"""
Docling Model API Server

This FastAPI application serves the Docling model from persistent storage.
The model is pre-downloaded to Azure Files using Xet for optimized transfer.
"""

import os
import logging
from typing import Optional
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Model configuration - DOCLING_ARTIFACTS_PATH is read by Docling automatically
ARTIFACTS_PATH = os.getenv("DOCLING_ARTIFACTS_PATH", "/models")

# Global state
model_loaded = False
docling_converter = None


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_path: str


class ConversionResponse(BaseModel):
    status: str
    message: str
    result: Optional[dict] = None


def check_model_exists():
    """Check if the model files exist in the persistent storage."""
    # Check for Docling's expected folder structure
    tableformer_dir = Path(ARTIFACTS_PATH) / "docling-project--docling-models"
    layout_dir = Path(ARTIFACTS_PATH) / "docling-project--docling-layout-heron"
    tableformer_marker = tableformer_dir / ".download_complete"
    layout_marker = layout_dir / ".download_complete"
    return tableformer_dir.exists() and tableformer_marker.exists() and layout_dir.exists() and layout_marker.exists()


def initialize_docling():
    """Initialize the Docling converter with the downloaded model."""
    global docling_converter, model_loaded
    
    try:
        if not check_model_exists():
            logger.warning(f"Models not found at {ARTIFACTS_PATH}")
            return False
        
        from docling.document_converter import DocumentConverter
        from docling.datamodel.base_models import InputFormat
        from docling.datamodel.pipeline_options import PdfPipelineOptions
        from docling.document_converter import PdfFormatOption
        
        # Log the artifacts path
        logger.info(f"DOCLING_ARTIFACTS_PATH = {ARTIFACTS_PATH}")
        
        # List contents of artifacts directory for debugging
        artifacts_path = Path(ARTIFACTS_PATH)
        logger.info(f"Contents of {ARTIFACTS_PATH}:")
        for item in artifacts_path.iterdir():
            logger.info(f"  - {item.name}")
        
        # Configure pipeline options
        # Docling will automatically find models in DOCLING_ARTIFACTS_PATH
        pipeline_options = PdfPipelineOptions()
        pipeline_options.do_ocr = False  # Disable OCR (no OCR engine installed)
        pipeline_options.do_table_structure = True  # We have tableformer models
        pipeline_options.table_structure_options.do_cell_matching = True
        pipeline_options.artifacts_path = artifacts_path
        
        logger.info(f"Using artifacts from {artifacts_path}")
        
        # Initialize converter
        docling_converter = DocumentConverter(
            format_options={
                InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
            }
        )
        model_loaded = True
        logger.info(f"Docling converter initialized successfully")
        return True
    except ImportError as e:
        logger.error(f"Docling not available - package not installed: {e}")
        model_loaded = False
        return False
    except Exception as e:
        logger.error(f"Failed to initialize Docling: {e}")
        import traceback
        logger.error(traceback.format_exc())
        model_loaded = False
        return False


app = FastAPI(
    title="Docling Model API",
    description="API for document processing using Docling models from persistent Azure Files storage",
    version="1.0.0",
)


@app.on_event("startup")
async def startup_event():
    """Initialize the model on startup."""
    logger.info("Starting Docling Model API Server...")
    logger.info(f"Artifacts path: {ARTIFACTS_PATH}")
    
    if check_model_exists():
        logger.info("Models found in persistent storage")
        initialize_docling()
    else:
        logger.warning("Models not yet available - waiting for download job to complete")


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    model_exists = check_model_exists()
    return HealthResponse(
        status="healthy" if model_exists else "waiting",
        model_loaded=model_loaded,
        model_path=ARTIFACTS_PATH,
    )


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": "Docling Model API",
        "version": "1.0.0",
        "artifacts_path": ARTIFACTS_PATH,
        "model_loaded": model_loaded,
        "model_exists": check_model_exists(),
        "endpoints": {
            "health": "/health",
            "convert": "/convert",
            "info": "/info",
            "files": "/files",
        },
    }


@app.get("/info")
async def model_info():
    """Get information about the loaded model."""
    artifacts_dir = Path(ARTIFACTS_PATH)
    tableformer_dir = artifacts_dir / "docling-project--docling-models"
    files = []
    if tableformer_dir.exists():
        files = [f.name for f in tableformer_dir.iterdir() if f.is_file()][:20]  # Limit to 20 files
    
    return {
        "artifacts_path": ARTIFACTS_PATH,
        "model_loaded": model_loaded,
        "model_exists": check_model_exists(),
        "files": files,
    }


@app.get("/files")
async def list_model_files():
    """List all files in the model directory."""
    artifacts_dir = Path(ARTIFACTS_PATH)
    if not artifacts_dir.exists():
        return {"error": "Artifacts directory not found", "path": ARTIFACTS_PATH}
    
    files = []
    for f in artifacts_dir.rglob("*"):
        if f.is_file():
            files.append({
                "path": str(f.relative_to(artifacts_dir)),
                "size_mb": round(f.stat().st_size / (1024 * 1024), 2)
            })
    
    return {
        "artifacts_path": ARTIFACTS_PATH,
        "total_files": len(files),
        "files": files[:100],  # Limit response
    }


@app.post("/convert", response_model=ConversionResponse)
async def convert_document(
    file: Optional[UploadFile] = File(None),
):
    """
    Convert a document using Docling.
    """
    if not model_loaded:
        # Try to initialize if model now exists
        if check_model_exists():
            initialize_docling()
        
        if not model_loaded:
            raise HTTPException(
                status_code=503,
                detail="Model is not yet available. Please wait for download to complete.",
            )
    
    if docling_converter is None:
        return ConversionResponse(
            status="demo",
            message="Docling converter not available. Model files are present but converter not initialized.",
            result={"artifacts_path": ARTIFACTS_PATH, "model_exists": check_model_exists()},
        )
    
    if file is None:
        raise HTTPException(
            status_code=400,
            detail="A file must be provided for conversion.",
        )
    
    try:
        import tempfile
        import aiofiles
        
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=f"_{file.filename}") as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
        
        result = docling_converter.convert(tmp_path)
        os.unlink(tmp_path)
        
        return ConversionResponse(
            status="success",
            message="Document converted successfully",
            result={"document": str(result)},
        )
    except Exception as e:
        logger.error(f"Conversion failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Document conversion failed: {str(e)}",
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
