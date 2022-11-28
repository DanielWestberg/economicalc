from economicalc.app import create_app
from economicalc.config import FlaskConfig

application = create_app(FlaskConfig())

if __name__ == "__main__":
    application.run(ssl_context='adhoc')
