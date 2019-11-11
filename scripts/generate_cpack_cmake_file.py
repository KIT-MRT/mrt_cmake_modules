'''
Reads the package.xml and generator a CMake file which uses CPack to create a debian package.

@author: Johannes Beck
@email: johannes.beck@kit.edu
@license: GPLv3
@version: 1.0.0
'''
from __future__ import print_function

import argparse
import platform
import sys
import os
import traceback

from bloom.generators.debian.generator import generate_substitutions_from_package
from catkin_pkg.packages import find_packages
from mrt_cmake_modules.packaging.utility import get_os_distro
from mrt_cmake_modules.packaging.utility import get_ros_distro
from mrt_cmake_modules.packaging.utility import get_apt_package_name
from mrt_cmake_modules.utility import eprint


class MrtCPackCMakeGenerator(object):
    def generate(self, root_workspace, package_name, output_file):
        os_distro = get_os_distro()
        ros_distro = get_ros_distro()
        bloom_apt_data = self._get_bloom_apt_data(
            root_workspace, package_name, os_distro, ros_distro)

        with open(output_file, "w") as f:
            apt_package_name = get_apt_package_name(package_name)
            f.write('set(CATKIN_BUILD_BINARY_PACKAGE "1")\n')
            f.write('set(CPACK_SET_DESTDIR true)\n')
            f.write('set(CPACK_GENERATOR DEB)\n')
            f.write('set(CPACK_PACKAGE_NAME "{}")\n'.format(apt_package_name))
            f.write('set(CPACK_PACKAGE_FILE_NAME "{}")\n'.format(apt_package_name))
            f.write(
                'set(CPACK_PACKAGE_VERSION "{}-${{MRT_PKG_TIMESTAMP}}")\n'.format(bloom_apt_data['Version']))
            f.write('set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "{}")\n'.format(
                bloom_apt_data['Description']))
            f.write('set(CPACK_DEBIAN_PACKAGE_MAINTAINER "{}")\n'.format(
                bloom_apt_data['Maintainer']))

            self._write_package_deps(f, bloom_apt_data, 'Depends')
            self._write_package_deps(f, bloom_apt_data, 'Replaces')
            self._write_package_deps(f, bloom_apt_data, 'Conflicts')

            f.write('set(CPACK_DEBIAN_DEBUGINFO_PACKAGE "ON")\n')

            f.write('include(CPack)\n')

    def _write_package_deps(self, f, bloom_apt_data, name):
        if bloom_apt_data[name]:
            f.write('set(CPACK_DEBIAN_PACKAGE_{} "{}")\n'.format(
                name.upper(), ", ".join(bloom_apt_data[name])))

    def _workspace_resolver(self, pkg_name, peer_packages):
        if pkg_name not in peer_packages:
            raise RuntimeError(
                "The requested package is not in the current workspace.")

        return [get_apt_package_name(pkg_name)]

    def _get_bloom_apt_data(self, root_workspace, package_name, os_distro, ros_distro):
        pkgs_dict = find_packages(root_workspace)
        if len(pkgs_dict) == 0:
            raise RuntimeError(
                "No packages found in path: '{0}'".format(root_workspace))

        pkg = None
        for ws_pkg in pkgs_dict.values():
            if ws_pkg.name == package_name:
                pkg = ws_pkg
                break

        if not pkg:
            raise RuntimeError("The requested package '{}' is not in '{}'".format(
                package_name, root_workspace))

        # Resolve apt dependencies using bloom.
        peer_packages = [i.name for i in pkgs_dict.values()
                         if i != package_name]

        bloom_apt_data = generate_substitutions_from_package(
            pkg, "ubuntu", os_distro, ros_distro, fallback_resolver=self._workspace_resolver, peer_packages=peer_packages, native=True)
        return bloom_apt_data


if __name__ == "__main__":
    try:
        parser = argparse.ArgumentParser(description='MRT CMake CPack file generator.')
        parser.add_argument('root_workspace_dir',
                            help='The root workspace dir.')
        parser.add_argument('package_name',
                            help='The catkin package name.')
        parser.add_argument('output_file',
                            help='The destination file path, where the CMake CPack file should be written.')

        args = parser.parse_args()

        root_workspace_dir = args.root_workspace_dir.strip("\n")
        package_name = args.package_name.strip("\n")
        output_file = args.output_file.strip("\n")

        generator = MrtCPackCMakeGenerator()
        generator.generate(root_workspace_dir, package_name, output_file)
    except Exception:
        error = traceback.format_exc()
        eprint(error)
        sys.exit(1)
