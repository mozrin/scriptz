# 🧠 PAI – Prep AI

> **Automate the grunt-work of turning a whole codebase into one perfect LLM prompt.**

PAI is a simple, powerful shell script that scans your project, filters out the noise, and bundles all relevant source code, file structures, and instructions into a single, context-rich text file ready for any Large Language Model.

---

## Table of Contents

1.  [Why PAI Exists](#1-why-pai-exists)
2.  [Quick Start Guide](#2-quick-start-guide)
3.  [How It Works: The `pai.env` System](#3-how-it-works-the-paienv-system)
4.  [Installation and Usage](#4-installation-and-usage)
5.  [Configuration Deep-Dive (`pai.env`)](#5-configuration-deep-dive-paienv)
6.  [The PAI Script Pipeline](#6-the-pai-script-pipeline)
7.  [Dependencies](#7-dependencies)
8.  [Troubleshooting](#8-troubleshooting)
9.  [License](#9-license)

---

## 1. Why PAI Exists

Large-language models thrive on **focused context**. Copy-pasting random snippets wastes tokens, loses structure, and derails your flow. PAI solves this by programmatically compressing your project's essence into **one single text file**.

| Section in Output File           | What it Contains                                                                      |
| -------------------------------- | ------------------------------------------------------------------------------------- |
| `--- AI Primary Prompt ---`      | Your global, unchanging directives (style, rules, overall goal).                      |
| `--- AI Details Prompt ---`      | Session-specific context (the task at hand, the "story so far").                      |
| `--- Folder Structure ---`       | A clean `tree` view of only the relevant source code directories and files.           |
| `--- Baseline File Contents ---` | Every source file you care about, stripped of comments, trimmed, and clearly labeled. |

Hand the generated file to any model—ChatGPT, Claude, Gemini, or a local LLM—and you’re ready to code in seconds.

---

## 2. Quick Start Guide

1.  **Add PAI to your project's `.gitignore`:**

    ```bash
    echo ".pai/" >> .gitignore
    ```

2.  **Clone PAI into a hidden `.pai` folder inside your project:**

    ```bash
    git clone https://github.com/moztopia/pai .pai
    ```

3.  **Create your configuration file from the sample:**

    ```bash
    cp .pai/examples/pai.env.sample .pai/pai.env
    ```

4.  **Edit `.pai/pai.env`** to set your `PROJECT_PROFILE` (e.g., `DART_FLUTTER`).

5.  **Navigate into the `.pai` directory:**

    ```bash
    cd .pai
    ```

6.  **Make the script executable and run it:**

    ```bash
    chmod +x pai-gen.sh
    ./pai-gen.sh
    ```

7.  **Done!** Your complete context is now in `pai.output.txt` inside the `.pai` folder.

---

## 3. How It Works: The `pai.env` System

PAI is designed to be **project-aware and portable**. It achieves this by separating configuration from logic.

- **`pai.env` (Your Configuration):** This is where you define _what_ to scan. It's a simple text file holding key-value pairs. You define "profiles" for different project types (e.g., a profile for Flutter, another for Laravel) and simply choose which one to use.
- **`pai-gen.sh` (The Engine):** This is the script that does the work. It reads `pai.env`, dynamically figures out your project's file paths, and intelligently applies the include/exclude rules from your chosen profile to build the final output.

This design means you can drop PAI into any project, set the profile, and it just works—no hardcoded paths, no script editing required.

---

## 4. Installation and Usage

### Repository Layout

Place the PAI toolset in a `.pai` directory at the root of your project. The leading dot keeps the folder hidden and grouped at the top of file listings.

```
your-project/
├── .git/
├── .pai/                  # PAI lives here, ignored by git
│   ├── pai-gen.sh         # 🏃 The main script you run
│   ├── pai.env            # ⚙️ Your local configuration (you create this)
│   ├── pai.prompt.txt     # 🌐 Your global AI directives
│   ├── pai.details.txt    # 🎯 Your session-specific context
│   ├── examples/
│   │   └── pai.env.sample # 📋 A template to create your pai.env from
│   └── README.md          # 📖 You are here
├── lib/
└── ...your project files
```

### Running the Script

**Important: You must run the script from within the `.pai` directory.**

The script is designed to be executed only from its own folder. Attempting to run it from the project root or any other location will cause it to fail with an error message.

**Correct Usage:**

```bash
cd .pai
./pai-gen.sh
```

**Incorrect Usage:**

```bash
# This will fail
./.pai/pai-gen.sh
```

---

## 5. Configuration Deep-Dive (`pai.env`)

Your entire configuration lives in `.pai/pai.env`. You define different sets of rules ("profiles") and then activate one.

| Variable Group                          | Description                                                                                                                                                      |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ------- | ------ |
| `PROJECT_PROFILE`                       | **The most important setting.** Set this to the profile you want to use, e.g., `PROJECT_PROFILE="DART_FLUTTER"`. The script uses this to select the rules below. |
| `*_ROOT_FOLDERS`                        | Pipe-separated list of folders **relative to your project root** to scan. <br>Example: `DART_FLUTTER_ROOT_FOLDERS="lib                                           | assets"`          |
| `*_INCLUDE_EXTS`                        | Pipe-separated list of file extensions to include. <br>Example: `PHP_LARAVEL_INCLUDE_EXTS="php                                                                   | blade.php         | json"`  |
| `*_EXCLUDE_DIRS`                        | Pipe-separated list of directory names to ignore completely. <br>Example: `DART_FLUTTER_EXCLUDE_DIRS="build                                                      | ios               | android | .git"` |
| `*_EXCLUDE_FILES`                       | Pipe-separated list of filename patterns (regex-compatible) to ignore. <br>Example: `DART_FLUTTER_EXCLUDE_FILES="\*.g.dart                                       | \*.freezed.dart"` |
| `(OUTPUT/PROMPT/DETAILS)_FILE_BASENAME` | The filenames for the output and input prompt files. Defaults are fine.                                                                                          |

To add a new profile (e.g., for a Python project), simply add the corresponding `PYTHON_DJANGO_*` variables to `pai.env` and set `PROJECT_PROFILE="PYTHON_DJANGO"`.

---

## 6. The PAI Script Pipeline

When you run `pai-gen.sh`, it performs the following steps:

| Step | What Happens                                                                                                                                                                           |
| :--- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | **Validate Location:** Checks that you are running the script from within the `.pai` directory.                                                                                        |
| 2    | **Load Config:** Reads `.pai/pai.env`, determines project paths, and selects the active profile's rules.                                                                               |
| 3    | **Initialize:** Wipes and creates a fresh `pai.output.txt`.                                                                                                                            |
| 4    | **Add Prompts:** Appends the content of `pai.prompt.txt` and `pai.details.txt` under their respective headers.                                                                         |
| 5    | **Build Tree:** Scans your `ROOT_FOLDERS`. If `tree` is installed, it generates a clean diagram showing only included files. Otherwise, it falls back to a simple list of directories. |
| 6    | **Sweep Files:** `find`s all files matching `INCLUDE_EXTS` within `ROOT_FOLDERS`, skipping any `EXCLUDE_DIRS` or `EXCLUDE_FILES`.                                                      |
| 7    | **Process & Append:** For each found file, it strips comments (`//` and `/* ... */`), trims whitespace, prepends a `# path/to/file.ext` header, and appends it to the output.          |
| 8    | **Report:** Finishes by printing a success message to the console.                                                                                                                     |

---

## 7. Dependencies

| Tool   | Purpose                        | Install (Ubuntu/Debian)           | Notes                                                        |
| ------ | ------------------------------ | --------------------------------- | ------------------------------------------------------------ |
| `bash` | Script runtime                 | Pre-installed on most Linux/macOS | Tested on Bash 5+                                            |
| `gawk` | Robust comment/text processing | `sudo apt install gawk`           | GNU awk is used for its advanced text manipulation features. |
| `tree` | Pretty directory diagrams      | `sudo apt install tree`           | **Optional.** The script gracefully falls back if not found. |

---

## 8. Troubleshooting

| Symptom                                                          | Fix                                                                                                                                                                                                                                                                                                                                                                                                           |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Error: This script must be run from within the .pai directory.` | You tried to run the script from the wrong place. Follow the instructions: `cd .pai` and then `./pai-gen.sh`.                                                                                                                                                                                                                                                                                                 |
| `You need a pai.env file...`                                     | You forgot to copy the sample file. Run `cp examples/pai.env.sample pai.env` from inside the `.pai` directory.                                                                                                                                                                                                                                                                                                |
| `Error: DART_FLUTTER_ROOT_FOLDERS is not defined...`             | The `PROJECT_PROFILE` you set in `pai.env` doesn't have a corresponding `*_ROOT_FOLDERS` variable defined. Check for typos.                                                                                                                                                                                                                                                                                   |
| `tree: command not found`                                        | This is just a warning. The script will work fine. To get the pretty tree view, run `sudo apt install tree`.                                                                                                                                                                                                                                                                                                  |
| A file you wanted is missing from the output                     | Check your `*_INCLUDE_EXTS`, `*_EXCLUDE_DIRS`, and `*_EXCLUDE_FILES` patterns in `.pai/pai.env`.                                                                                                                                                                                                                                                                                                              |
| The output file is still too big                                 | Tighten your `*_EXCLUDE_*` rules. Exclude test directories, assets, or generated code more aggressively.<br><br>**Note:** Many consumer AI tools have limited input sizes. PAI was built to leverage the large context windows of tools like [Google AI Studio](https://aistudio.google.com/prompts/new_chat). If you are consistently hitting input limits, consider using a service with a larger capacity. |

---

## 9. License

MIT — do what you want with this, but don't blame me if your AI hallucinates. See the `LICENSE` file for the full text.

**Made with caffeine & curiosity.** If PAI speeds up your workflow, drop a ⭐️ on the repo or open an issue with your ideas.
