from economicalc.app import create_db

class TestSetup:

    def test_db_connection(self, app):
        db = create_db(app)
        result = db.command("ping")
        assert result["ok"] == 1.0
