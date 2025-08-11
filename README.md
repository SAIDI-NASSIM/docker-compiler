# Docker Compiler

**Compile and run your code using Docker containers as compiler interfaces.**

Use Docker images to compile C, Go, and Rust projects without installing toolchains locally. Project files are mounted into containers for seamless development workflow.

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh compilers/*.sh utils/*.sh

# Run the compiler
./main.sh
```

1. Select your language (C, Go, Rust)
2. Point to your project directory
3. Choose: build only or build + run

## How It Works

- **Docker Images**: Uses official compiler images (`gcc:bookworm`, `golang:alpine`, `rust:alpine`)
- **Volume Mounting**: Your project directory is mounted into the container
- **Smart Detection**: Automatically detects project structure (Makefile, go.mod, Cargo.toml)
- **Local Output**: Compiled binaries are saved in your project directory

## Supported Languages

| Language | Auto-Detection | Build Tools |
|----------|---------------|-------------|
| **C** | `*.c` files, Makefile | make or gcc |
| **Go** | `*.go` files, go.mod | go modules or simple build |
| **Rust** | `*.rs` files, Cargo.toml | cargo or rustc |

## Project Structure

```
project/
├── main.sh              # Main entry point
├── config/
│   └── languages.json   # Language configurations
├── compilers/           # Language-specific scripts
├── utils/               # Helper functions
└── tests/               # Test projects and examples
```

## Configuration

Customize language settings in `config/languages.json`:

```json
{
  "languages": {
    "go": {
      "name": "Go",
      "extensions": [".go"],
      "docker_image": "golang:alpine",
      "detection": {
        "required_files": ["*.go"],
        "optional_files": ["go.mod", "go.sum"],
        "search_depth": 5,
        "exclude_paths": ["vendor", "node_modules", ".git", "build", "dist"]
      },
      "build": {
        "with_modules": "go mod tidy && go build -o app .",
        "without_modules": "go build -o app *.go"
      },
      "run": "./app"
    }
  }
}
```

**Key Configuration Options:**
- `search_depth`: How deep to search for source files (max levels)
- `exclude_paths`: Directories to skip during file detection
- `required_files`: File patterns that must exist for language detection
- `optional_files`: Files that indicate project type (Makefile, go.mod, etc.)

## Requirements

- Docker
- Bash
- File system with execution permissions

## Tested Project Layouts

This tool has been tested locally on various project structures for all three languages:

- **Basic**: Single file projects (`main.c`, `main.go`, `main.rs`)
- **With Dependencies**: Projects using external libraries (go.mod, Cargo.toml, custom headers)
- **Advanced**: Complex folder structures with multiple modules and build configurations

**Portable but Customizable**: If your project has a particular folder layout, adapt the `config/languages.json` to match your structure. Adjust `search_depth`, `exclude_paths`, and file patterns as needed.

## Adding Languages

The system is scalable for daily use via configuration. Adding a new language:

1. Add language entry to `config/languages.json`
2. Create corresponding compiler script in `compilers/`
3. Docker will automatically pull the specified image

**Contributions welcome** - especially for additional languages and project layouts.

## Docker Image Management

- **Containers**: Automatically removed after compilation
- **Images**: Kept locally for faster subsequent builds
- **Cleanup**: Run `docker image prune` if storage space is needed

*Keeping images speeds up compilation for multiple projects of the same language.*

---

*Clean, portable compilation without local toolchain installation.*
