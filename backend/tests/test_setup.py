

class TestSetup:

    def testDBConnection(self, db):
        result = db.command("ping")
        assert result["ok"] == 1.0
