#!/usr/bin/env python3
"""Git clone helper for GitHub repositories.

Clone repositories from GitHub with a simpler syntax.
Defaults to the moztopia organization.
"""

import argparse
import subprocess
import sys
from pathlib import Path


def parse_arguments(args: list[str]) -> argparse.Namespace:
    """Parse command line arguments.

    Args:
        args: Command line arguments passed to the script.

    Returns:
        Parsed arguments namespace.
    """
    parser = argparse.ArgumentParser(
        description="Clone a repository from GitHub",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  git-clone scriptz                    # Clone moztopia/scriptz to ./scriptz
  git-clone scriptz my-folder          # Clone to ./my-folder
  git-clone scriptz --org=mozrin       # Clone mozrin/scriptz
  git-clone scriptz ~/Code --quiet     # Clone without prompts
""",
    )
    parser.add_argument(
        "repo_name",
        help="The name of the repository to clone",
    )
    parser.add_argument(
        "target_directory",
        nargs="?",
        default=None,
        help="Local folder where the repo will be cloned (default: repo name)",
    )
    parser.add_argument(
        "--org",
        default="moztopia",
        help="GitHub organization or username (default: moztopia)",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Suppress prompts",
    )

    return parser.parse_args(args)


def clone_repository(
    repo_name: str,
    target_directory: Path,
    org: str,
    quiet: bool,
) -> int:
    """Clone a repository from GitHub.

    Args:
        repo_name: Name of the repository.
        target_directory: Local directory to clone into.
        org: GitHub organization or username.
        quiet: Suppress prompts if True.

    Returns:
        Exit code from git clone command.
    """
    repo_url = f"https://github.com/{org}/{repo_name}.git"

    if not quiet:
        print(f"Cloning {org}/{repo_name}")
        print(f"  From: {repo_url}")
        print(f"  To:   {target_directory.absolute()}")
        print()

        response = input("Proceed? [Y/n] ").strip().lower()
        if response == "n":
            print("Cancelled.")
            return 0

    if target_directory.exists():
        print(f"Error: Target directory already exists: {target_directory}")
        return 1

    cmd = ["git", "clone", repo_url, str(target_directory)]

    if quiet:
        cmd.append("--quiet")

    result = subprocess.run(cmd, check=False)

    if result.returncode == 0 and not quiet:
        print()
        print(f"Successfully cloned to {target_directory}")

    return result.returncode


def main() -> None:
    """Main execution block."""
    args = parse_arguments(sys.argv[1:])

    target = args.target_directory if args.target_directory else args.repo_name
    target_path = Path(target)

    exit_code = clone_repository(
        repo_name=args.repo_name,
        target_directory=target_path,
        org=args.org,
        quiet=args.quiet,
    )

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
