

class TestSetup:

    def test_db_connection(self, db):
        result = db.command("ping")
        assert result["ok"] == 1.0
