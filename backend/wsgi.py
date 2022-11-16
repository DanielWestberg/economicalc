from economicalc.app import create_app
from economicalc.config import RunConfig

application = create_app(RunConfig())

if __name__ == "__main__":
    application.run()
