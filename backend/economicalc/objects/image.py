from typing import Dict, Any


class Image:
    def __init__(self, name: str) -> None:
        self.name = name

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
        }
