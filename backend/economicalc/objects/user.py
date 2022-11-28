from typing import Any, Dict, List

from .transaction import Transaction


class User:
    def __init__(self, bankId, transactions: List[Transaction]) -> None:
        self.bankId = bankId
        self.transactions = transactions

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.bankId == other.bankId and
            all([expected == actual for (expected, actual) in zip(self.transactions, other.transactions)])
        )

    def to_dict(self, json_serializable=False) -> None:
        return {
            "bankId": self.bankId,
            "transactions": [transaction.to_dict(json_serializable) for transaction in self.transactions],
        }

    @staticmethod
    def make_json_serializable(user_dict: Dict[str, Any]) -> None:
        for transaction_dict in user_dict["transactions"]:
            Transaction.make_json_serializable(transaction_dict)
