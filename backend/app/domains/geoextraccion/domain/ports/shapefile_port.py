from abc import ABC, abstractmethod

from app.domains.geoextraccion.domain.entities.terreno import Terreno


class ShapefilePort(ABC):
    """Interfaz para generar/fusionar Shapefiles; application/ no conoce GeoPandas."""

    @abstractmethod
    def generar(self, terrenos: list[Terreno]) -> bytes:
        """Genera un ZIP con un Shapefile a partir de uno o más terrenos (polígonos)."""

    @abstractmethod
    def fusionar(self, archivos: list[bytes]) -> bytes:
        """Une varios ZIP de Shapefile (bytes crudos) en una sola capa y devuelve el ZIP resultante."""
