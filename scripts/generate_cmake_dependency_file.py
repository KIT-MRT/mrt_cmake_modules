'''
Reads a catkin package xml file, extract all dependencies and generate
a cmake which is used by FindDependendPackages.cmake to automatically
find_package catkin and non-catkin packages.

This script must be called in a ROS environment so that rospack find
all of catkin packages.

Created on Jul 1, 2015

@author: Johannes Beck
@email: johannes.beck@kit.edu
@license: GPLv3
@version: 1.0.0
'''
from __future__ import print_function

import os
import sys
import subprocess
import platform
import xml.etree.ElementTree as ET
import yaml
from catkin_pkg.packages import find_packages
from string import Template
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader
if sys.version_info >= (3, 0):
    import ast.literal_eval as eval_expr
else:
    eval_expr = eval # with python2 we have to just hope no one uses "rm -rf /" as condition in his package.xml...


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


class PackageType:
    """Package type. This can be either a catkin package or an other one."""
    catkin, other = range(2)


class Dependency:
    """Stores a dependency."""
    packageType = PackageType()
    name = ""
    build_depend = False
    build_export_depend = False
    test_depend = False
    optional = True

    def isCatkin(self):
        return self.packageType == PackageType.catkin

    def __repr__(self):
        return "Dependency(name:%s type:%s buld_depend:%s build_export_depend:%s test_depend:%s)" % (self.name, self.packageType, self.build_depend,
                                                                                                     self.build_export_depend, self.test_depend)


class PackageCMakeData:
    """Stores information about how to find_package non-catkin packages"""
    name = ""
    includeDirs = list()
    """contains the cmake variables names of the include dirs (e.g. defined by a call to find_package(...))"""

    libraryDirs = list()
    """contains the cmake variables names of the library dirs (e.g. defined by a call to find_package(...))"""

    libraries = list()
    """contains the cmake variables names of the libraries (e.g. defined by a call to find_package(...))"""

    components = list()
    """contains the components, which are used in find_package (e.g. defined by a call to find_package(<name> COMPONENTS ...))"""

    targets = list()
    """contains the targets which are defined when calling find_package(...)"""

    def __init__(self, data={}):
        """Init cmake package data from a dict"""
        self.name = data.get("name", "")
        self.includeDirs = data.get("include_dirs", list())
        self.libraryDirs = data.get("library_dirs", list())
        self.libraries = data.get("libraries", list())
        self.components = data.get("components", list())
        self.targets = data.get("targets", list())
        self.warning = data.get("warning", "")

    def __nonzero__(self):
        return bool(self.name)

    def __repr__(self):
        return "PackageCMakeData(name:" + self.name + " include_dirs:" + str(self.includeDirs) + " library_dirs:" + \
            str(self.libraryDirs) + " libraries:" + \
            str(self.libraries) + " components:" + str(self.components)


def findWorkspaceRoot(packageXmlFilename):
    """
    Tries to find the root of the workspace by search top down
    and looking for a CMakeLists.txt or .catkin_tools file / folder. If no
    workspace is found an empty string is returned.

    @param[in] packageXmlFilename: package xml file name
    """

    pathOld = ""
    pathNew = os.path.dirname(os.path.abspath(packageXmlFilename))

    while pathOld != pathNew:
        pathOld = pathNew
        pathNew = os.path.dirname(pathOld)

        files = os.listdir(pathNew)
        if ".catkin_tools" in files:
            return(os.path.join(pathNew, "src"))

        if "CMakeLists.txt" in files:
            return(pathNew)

    return ""


def readPackageCMakeData(rosDebYamlFileName):
    """
    Read the cmake meta data for packages from a rosdep yaml file.
    The yaml file format is extended with a cmake node:
    package1:
      ubuntu: [ ... ]
      cmake:
        xenial/trusty:
          name: ...
          include_dirs: []
          library_dirs: []
          libraries: []
          components: []
    """
    # load ros dep yaml file
    f = open(rosDebYamlFileName, "r")
    rosDebYamlData = yaml.load(f, Loader=Loader)

    # dictionary for storing cmake dependencies
    # e.g. { "<package name 1>" -> PackageCMakeData, "<package name 2>" -> PackageCMakeData ... }
    data = {}
    distro = platform.dist()[2]
    if 'ROS_OS_OVERRIDE' in os.environ:
        ros_os_override = os.environ['ROS_OS_OVERRIDE'].split(':')
        if len(ros_os_override) == 2:
            distro = ros_os_override[1]

    for packageName, packageCMakeData in rosDebYamlData.items():
        # find out which distribution
        if "name" in packageCMakeData:
            data[packageName] = PackageCMakeData(packageCMakeData)
        elif distro in packageCMakeData:
            data[packageName] = PackageCMakeData(packageCMakeData[distro])
        elif not packageCMakeData:
            data[packageName] = PackageCMakeData() # placeholder
    return data


