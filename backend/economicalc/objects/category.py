from bson.objectid import ObjectId
from typing import Any, Dict, Optional

from .type_check import check_type


class Category:
    def __init__(self, id: int, description: str, color: int) -> None:
        check_type(id, int, "category.id")
        check_type(description, str, "category.description")
        check_type(color, int, "category.color")

        self.id = id
        self.description = description
        self.color = color

    def __eq__(self, other) -> bool:
        return (
            type(self) == type(other) and
            self.id == other.id and
            self.description == other.description and
            self.color == other.color
        )

    def to_dict(self, json_serializable: bool = False) -> None:
        res = {
            "id": self.id
            "description": self.description,
            "color": self.color,
        }

        return res

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        id = d["id"] if "id" in d else None
        description = d["description"]
        color = d["color"]

        return Category(id, description, color)
