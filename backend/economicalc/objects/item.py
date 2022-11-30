from typing import Dict, Any

from .type_check import check_type

class Item:
    def __init__(self, item_name: str, amount: float) -> None:
        check_type(item_name, str, "item.itemName")
        check_type(amount, float, "item.amount")

        self.item_name = item_name
        self.amount = amount

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.item_name == other.item_name and
            self.amount == other.amount
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "itemName": self.item_name,
            "amount": self.amount,
        }

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        check_type(d, dict, "item")

        item_name = d["itemName"]
        amount = d["amount"]

        return Item(item_name, amount)
