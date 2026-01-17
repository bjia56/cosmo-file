"""cosmo-file: Cosmopolitan builds of file(1) as a Python package.

This package provides the file(1) command-line utility built with Cosmopolitan libc,
allowing file type detection across multiple platforms from a single universal binary.

Example:
    >>> import cosmo_file
    >>> result = cosmo_file.run('example.txt')
    >>> print(result.stdout.decode())
    example.txt: ASCII text

    >>> # Or use from command line:
    $ cosmo-file example.txt
    example.txt: ASCII text
"""

import platform
import subprocess
from pathlib import Path
from typing import Union, Optional

from ._version import __version__

__all__ = ["run"]


def get_binary_path() -> Path:
    """Get the path to the file.com binary.

    Returns:
        Path object pointing to the file.com binary.

    Raises:
        FileNotFoundError: If the binary cannot be found.
    """
    binary_path = Path(__file__).parent / "data" / ("file.com" if platform.system() != "Linux" else "file.elf")
    if binary_path.exists():
        return binary_path
    raise FileNotFoundError(
        f"file.com binary not found at {binary_path}. "
        "The package may not be properly installed."
    )


def get_pledge_path() -> Path:
    """Get the path to the pledge binary.

    Returns:
        Path object pointing to the pledge binary.

    Raises:
        FileNotFoundError: If the pledge binary cannot be found.
    """
    if platform.system() != "Linux":
        raise FileNotFoundError("pledge binary is only available on Linux systems.")

    pledge_path = Path(__file__).parent / "data" / "pledge"
    if pledge_path.exists():
        return pledge_path
    raise FileNotFoundError(
        f"pledge binary not found at {pledge_path}. "
        "The package may not be properly installed."
    )


def get_base_command() -> list[str]:
    """Get the base command to execute the file.com binary.

    Returns:
        List of command components to execute the binary.
    """
    binary = get_binary_path()
    if platform.system() == "Windows":
        return [str(binary)]
    else:
        if platform.system() == "Linux":
            pledge = get_pledge_path()
            return [
                "sh",
                str(pledge), "-V", "-p", "stdio rpath",
                str(binary),
            ]
        return ["sh", str(binary)]


def run(
    *args: Union[str, Path],
    stdin: Optional[Union[str, bytes]] = None,
    capture_output: bool = True,
    check: bool = False,
    **kwargs
) -> subprocess.CompletedProcess:
    """Run the file command with the given arguments.

    Args:
        *args: Arguments to pass to the file command (e.g., file paths, options).
        stdin: Optional input to pass to stdin (str or bytes).
        capture_output: If True, capture stdout and stderr. If False, they go to
                       the parent process streams.
        check: If True, raise CalledProcessError if the command returns non-zero.
        **kwargs: Additional keyword arguments to pass to subprocess.run().

    Returns:
        CompletedProcess instance with returncode, stdout, stderr attributes.

    Raises:
        FileNotFoundError: If the file.com binary cannot be found.
        subprocess.CalledProcessError: If check=True and command fails.

    Example:
        >>> result = cosmo_file.run('--version')
        >>> print(result.stdout.decode())

        >>> result = cosmo_file.run('-b', 'image.png')  # Brief mode
        >>> print(result.stdout.decode())

        >>> result = cosmo_file.run('-', stdin=b'#!/bin/bash\\necho test')
        >>> print(result.stdout.decode())
        /dev/stdin: Bourne-Again shell script, ASCII text executable
    """
    # Convert all args to strings
    cmd = get_base_command() + [str(arg) for arg in args]

    # Handle stdin
    stdin_input = None
    if stdin is not None:
        if isinstance(stdin, str):
            stdin_input = stdin.encode()
        else:
            stdin_input = stdin

    # Run the command
    return subprocess.run(
        cmd,
        input=stdin_input,
        capture_output=capture_output,
        check=check,
        **kwargs
    )
