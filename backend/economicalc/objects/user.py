from typing import Any, Dict, List

from .receipt import Receipt
from .category import Category


class User:
    def __init__(self, bankId, receipts: List[Receipt], categories: List[Category]) -> None:
        self.bankId = bankId
        self.receipts = receipts
        self.categories = categories

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.bankId == other.bankId and
            all([expected == actual for (expected, actual) in zip(self.receipts, other.receipts)]) and
            all([expected == actual for (expected, actual) in zip(self.categories, other.categories)])
        )

    def to_dict(self, json_serializable=False) -> None:
        return {
            "bankId": self.bankId,
            "receipts": [receipt.to_dict(json_serializable) for receipt in self.receipts],
            "categories": [category.to_dict(json_serializable) for category in self.categories],
        }

    @staticmethod
    def make_json_serializable(user_dict: Dict[str, Any]) -> None:
        user_dict.pop("_id", None)
        for receipt_dict in user_dict["receipts"]:
            Receipt.make_json_serializable(receipt_dict)
