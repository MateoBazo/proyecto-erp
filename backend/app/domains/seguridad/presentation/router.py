from fastapi import APIRouter
from app.domains.seguridad.presentation.endpoints.auth import router as auth_router
from app.domains.seguridad.presentation.endpoints.public import router as public_router

router = APIRouter()

router.include_router(auth_router)
router.include_router(public_router)
