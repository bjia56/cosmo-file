"""Version information for cosmo-file package.

This module defines the version of the Python package and the upstream file(1) version
being packaged.

Versioning scheme: {FILE_MAJOR}.{FILE_MINOR}.{PACKAGE_PATCH}
  - FILE_MAJOR.FILE_MINOR: Version of upstream file(1) being packaged
  - PACKAGE_PATCH: Python package-specific updates (starts at 0 for each new file version)

Examples:
  - 5.46.0: First release packaging file 5.46
  - 5.46.1: Bugfix/improvement to Python packaging for file 5.46
  - 5.47.0: First release packaging file 5.47
"""

# Python package version
__version__ = "5.46.3"

# Git tag from https://github.com/file/file/tags to build
FILE_GIT_TAG = "FILE5_46"