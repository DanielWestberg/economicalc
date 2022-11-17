class User:
    def __init__(self, bankId, receipts: list) -> None:
        self.bankId = bankId
        self.receipts = receipts

    @staticmethod
    def from_mongo_doc(doc):
        return User(doc["bankId"], doc["receipts"])

    def to_dict(self):
        return {
            "bankId": self.bankId,
            "receipts": self.receipts,
        }

    @staticmethod
    def doc2dict(doc):
        return User.from_mongo_doc(doc).to_dict()
