class Image:
    def __init__(self, name):
        self.name = name

    @staticmethod
    def from_mongo_doc(doc):
        return Image(doc['name'])

    def to_dict(self):
        return {
            'name': self.name,
        }

    @staticmethod
    def doc2dict(doc):
        return Image.from_mongo_doc(doc).to_dict()