def parseManifest(parsed_xml, catkin_packages, validate=True):
    # check catkin package xml file
    if validate:
        if parsed_xml.tag != 'package':
            raise Exception("Cannot find package node in xml file")
        if 'format' not in parsed_xml.attrib:
            raise Exception(
                "Catkin package format must be 2. Change package.xml to <package format=\"2\">")
        if not (parsed_xml.attrib['format'] == "2" or parsed_xml.attrib['format'] == "3"):
            raise Exception("Package format must be 2 or 3")

    # variable used to hold the Dependency classes from the package xml
    depends = []
    cuda_depends = []

    for child in parsed_xml:
        depend = Dependency()

        # check conditions
        condition = child.get("condition")
        if condition:
            try:
                is_fulfilled = eval_expr(Template(condition).substitute(os.environ))
            except:
                if validate:
                    raise
                is_fulfilled = True
            if not is_fulfilled:
                continue

        # check tag
        if child.tag == "depend":
            depend.build_depend = True
            depend.build_export_depend = True
            depend.test_depend = True
        elif child.tag == "build_depend":
            depend.build_depend = True
            depend.build_export_depend = False
            depend.test_depend = False
        elif child.tag == "build_export_depend":
            depend.build_depend = True
            depend.build_export_depend = True
            depend.test_depend = False
        elif child.tag == "test_depend":
            depend.build_depend = False
            depend.build_export_depend = False
            depend.test_depend = True
        elif child.tag == "export":
            for export_child in child:
                if export_child.tag == "cuda_depend":
                    cuda_depends.append(export_child.text)
            continue
        else:
            continue

        # get name
        depend.name = child.text

        # check if catkin package
        depend.packageType = PackageType.catkin if depend.name in catkin_packages else PackageType.other

        depends.append(depend)
    return depends, cuda_depends


def gatherDependeciesRecursive(manifest, catkin_packages, ignored_packages=set()):
    first_pass = not ignored_packages
    all_deps, cuda_depends = parseManifest(manifest, catkin_packages, validate=first_pass)
    depends = all_deps if first_pass else []
    for dep in depends:
        # only first-level dependencies have to be resolved, all others are resolved if possible.
        dep.optional = False
    # recursively gather the build_export_depends of these dependencies
    for dep in all_deps:
        if not first_pass and not dep.build_export_depend:
            continue
        if dep.name in ignored_packages:
            continue
        ignored_packages.add(dep.name)
        if not first_pass and not dep.isCatkin():
            depends.append(dep)
        if dep.isCatkin():
            depends += gatherDependeciesRecursive(catkin_packages[dep.name], catkin_packages, ignored_packages)[0]
    return depends, cuda_depends


def getCatkinPackages(workspaceRoot):
    """Get all available catkin packages"""
    manifest = "package.xml"
    catkin_ignore = "CATKIN_IGNORE"
    nosubdirs = "rospack_nosubdirs"
    ros_package_env = "ROS_PACKAGE_PATH"

    def getPackagesInPath(packages, path):
        for root, dirs, files in os.walk(path, topdown=True, followlinks=True):
            if catkin_ignore in files:
                dirs[:] = []  # instruct walk to not recurse deeper
                continue
            if manifest in files:  # found a package
                package = ET.parse(os.path.join(root, manifest)).getroot()
                export = package.find("export")
                # ignore metapackages
                if export is None or export.find("metapackage") is None:
                    name = package.findtext("name", default=os.path.basename(root))
                    if not name in packages:
                        packages[name] = package
                dirs[:] = []
                continue
            if nosubdirs in files:
                dirs[:] = []  # package is tagged to not recurse
                continue

    package_paths = {}
    paths = os.environ.get(ros_package_env, "").split(":")
    paths.append(workspaceRoot)
    packages = {}
    for path in paths:
        getPackagesInPath(packages, path)
    return packages


