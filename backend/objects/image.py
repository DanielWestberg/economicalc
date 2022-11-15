class Image:
    def __init__(self, id, name, lastModified):
        self.id = str(id)
        self.name = name
        self.lastModified = lastModified.as_datetime()

    @staticmethod
    def fromMongoDoc(doc):
        return Image(doc['_id'], doc['name'], doc['lastModified'])

    def toDict(self):
        return {
            'id': self.id,
            'name': self.name,
            'lastModified': self.lastModified,
        }

    @staticmethod
    def doc2Dict(doc):
        return Image.fromMongoDoc(doc).toDict()
