from typing import Dict, Any

from mimetypes import guess_type


class Image:
    def __init__(self, name: str) -> None:
        self.name = name
        self.id = None

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.name == other.name and
            self.id == other.id
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            '_id': self.id
        }

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        image = Image(d["name"])
        if "_id" in d:
            image.id = d["_id"]

        return image
