#!/usr/bin/env python3
"""Barrel file generator for Dart projects.

This script creates and deletes barrel (export) files for Dart projects.
It recursively scans directories and generates export statements for all
Dart files, making it easier to import multiple files from a single location.
"""

import argparse
import sys
from pathlib import Path

MAGIC_HEADER = "/* created by barrel.py */"


def show_help() -> None:
    """Display usage instructions and exit."""
    print("Usage: barrelpy <create|delete> [--folder=.] [--target=name] [--yes] [--quiet]")
    sys.exit(1)


def parse_arguments(args: list[str]) -> argparse.Namespace:
    """Parse command line arguments.

    Args:
        args: Command line arguments passed to the script.

    Returns:
        Parsed arguments namespace with verb, folder, target, yes, and quiet.
    """
    parser = argparse.ArgumentParser(
        description="Barrel file generator for Dart projects",
        add_help=True,
    )
    parser.add_argument(
        "verb",
        choices=["create", "delete"],
        help="Command to execute: create or delete barrel files",
    )
    parser.add_argument(
        "--folder",
        default=".",
        help="Folder to process (default: current directory)",
    )
    parser.add_argument(
        "--target",
        default="",
        help="Target name for the root barrel file",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Skip confirmation prompts",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Suppress output (implies --yes)",
    )

    parsed = parser.parse_args(args)

    if parsed.quiet:
        parsed.yes = True

    parsed.folder = parsed.folder.rstrip("/")

    return parsed


def determine_root_filename(folder: str, target_name: str) -> tuple[str, Path]:
    """Determine the full path for the root barrel file.

    Args:
        folder: The folder being processed.
        target_name: User-specified target name, or empty for auto-detect.

    Returns:
        Tuple of (resolved target name, root file path).
    """
    if not target_name:
        if folder == ".":
            target_name = "barrel"
        else:
            target_name = Path(folder).name

    if not target_name.endswith(".dart"):
        target_name = f"{target_name}.dart"

    root_file = Path(f"./{target_name}")
    return target_name, root_file


def is_safe_to_delete(file_path: Path) -> bool:
    """Check if a file contains the magic header indicating it was created by this script.

    Args:
        file_path: Path to the file to check.

    Returns:
        True if safe to delete (header matches), False otherwise.
    """
    if file_path.is_file():
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                header = f.readline().strip()
                return header == MAGIC_HEADER
        except (IOError, UnicodeDecodeError):
            return False
    return False


def generate_recursive(
    directory: Path,
    explicit_output: Path | None = None,
) -> None:
    """Recursively generate barrel files.

    Args:
        directory: Directory to process.
        explicit_output: Explicit output filename, or None for auto-generated name.
    """
    base_name = directory.name if directory.name != "." else "barrel"

    if explicit_output:
        output_file = explicit_output
    else:
        output_file = directory / f"exports_{base_name}.dart"

    lines: list[str] = [MAGIC_HEADER, ""]

    dart_files = sorted(directory.glob("*.dart"))
    for dart_file in dart_files:
        fname = dart_file.name

        if dart_file == output_file or Path(f"./{fname}") == output_file:
            continue

        if fname.startswith("exports_") and fname.endswith(".dart"):
            continue

        if fname.endswith(".g.dart"):
            continue

        if is_safe_to_delete(dart_file):
            continue

        lines.append(f'export "{fname}";')

    subdirs = sorted([d for d in directory.iterdir() if d.is_dir()])
    for subdir in subdirs:
        sub_name = subdir.name

        generate_recursive(subdir, None)

        lines.append(f'export "{sub_name}/exports_{sub_name}.dart";')

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
        f.write("\n")


def perform_delete(
    root_file: Path,
    folder: Path,
    yes: bool,
    quiet: bool,
) -> None:
    """Delete the root file and recursive export files.

    Args:
        root_file: Path to the root barrel file.
        folder: Folder to scan for export files.
        yes: Skip confirmation prompt.
        quiet: Suppress output.
    """
    if not quiet:
        print("--------------------------------------------------")
        print("Deleting barrel files...")
        print(f"  Root: {root_file}")
        print(f"  Scan: {folder}")
        print("--------------------------------------------------")

    if not yes:
        response = input("Delete generated files? [y/N] ").strip().lower()
        if response != "y":
            return

    if is_safe_to_delete(root_file):
        root_file.unlink()
        if not quiet:
            print(f"Deleted: {root_file}")

    for export_file in folder.rglob("exports_*.dart"):
        if is_safe_to_delete(export_file):
            export_file.unlink()
            if not quiet:
                print(f"Deleted: {export_file}")

    if not quiet:
        print("Done.")


def perform_create(
    root_file: Path,
    folder: Path,
    yes: bool,
    quiet: bool,
) -> None:
    """Create the barrel files.

    Args:
        root_file: Path to the root barrel file.
        folder: Folder to scan for Dart files.
        yes: Skip confirmation prompt.
        quiet: Suppress output.
    """
    if not folder.is_dir():
        print(f"Error: Folder '{folder}' does not exist.")
        sys.exit(1)

    if not quiet:
        print("--------------------------------------------------")
        print("Creating barrel files...")
        print(f"  Root: {root_file}")
        print(f"  Scan: {folder}")
        print("--------------------------------------------------")

    if not yes:
        response = input("Create barrel files? [y/N] ").strip().lower()
        if response != "y":
            return

    if str(folder) == ".":
        generate_recursive(folder, root_file)
    else:
        generate_recursive(folder, None)

        inner_export = folder / f"exports_{folder.name}.dart"
        with open(root_file, "w", encoding="utf-8") as f:
            f.write(f"{MAGIC_HEADER}\n\n")
            f.write(f'export "{inner_export}";\n')

    if not quiet:
        print("Done.")


def main() -> None:
    """Main execution block."""
    args = parse_arguments(sys.argv[1:])
    _, root_file = determine_root_filename(args.folder, args.target)
    folder = Path(args.folder)

    if args.verb == "create":
        perform_create(root_file, folder, args.yes, args.quiet)
    elif args.verb == "delete":
        perform_delete(root_file, folder, args.yes, args.quiet)
    else:
        print(f"Error: Invalid command '{args.verb}'.")
        show_help()


if __name__ == "__main__":
    main()
