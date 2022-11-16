from app import create_app
from config import RunConfig

application = create_app(RunConfig())

if __name__ == "__main__":
    application.run()
