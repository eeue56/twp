import subprocess
import os
import shutil
import pathlib
import pytest
import re

from typing import List


dir_path = pathlib.Path(os.path.dirname(os.path.realpath(__file__))).parent
twp_script_path: str = os.path.join(dir_path, "src", "_twp_script.sh")
example_dir = os.path.join(dir_path, "example")


def setup_dotfiles():
    with open(os.path.join(example_dir, ".env"), "w") as f:
        f.write("API_KEY=")

    with open(os.path.join(example_dir, ".example"), "w") as f:
        f.write("API_KEY=")


def setup_real_files():
    with open(os.path.join(example_dir, "README.md"), "w") as f:
        f.write("### Example")

    with open(os.path.join(example_dir, "package.json"), "w") as f:
        f.write("{}")


def teardown_gitignore():
    os.remove(os.path.join(example_dir, ".gitignore"))


def setup_gitignore():
    with open(os.path.join(example_dir, ".gitignore"), "w") as f:
        f.write("")


def teardown_git_repo():
    shutil.rmtree(example_dir)


def setup_git_repo():
    os.mkdir(example_dir)
    subprocess.run(["git init"], cwd=example_dir, shell=True)

    subprocess.run(
        ["git remote add origin git@github.com:eeue56/twp-example.git"],
        cwd=example_dir,
        shell=True,
    )

    setup_dotfiles()
    setup_real_files()


def add_gitignore():
    subprocess.run(
        ["git add .gitignore"],
        cwd=example_dir,
        shell=True,
    )


@pytest.fixture
def setup():
    setup_git_repo()
    yield True
    teardown_git_repo()


def run_function(function_name: str) -> str:
    process = subprocess.run(
        [f"{twp_script_path} _test {function_name}"],
        cwd=example_dir,
        shell=True,
        capture_output=True,
    )

    stdout = process.stdout.decode("utf-8")

    ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
    return ansi_escape.sub("", stdout)


def run_interaction_function(
    function_name: str, var_name: str, input: str, args: List[str]
) -> List[str]:
    joined_args = " ".join(f'"{arg}"' for arg in args)
    process = subprocess.Popen(
        [
            f"{twp_script_path} _test_interactive {function_name} {var_name} {joined_args}"
        ],
        stdout=subprocess.PIPE,
        stdin=subprocess.PIPE,
        cwd=example_dir,
        shell=True,
    )

    stdout: List[str] = []
    ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")

    if process.stdout:
        line = process.stdout.readline()
        stdout.append(line.decode("utf-8"))

    if process.stdin:
        process.stdin.write(input.encode("utf-8"))
        process.stdin.flush()
        process.stdin.close()

    if process.stdout:

        for line in process.stdout:
            stdout.append(line.decode("utf-8"))

    return [ansi_escape.sub("", line) for line in stdout]


def run_save():
    process = subprocess.Popen(
        [f"{twp_script_path} save"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        shell=True,
        cwd=example_dir,
    )

    if process.stdout:
        print(process.stdout.read())


def test_untracked_files(setup):
    files = run_function("_twp::_untracked_files")

    assert files == ".env\n.example\nREADME.md\npackage.json\n"


def test_untracked_dirs(setup):
    files = run_function("_twp::_untracked_dirs")

    assert files == ".env\n.example\nREADME.md\npackage.json\n"


def test_untracked_dotfiles(setup):
    files = run_function("_twp::_untracked_dotfiles")

    assert files == ".env\n.example\n"


def test_untracked_gitignore_when_it_doesnt_exist(setup):
    files = run_function("_twp::_has_untracked_gitignore")

    assert files == "false\n"


def test_untracked_gitignore_when_it_exists_but_is_untracked(setup):
    setup_gitignore()
    files = run_function("_twp::_has_untracked_gitignore")
    teardown_gitignore()
    assert files == "true\n"


def test_untracked_gitignore_when_it_exists_and_is_tracked(setup):
    setup_gitignore()
    add_gitignore()
    files = run_function("_twp::_has_untracked_gitignore")
    teardown_gitignore()
    assert files == "false\n"


def test_ask_to_add_gitignore_yes(setup):
    lines = run_interaction_function("_twp::_ask_to_add_gitignore", "CONFIRM", "y", [])

    assert lines[-2] == "true\n"
    assert lines[-1] == ""


def test_ask_to_add_gitignore_enter_yes(setup):
    lines = run_interaction_function("_twp::_ask_to_add_gitignore", "CONFIRM", "\n", [])

    assert lines[-2] == "true\n"
    assert lines[-1] == ""


def test_ask_to_add_gitignore_no(setup):
    lines = run_interaction_function("_twp::_ask_to_add_gitignore", "CONFIRM", "n", [])

    assert lines[-2] == "false\n"
    assert lines[-1] == ""


# try:
#     teardown_git_repo()
# except:
#     pass
# setup_git_repo()
# # run_interaction_function("_twp::_ask_to_add_gitignore", "CONFIRM", "y")
# x = run_interaction_function("_example", "X", "", ["one", "two"])
# print(x)
# teardown_git_repo()