def main(packageXmlFile, rosDepYamlFileName, outputFile):
    """
    Reads a catkin package xml file, extract all dependencies and generate
    a cmake which is used by FindDependendPackages.cmake to automatically
    find_package catkin and non-catkin packages.

    This script must be called in a ROS environment so that rospack find
    all of catkin packages.

    @param[in] packageXmlFile: catkin package xml file name
    @param[in] rosDepYamlFileName: name of the ros dep yaml file which contains the
                               cmake information for non-catkin packages
    @param[out] outputFile: File name to the generated cmake file
    """
    # read package xml file
    tree = ET.parse(packageXmlFile).getroot()

    # get all catkin packages to distinguish between
    # catkin and non-catkin packages
    workspaceRoot = findWorkspaceRoot(os.path.abspath(packageXmlFile))
    catkin_packages = getCatkinPackages(workspaceRoot)
    # read rosdep yaml file for cmake variables used for non-catkin packages
    # to automatically create a find_package(...)
    cmakeVarData = readPackageCMakeData(rosDepYamlFileName)

    depends, cuda_depends = gatherDependeciesRecursive(tree, catkin_packages)
    # clear optional deps for which no cmake data is available
    depends = [d for d in depends if d.isCatkin() or not d.optional or d.name in cmakeVarData]
    # check CUDA depends and categorize them as either catkin or other package
    depends_names = {d.name for d in depends}
    cuda_catkin_depends = []
    cuda_other_depends = []
    for cuda_depend in cuda_depends:
        if cuda_depend not in depends_names:
            raise Exception(("CUDA package {0} specified as dependency but not specified "
                             "as regular <depend...>. Please add a depend like <depend>{0}"
                             "</depend> to your package.xml.").format(cuda_depend))

        if cuda_depend in catkin_packages:
            cuda_catkin_depends.append(cuda_depend)
        else:
            cuda_other_depends.append(cuda_depend)

    # output variables
    out = {}
    out["dependend_packages"] = " ".join(depend.name for depend in depends)
    out["catkin_pkgs"] = " ".join(s.name  for s in depends if s.isCatkin() and s.build_depend)
    out["catkin_exp_pkgs"] = " ".join(s.name  for s in depends if s.isCatkin() and s.build_export_depend)
    out["catkin_test_pkgs"] = " ".join(s.name  for s in depends if s.isCatkin() and s.test_depend)
    out["other_pkgs"] = " ".join(s.name  for s in depends if not s.isCatkin() and s.build_depend)
    out["other_exp_pkgs"] = " ".join(s.name  for s in depends if not s.isCatkin() and s.build_export_depend)
    out["other_test_pkgs"] = " ".join(s.name  for s in depends if not s.isCatkin() and s.test_depend)

    # generate output file
    f = open(outputFile, "w")

    text = ("#This is an autogenerated file. Do not edit!\n"
            "#Changes will be overritten the next time cmake runs.\n"
            "\n"
            "set(DEPENDEND_PACKAGES $dependend_packages)\n"
            "set(_CATKIN_PACKAGES_ $catkin_pkgs)\n"
            "set(_CATKIN_EXPORT_PACKAGES_ $catkin_exp_pkgs)\n"
            "set(_CATKIN_TEST_PACKAGES_ $catkin_test_pkgs)\n"
            "set(_OTHER_PACKAGES_ $other_pkgs)\n"
            "set(_OTHER_EXPORT_PACKAGES_ $other_exp_pkgs)\n"
            "set(_OTHER_TEST_PACKAGES_ $other_test_pkgs)\n\n"
            )

    f.write(Template(text).substitute(out))

    # write CUDA catkin / other packages
    if cuda_catkin_depends:
        f.write("set(_CUDA_CATKIN_PACKAGES_ %s)\n" %
                ' '.join(cuda_catkin_depends))
    if cuda_other_depends:
        f.write("set(_CUDA_OTHER_PACKAGES_ %s)\n" %
                ' '.join(cuda_other_depends))

    # write cmake variables (only those which are used in this package)
    for depend in (s for s in depends if s.name in cmakeVarData):
        cmakeData = cmakeVarData[depend.name]
        if not cmakeData:
            # package needs no cmake definition
            f.write("set(_{}_NO_CMAKE_ 1)\n".format(depend.name))
            continue

        f.write("set(_" + depend.name + "_CMAKE_NAME_ " + cmakeData.name + ")\n")
        if cmakeData.includeDirs:
            f.write("set(_" + depend.name + "_CMAKE_INCLUDE_DIRS_ " +
                    ' '.join(cmakeData.includeDirs) + ")\n")
        if cmakeData.libraryDirs:
            f.write("set(_" + depend.name + "_CMAKE_LIBRARY_DIRS_ " +
                    ' '.join(cmakeData.libraryDirs) + ")\n")
        if cmakeData.libraries:
            f.write("set(_" + depend.name + "_CMAKE_LIBRARIES_ " +
                    ' '.join(cmakeData.libraries) + ")\n")
        if cmakeData.components:
            f.write("set(_" + depend.name + "_CMAKE_COMPONENTS_ " +
                    ' '.join(cmakeData.components) + ")\n")
        if cmakeData.targets:
            f.write("set(_" + depend.name + "_CMAKE_TARGETS_ " +
                    ' '.join(cmakeData.targets) + ")\n")
        if cmakeData.warning and not depend.optional:
            eprint(cmakeData.warning)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
