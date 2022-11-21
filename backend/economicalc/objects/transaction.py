from datetime import datetime, timezone
from typing import Optional, Dict, Any, List

from .image import Image
from .item import Item


class Transaction:
    def __init__(self, recipient: str, items: List[Item], date_of_purchase: datetime, total_sum_kr: int, total_sum_ore: int, image: Optional[Image] = None) -> None:
        self.recipient = recipient
        self.items = items
        self.total_sum_kr = total_sum_kr
        self.total_sum_ore = total_sum_ore
        self.image = image

        date = date_of_purchase
        self.date = datetime(date.year, date.month, date.day, tzinfo=timezone.utc)

    def to_dict(self) -> Dict[str, Any]:
        res = {
            "recipient": self.recipient,
            "items": [item.to_dict() for item in self.items],
            "date": self.date,
            "total_sum_kr": self.total_sum_kr,
            "total_sum_ore": self.total_sum_ore
        }

        if self.image is not None:
            res["image"] = self.image.to_dict()

        return res
