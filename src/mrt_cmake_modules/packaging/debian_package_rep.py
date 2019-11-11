from __future__ import print_function

from temporary_directory import TemporaryDirectory
import os
import subprocess
import hashlib
from debian import deb822


class DebianPackageRep(object):
    def __init__(self, debian_file_name):
        # Extract control part of debian file and parse those files.
        data = {}

        with TemporaryDirectory() as control_folder:
            subprocess.check_call(
                ['dpkg', '-e', debian_file_name, control_folder])

            for filename in os.listdir(control_folder):
                path = os.path.join(control_folder, filename)
                res = None
                if filename == "control":
                    res = self._parse_control_file(path)
                elif filename == "md5sums":
                    res = self._parse_md5_sums(path)
                elif filename not in ['triggers', 'shlibs']:
                    res = self._parse_other_files(path)

                if res:
                    data[filename] = res

        self.data = data

    def __eq__(self, other):
        if isinstance(other, DebianPackageRep):
            return self.data == other.data
        return False

    def __ne__(self, other):
        return not self.__eq__(other)

    def _parse_package_name(self, control_file_name):
        return deb822.Deb822(open(control_file_name))['name']

    def _parse_control_file(self, control_file_name):
        res = []
        for pkg in deb822.Packages.iter_paragraphs(open(control_file_name)):
            rels = pkg.relations
            res += [sorted(deps, key=lambda x: x['name'])
                    for deps in rels['depends']]

        res.sort(key=lambda x: [p['name'] for p in x])
        return res

    def _parse_md5_sums(self, md5_sums_file_name):
        res = {}
        with open(md5_sums_file_name) as f:
            for l in f.read().split("\n"):
                entry = l.split(" ", 1)
                if len(entry) == 2:
                    res[entry[0]] = entry[1].strip(" ")

        return hashlib.md5(" ".join(res)).hexdigest()

    def _parse_other_files(self, other_file_name):
        with open(other_file_name) as f:
            return hashlib.md5(f.read()).hexdigest()
