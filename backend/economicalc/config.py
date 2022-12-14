import os


class FlaskConfig:

    def __init__(self):
        self.MONGO_USERNAME = os.environ['MONGODB_USERNAME']
        self.MONGO_PASSWORD = os.environ['MONGODB_PASSWORD']
        self.MONGO_HOSTNAME = os.environ['MONGODB_HOSTNAME']
        self.MONGO_DATABASE = os.environ['MONGODB_DATABASE']
        self.MONGO_URI = self.getMongoURI()

    def getMongoURI(self):
        return f"mongodb://{self.MONGO_USERNAME}:{self.MONGO_PASSWORD}@{self.MONGO_HOSTNAME}:27017/{self.MONGO_DATABASE}"
