# Contributing to wt-tools

Thank you for your interest in contributing to wt-tools! This document provides guidelines and information for contributors.

## Development Setup

### Prerequisites

- Python 3.10 or higher
- Git
- Node.js (for Claude Code CLI)
- jq (JSON processing)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/tatargabor/wt-tools.git
   cd wt-tools
   ```

2. Run the installer:
   ```bash
   ./install.sh
   ```

3. Install development dependencies:
   ```bash
   pip install -e ".[dev]"
   ```

## Project Structure

```
wt-tools/
├── bin/                    # Shell scripts (CLI tools)
│   ├── wt-new             # Create new worktree
│   ├── wt-work            # Open worktree
│   ├── wt-list            # List worktrees
│   ├── wt-close           # Close worktree
│   ├── wt-merge           # Merge branch
│   ├── wt-status          # JSON status output
│   └── wt-common.sh       # Shared functions
├── gui/                    # Python GUI (PySide6)
│   ├── control_center/    # Main window and mixins
│   ├── dialogs/           # Dialog windows
│   ├── workers/           # Background workers
│   └── widgets/           # Custom widgets
├── wt_tools/              # Python package
│   └── plugins/           # Plugin system
├── docs/                  # Documentation
└── tests/                 # Test suite
```

## Making Changes

### Branching Strategy

1. Create a feature branch from `master`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Or use wt-tools itself:
   ```bash
   wt-new your-feature-name
   ```

### Code Style

- **Python**: Follow PEP 8, use Black for formatting
- **Shell**: Use ShellCheck, follow Google Shell Style Guide
- **Markdown**: Use consistent headers and formatting

### Testing

Run tests before submitting:
```bash
pytest
```

### Commit Messages

Use clear, descriptive commit messages:
```
Add feature X for doing Y

- Implemented Z functionality
- Updated tests for new behavior

Co-Authored-By: Your Name <email@example.com>
```

## Plugin Development

wt-tools supports plugins via entry points. To create a plugin:

1. Create a Python package with a class inheriting from `wt_tools.Plugin`
2. Implement required methods (`info`, etc.)
3. Register via entry point in `pyproject.toml`:
   ```toml
   [project.entry-points."wt_tools.plugins"]
   your-plugin = "your_package:YourPlugin"
   ```

See `wt_tools/plugins/base.py` for the plugin interface.

## Reporting Issues

When reporting issues, please include:
- Operating system and version
- Python version
- Steps to reproduce
- Expected vs actual behavior
- Relevant log output

## Pull Requests

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

### PR Checklist

- [ ] Tests pass
- [ ] Code follows style guidelines
- [ ] Documentation updated (if needed)
- [ ] Commit messages are clear
- [ ] Changes are focused and minimal

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
