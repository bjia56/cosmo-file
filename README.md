# cosmo-file

Cross-platform `file(1)` command built with Cosmopolitan libc, distributed as a Python package.

## Installation

```bash
pip install cosmo-file
```

## Usage

### Command Line

```bash
cosmo-file document.pdf
cosmo-file --version
echo "#!/bin/bash" | cosmo-file -
```

### Python API

```python
import cosmo_file

result = cosmo_file.run('image.png')
print(result.stdout.decode())
```

## Features

- Single universal binary runs on Windows, macOS, and Linux
- No external dependencies
- Python 3.8+ compatible
- Supports all `file` command options

## Platforms

- Windows x64
- macOS x86_64 / ARM64
- Linux x86_64 / ARM64

## Building from Source

Requires [cosmocc](https://cosmo.zip/pub/cosmocc/):

```bash
./scripts/build_file_com.sh
pip install -e .
```

## License

MIT (Python packaging) - See [LICENSE](LICENSE)

The bundled `file` utility is from [file/file](https://github.com/file/file) - See [COPYING](https://github.com/file/file/blob/master/COPYING)