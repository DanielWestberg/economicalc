from economicalc.config import FlaskConfig
from economicalc.app import create_app, create_db


class TestSetup:

    def testDBConnection(self):
        app = create_app(FlaskConfig())
        db = create_db(app)
        result = db.command("ping")
        assert result["ok"] == 1.0
