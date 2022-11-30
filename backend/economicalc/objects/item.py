from typing import Dict, Any

from .type_check import check_type

class Item:
    def __init__(self, item_name: str, price_kr: int, price_ore: int, sum_kr: int, sum_ore: int, amount: int) -> None:
        check_type(item_name, str, "item.itemName")
        check_type(price_kr, int, "item.priceKr")
        check_type(price_ore, int, "item.priceOre")
        check_type(sum_kr, int, "item.sumKr")
        check_type(sum_ore, int, "item.sumOre")
        check_type(amount, int, "item.amount")

        self.item_name = item_name
        self.price_kr = price_kr
        self.price_ore = price_ore
        self.sum_kr = sum_kr
        self.sum_ore = sum_ore
        self.amount = amount

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.item_name == other.item_name and
            self.price_kr == other.price_kr and
            self.price_ore == other.price_ore and
            self.sum_kr == other.sum_kr and
            self.sum_ore == other.sum_ore and
            self.amount == other.amount
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "itemName": self.item_name,
            "priceKr": self.price_kr,
            "priceOre": self.price_ore,
            "sumKr": self.sum_kr,
            "sumOre": self.sum_ore,
            "amount": self.amount,
        }

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        check_type(d, dict, "item")

        item_name = d["itemName"]
        price_kr = d["priceKr"]
        price_ore = d["priceOre"]
        sum_kr = d["sumKr"]
        sum_ore = d["sumOre"]
        amount = d["amount"]

        return Item(item_name, price_kr, price_ore, sum_kr, sum_ore, amount)
