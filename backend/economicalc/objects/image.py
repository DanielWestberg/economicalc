from typing import Dict, Any

from mimetypes import guess_type


class Image:
    def __init__(self, name: str) -> None:
        self.name = name
        (self.content_type, _) = guess_type(name)
        self.id = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            '_id': self.id
        }
