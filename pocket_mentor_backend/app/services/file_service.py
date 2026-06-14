import os
import io
from pathlib import Path
from typing import Optional
from fastapi import UploadFile

from app.config import settings
from app.core.exceptions import FileTooLargeException, UnsupportedFileTypeException

ALLOWED_EXTENSIONS = {"pdf", "docx", "txt"}
MAX_BYTES = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024


def get_file_extension(filename: str) -> str:
    return Path(filename).suffix.lstrip(".").lower()


async def validate_and_save_file(upload: UploadFile, user_id: str) -> tuple[str, str, int]:
    """
    Validates the uploaded file, saves it to disk.
    Returns (storage_path, file_type, file_size_bytes).
    """
    ext = get_file_extension(upload.filename or "")
    if ext not in ALLOWED_EXTENSIONS:
        raise UnsupportedFileTypeException()

    contents = await upload.read()
    if len(contents) > MAX_BYTES:
        raise FileTooLargeException(settings.MAX_UPLOAD_SIZE_MB)

    # Ensure upload directory exists
    upload_dir = Path(settings.UPLOAD_DIR) / user_id
    upload_dir.mkdir(parents=True, exist_ok=True)

    # Use a unique filename
    import uuid
    unique_name = f"{uuid.uuid4()}.{ext}"
    file_path = upload_dir / unique_name

    with open(file_path, "wb") as f:
        f.write(contents)

    return str(file_path), ext, len(contents)


def extract_text_from_file(storage_path: str, file_type: str) -> str:
    """
    Synchronous text extraction — called inside a Celery worker or run_in_executor.
    """
    if file_type == "txt":
        return _extract_txt(storage_path)
    elif file_type == "pdf":
        return _extract_pdf(storage_path)
    elif file_type == "docx":
        return _extract_docx(storage_path)
    return ""


def _extract_txt(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def _extract_pdf(path: str) -> str:
    try:
        import PyPDF2
        text_parts = []
        with open(path, "rb") as f:
            reader = PyPDF2.PdfReader(f)
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text_parts.append(page_text)
        return "\n".join(text_parts)
    except Exception as e:
        raise RuntimeError(f"PDF extraction failed: {e}")


def _extract_docx(path: str) -> str:
    try:
        import docx
        doc = docx.Document(path)
        paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
        return "\n".join(paragraphs)
    except Exception as e:
        raise RuntimeError(f"DOCX extraction failed: {e}")


def delete_file(storage_path: str) -> None:
    try:
        os.remove(storage_path)
    except FileNotFoundError:
        pass
