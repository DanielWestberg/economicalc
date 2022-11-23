from typing import Dict, Any

from .type_check import check_type

class Item:
    def __init__(self, name: str, price_kr: int, price_ore: int, sum_kr: int, sum_ore: int, quantity: int) -> None:
        check_type(name, str, "item.name")
        check_type(price_kr, int, "item.price_kr")
        check_type(price_ore, int, "item.price_ore")
        check_type(sum_kr, int, "item.sum_kr")
        check_type(sum_ore, int, "item.sum_ore")
        check_type(quantity, int, "item.quantity")

        self.name = name
        self.price_kr = price_kr
        self.price_ore = price_ore
        self.sum_kr = sum_kr
        self.sum_ore = sum_ore
        self.quantity = quantity

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "price_kr": self.price_kr,
            "price_ore": self.price_ore,
            "sum_kr": self.sum_kr,
            "sum_ore": self.sum_ore,
            "quantity": self.quantity,
        }

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        check_type(d, dict, "item")

        name = d["name"]
        price_kr = d["price_kr"]
        price_ore = d["price_ore"]
        sum_kr = d["sum_kr"]
        sum_ore = d["sum_ore"]
        quantity = d["quantity"]

        return Item(name, price_kr, price_ore, sum_kr, sum_ore, quantity)
