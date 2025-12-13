#!/usr/bin/env python3
"""
git-release - Smart release tagging for git repositories.

Creates versioned release tags with intelligent defaults and safety checks.
"""

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from enum import IntEnum


class Verbosity(IntEnum):
    QUIET = -1
    NORMAL = 0
    DEBUG = 1


@dataclass
class Config:
    release_tag: str | None = None
    release_name: str | None = None
    yes: bool = False
    verbose: Verbosity = Verbosity.NORMAL


def run_git(*args: str, capture: bool = True, check: bool = True) -> str:
    """Run a git command and return its output."""
    cmd = ["git"] + list(args)
    result = subprocess.run(
        cmd,
        capture_output=capture,
        text=True,
        check=check,
    )
    return result.stdout.strip() if capture else ""


def log(msg: str, config: Config, level: Verbosity = Verbosity.NORMAL) -> None:
    """Print a message based on verbosity level."""
    if config.verbose >= level:
        prefix = "[DEBUG] " if level == Verbosity.DEBUG else ""
        print(f"{prefix}{msg}")


def error(msg: str) -> None:
    """Print an error message and exit."""
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def warn(msg: str) -> None:
    """Print a warning message."""
    print(f"WARNING: {msg}", file=sys.stderr)


def get_current_branch() -> str:
    """Get the current git branch name."""
    return run_git("rev-parse", "--abbrev-ref", "HEAD")


def fetch_tags(config: Config) -> None:
    """Fetch latest tags from origin."""
    log("Fetching tags from origin...", config, Verbosity.DEBUG)
    run_git("fetch", "--tags", "--quiet")


def get_all_tags() -> list[str]:
    """Get all tags from the repository."""
    output = run_git("tag", "--list")
    return output.split("\n") if output else []


def parse_semver(tag: str) -> tuple[int, int, int] | None:
    """Parse a semantic version tag. Returns (major, minor, patch) or None."""
    # Remove 'v' prefix if present
    version = tag.lstrip("v")
    match = re.match(r"^(\d{1,2})\.(\d{1,2})\.(\d{1,2})$", version)
    if match:
        return int(match.group(1)), int(match.group(2)), int(match.group(3))
    return None


def validate_tag_format(tag: str) -> bool:
    """Validate that a tag matches ##.##.## format (with optional v prefix)."""
    return parse_semver(tag) is not None


def get_highest_version(tags: list[str]) -> tuple[int, int, int] | None:
    """Find the highest semantic version from a list of tags."""
    versions = []
    for tag in tags:
        parsed = parse_semver(tag)
        if parsed:
            versions.append(parsed)
    
    if not versions:
        return None
    
    return max(versions)


def suggest_next_version(tags: list[str]) -> str:
    """Suggest the next patch version based on existing tags."""
    highest = get_highest_version(tags)
    if highest is None:
        return "1.0.0"
    
    major, minor, patch = highest
    return f"{major}.{minor}.{patch + 1}"


def tag_exists(tag: str, tags: list[str]) -> bool:
    """Check if a tag already exists."""
    # Normalize: check both with and without 'v' prefix
    normalized = tag.lstrip("v")
    return tag in tags or f"v{normalized}" in tags or normalized in tags


def has_uncommitted_changes() -> bool:
    """Check if there are uncommitted changes."""
    result = subprocess.run(
        ["git", "diff-index", "--quiet", "HEAD", "--"],
        capture_output=True,
    )
    return result.returncode != 0


def has_unpushed_commits(branch: str) -> bool:
    """Check if there are commits not pushed to origin."""
    try:
        local = run_git("rev-parse", branch)
        remote = run_git("rev-parse", f"origin/{branch}")
        return local != remote
    except subprocess.CalledProcessError:
        # Remote branch doesn't exist
        return True


def get_branch_commit(branch: str) -> str | None:
    """Get the commit hash of a branch, or None if it doesn't exist."""
    try:
        return run_git("rev-parse", branch)
    except subprocess.CalledProcessError:
        return None


def check_develop_divergence(config: Config) -> None:
    """Warn if develop branch differs from main."""
    main_commit = get_branch_commit("main")
    develop_commit = get_branch_commit("develop")
    
    if develop_commit is None:
        log("No 'develop' branch found (this is fine)", config, Verbosity.DEBUG)
        return
    
    if main_commit != develop_commit:
        warn("'develop' branch differs from 'main' - consider merging before release")
        log(f"  main:    {main_commit[:8] if main_commit else 'N/A'}", config, Verbosity.DEBUG)
        log(f"  develop: {develop_commit[:8]}", config, Verbosity.DEBUG)


