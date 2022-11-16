from economicalc.config import RunConfig, TestConfig
from economicalc.app import create_app, create_db


class TestSetup:

    def testProdDBConnection(self):
        app = create_app(RunConfig())
        db = create_db(app)
        result = db.command("ping")
        assert result["ok"] == 1.0
