from __future__ import print_function

import shutil
import tempfile
import errno


class TemporaryDirectory(object):
    """Context manager for tempfile.mkdtemp() so it's usable with "with" statement."""

    def __enter__(self):
        self.name = tempfile.mkdtemp()
        return self.name

    def __exit__(self, exc_type, exc_value, traceback):
        try:
            shutil.rmtree(self.name)  # delete directory
        except OSError as exc:
            if exc.errno != errno.ENOENT:  # ENOENT - no such file or directory
                raise  # re-raise exception