def create_tag(tag: str, name: str | None, config: Config) -> None:
    """Create an annotated tag."""
    message = name if name else f"Release {tag}"
    log(f"Creating tag '{tag}' with message: {message}", config, Verbosity.DEBUG)
    run_git("tag", "-a", tag, "-m", message)


def push_tag(tag: str, config: Config) -> None:
    """Push a tag to origin."""
    log(f"Pushing tag '{tag}' to origin...", config, Verbosity.DEBUG)
    run_git("push", "origin", tag)


def confirm(prompt: str, config: Config) -> bool:
    """Ask for confirmation unless --yes is set."""
    if config.yes:
        return True
    
    response = input(f"{prompt} (y/N) ").strip().lower()
    return response == "y"


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="git-release",
        description="Create versioned release tags with intelligent defaults and safety checks.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  git-release                          # Auto-suggest next tag
  git-release --release-tag=2.0.0      # Use specific tag
  git-release --release-name="Holiday" # Add release name
  git-release --yes                    # Skip confirmation
  git-release --verbose                # Show debug output
        """,
    )
    
    parser.add_argument(
        "--release-tag",
        metavar="TAG",
        help="Override the suggested release tag (format: ##.##.## with optional 'v' prefix)",
    )
    parser.add_argument(
        "--release-name",
        metavar="NAME",
        help="Release name for the tag message (default: 'Release TAG')",
    )
    parser.add_argument(
        "--yes", "-y",
        action="store_true",
        help="Skip confirmation prompt",
    )
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Suppress informational output",
    )
    parser.add_argument(
        "--verbose", "-v",
        nargs="?",
        const=1,
        type=int,
        choices=[0, 1],
        default=0,
        metavar="LEVEL",
        help="Verbosity level: 0=normal (default), 1=debug",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Same as --verbose=1",
    )
    
    args = parser.parse_args()
    
    # Build config
    if args.quiet:
        verbosity = Verbosity.QUIET
    elif args.debug or args.verbose == 1:
        verbosity = Verbosity.DEBUG
    else:
        verbosity = Verbosity.NORMAL
    
    config = Config(
        release_tag=args.release_tag,
        release_name=args.release_name,
        yes=args.yes,
        verbose=verbosity,
    )
    
    # === Safety Checks ===
    
    # 1. Must be on main branch
    current_branch = get_current_branch()
    log(f"Current branch: {current_branch}", config, Verbosity.DEBUG)
    
    if current_branch != "main":
        error(f"Must be on 'main' branch to create a release (currently on '{current_branch}')")
    
    # 2. No uncommitted changes
    if has_uncommitted_changes():
        error("You have uncommitted changes. Commit or stash them first.")
    
    # 3. Fetch and get all tags
    fetch_tags(config)
    tags = get_all_tags()
    log(f"Found {len(tags)} existing tags", config, Verbosity.DEBUG)
    
    # 4. Determine release tag
    if config.release_tag:
        release_tag = config.release_tag
        if not validate_tag_format(release_tag):
            error(f"Invalid tag format '{release_tag}'. Expected ##.##.## (e.g., 1.2.3 or v1.2.3)")
    else:
        suggested = suggest_next_version(tags)
        release_tag = suggested
        log(f"Suggested next version: {release_tag}", config)
    
    # Normalize tag (ensure no 'v' prefix for storage, we'll add it)
    release_tag_normalized = release_tag.lstrip("v")
    final_tag = f"v{release_tag_normalized}"
    
    # 5. Check for duplicate tags
    if tag_exists(final_tag, tags):
        error(f"Tag '{final_tag}' already exists. Choose a different version.")
    
    # 6. Check for unpushed commits
    if has_unpushed_commits("main"):
        error("You have unpushed commits on 'main'. Push them first or pull latest.")
    
    # 7. Warn about develop divergence (non-blocking)
    check_develop_divergence(config)
    
    # === Summary ===
    log("", config)
    log("=" * 50, config)
    log(" Release Summary", config)
    log("=" * 50, config)
    log("  Branch:  main", config)
    log(f"  Tag:     {final_tag}", config)
    if config.release_name:
        log(f"  Name:    {config.release_name}", config)
    log("=" * 50, config)
    log("", config)
    
    # === Confirmation ===
    if not confirm("Create this release?", config):
        log("Release aborted.", config)
        sys.exit(0)
    
    # === Execute ===
    create_tag(final_tag, config.release_name, config)
    push_tag(final_tag, config)
    
    log("", config)
    log(f"✓ Release {final_tag} created and pushed successfully!", config)


if __name__ == "__main__":
    main()
