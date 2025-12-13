<div align="center">
  <img src="assets/scriptz-banner.png" alt="Scriptz Banner" width="100%">
</div>

# 🛠️ Scriptz

A collection of handy command-line tools for developers. Clone it, install it, use it. Fork it to add your own!

## 🚀 Quick Start

```bash
# Clone the repo
git clone https://github.com/mozrin/scriptz.git
cd scriptz/src

# Install to ~/.local/bin (user-local, no sudo needed)
./install_scriptz.sh --user-bin

# Or install system-wide to /usr/local/bin (requires sudo)
./install_scriptz.sh
```

That's it! All tools are now available in your terminal.

## 📦 Available Tools

| Tool | Description |
|------|-------------|
| `archive_project` | Archive a project folder |
| `backup_project` | Create a backup of your project |
| `barrel` | Generate Dart barrel (export) files |
| `barrelpy` | Python version of barrel |
| `chunk` | Split files into chunks |
| `firefox_install` | Install Firefox from Mozilla |
| `git-release` | Create a git release |
| `git-status` | Multi-repo git status check |
| `idea` | Generate project ideas |
| `pai` | Personal AI assistant |
| `tv_series_template` | TV series folder template |
| `unbloat` | Remove bloatware packages |
| `version` | Version management tool |

## 🗑️ Uninstall

The installer creates an uninstall script automatically:

```bash
./uninstall_scriptz.sh
```

This removes only the symlinks that were created during installation.

## 🍴 Fork It

Feel free to fork this repo and add your own scripts:

1. Fork the repository
2. Create a new folder under `src/scripts/your_tool/`
3. Add your script as `your_tool.sh` or `your_tool.py`
4. Run the installer to link it

### Script Structure

```tree
src/scripts/
├── your_tool/
│   └── your_tool.sh    # Main script (same name as folder)
├── another_tool/
│   └── another_tool.py # Python scripts work too!
```

The installer automatically finds scripts matching the folder name with `.sh` or `.py` extension.

## 💡 Got a Cool Script?

Have a handy script you want to share with the world?

� Head over to [GitHub Discussions](https://github.com/mozrin/scriptz/discussions) and share it!

We'd love to see what you've built.

## 📄 License

Do whatever you want with it. Just don't blame us if something breaks. 🤷

---

Made with ☕ by [Moztopia](https://moztopia.com)
