from app import get_environment_message


def test_environment_message():
    message = get_environment_message()

    assert message == "VS Code Server JFrog POC is running successfully."