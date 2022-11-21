from datetime import datetime, timezone
from typing import Optional

from .image import Image


class Transaction:
    def __init__(self, id: int, store: str, items: list, date_of_purchase: datetime, total_sum: int, image: Optional[Image] = None) -> None:
        self.id = id
        self.store = store
        self.items = items
        self.total_sum = total_sum
        self.image = image

        date = date_of_purchase
        self.date = datetime(date.year, date.month, date.day, tzinfo=timezone.utc)

    def to_dict(self):
        res = {
            "id": self.id,
            "store": self.store,
            "items": [item.to_dict() for item in self.items],
            "date": self.date,
            "total_sum": self.total_sum,
        }

        if self.image is not None:
            res["image"] = self.image.to_dict()

        return res
