"""CLI entry point for cosmo-file.

This module provides the command-line interface that forwards all arguments
directly to the file.com binary, streaming stdin/stdout/stderr transparently.
"""

import sys
import subprocess
import platform
from . import get_binary_path


def main():
    """Main CLI entry point.

    Executes the file.com binary with all command-line arguments,
    forwarding stdin/stdout/stderr directly to the parent process.

    Returns:
        Exit code from the file command.
    """
    try:
        binary = get_binary_path()
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    # Execute the binary with all arguments, streaming I/O
    try:
        result = subprocess.run(
            (
                [str(binary)]
                if platform.system() != "Linux"
                else ["sh", str(binary)]
            ) + sys.argv[1:],
            stdin=sys.stdin.buffer if sys.stdin.isatty() else sys.stdin.buffer,
            stdout=sys.stdout.buffer,
            stderr=sys.stderr.buffer,
        )
        return result.returncode
    except KeyboardInterrupt:
        return 130  # Standard exit code for SIGINT
    except Exception as e:
        print(f"Error executing file command: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
