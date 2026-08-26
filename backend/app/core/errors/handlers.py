from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.core.errors.exceptions import DomainException


def register_exception_handlers(app: FastAPI) -> None:
    """
    Registra un único manejador genérico para toda excepción de dominio (de cualquier dominio),
    traduciéndola a HTTP según los atributos `http_status`/`headers` que cada excepción declara.
    Así core/errors nunca necesita importar tipos de excepción específicos de un dominio de negocio.
    """

    @app.exception_handler(DomainException)
    async def domain_exception_handler(request: Request, exc: DomainException):
        return JSONResponse(
            status_code=exc.http_status,
            content={"detail": exc.message},
            headers=exc.headers,
        )
