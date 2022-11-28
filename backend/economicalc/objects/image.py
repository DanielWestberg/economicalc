from typing import Any, Dict, Optional, Union

from bson.objectid import ObjectId

from .type_check import check_type


class Image:
    def __init__(self, id: Optional[Union[ObjectId, str]]) -> None:
        check_type(id, [type(None), str, ObjectId], "image.id")
        self.id = ObjectId(id)

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.id == other.id
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            '_id': self.id
        }

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        image = Image(d["name"])
        if "_id" in d:
            image.id = d["_id"]

        return image
