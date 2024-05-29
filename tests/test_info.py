import subprocess
import os
import pathlib
import pytest


dir_path = pathlib.Path(os.path.dirname(os.path.realpath(__file__))).parent
twp_script_path: str = os.path.join(dir_path, "src", "_twp_script.sh")


@pytest.fixture
def run_info():
    res = subprocess.run([f"{twp_script_path} info"], shell=True, capture_output=True)

    return res.stdout.decode("utf-8")


def test_info_has_repo_host(run_info):
    assert "Hostname: github.com" in run_info


def test_info_has_repo_name(run_info):
    assert "Repo: eeue56/twp" in run_info


def test_info_has_branch_name(run_info):
    assert "On branch" in run_info


if __name__ == "__main__":
    print(twp_script_path)
    run_info()
