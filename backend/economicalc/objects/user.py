from typing import List

from .transaction import Transaction


class User:
    def __init__(self, bankId, transactions: List[Transaction]) -> None:
        self.bankId = bankId
        self.transactions = transactions

    def to_dict(self, json_serializable=False) -> None:
        return {
            "bankId": self.bankId,
            "transactions": [transaction.to_dict(json_serializable) for transaction in self.transactions],
        }
