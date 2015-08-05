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

import os
import sys
import subprocess
import xml.etree.ElementTree as ET
import yaml

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
    
    def __init__(self, data):
    	"""Init cmake package data from a dict"""
        self.name = data["name"]
        self.includeDirs = data["include_dirs"]
        self.libraryDirs = data.get("library_dirs", list())
        self.libraries = data.get("libraries", list())
        self.components = data.get("components", list())
        
    def __repr__(self):
        return "PackageCMakeData(name:" + self.name + " include_dirs:" + str(self.includeDirs) + " librariy_dirs:" + \
           str( self.libraryDirs) + " libraries:" + str(self.libraries) + " components:" + str(self.components)

def readPackageCMakeData(rosDebYamlFileName):
    """
    Read the cmake meta data for packages from a rosdep yaml file.
    The yaml file format is extended with a cmake node:
    package1:
      ubuntu: [ ... ]
      cmake:
        name: ...
        include_dirs: []
        library_dirs: []
        libraries: []
        components: []
    """
    #load ros dep yaml file
    f = open(rosDebYamlFileName, "r")
    rosDebYamlData = yaml.load(f)
    
    #dictionary for storing cmake dependencies 
    #e.g. { "<package name 1>" -> PackageCMakeData, "<package name 2>" -> PackageCMakeData ... }
    data = {}
    for packageName, packageCMakeData in rosDebYamlData.items():
        #check if cmake part is available. There could also be entries with no
        #cmake part (only ubuntu, etc.)
        if "cmake" in packageCMakeData:
            data[packageName] = PackageCMakeData(packageCMakeData["cmake"])
    
    return data

def getCatkinPackages():
    """Get all available catkin packages using rospack"""
    args = ['rospack', 'list-names']
    catkin_packages = subprocess.check_output(args).split('\n')
    return catkin_packages

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
    #read package xml file
    tree = ET.parse(packageXmlFile)
    
    #check catkin package xml file
    root = tree.getroot()
    if root.tag != 'package':
        raise Exception("Cannot find package node in xml file")
    if 'format' not in root.attrib:
        raise Exception("Catkin package format must be 2. Change package.xml to <package format=\"2\">")
    if root.attrib['format'] != "2":
        raise Exception("Package format must be 2")
    
    #get all catkin packages to distinguish between
    #catkin and non-catkin packages
    catkin_packages = getCatkinPackages()
    #read rosdep yaml file for cmake variables used for non-catkin packages
    #to automatically create a find_package(...)
    cmakeVarData = readPackageCMakeData(rosDepYamlFileName);
    
    #variable used to hold the Dependency classes from the package xml
    depends = []
    
    for child in root:
        depend = Dependency()
        
        #check tag
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
        else:
            continue
        
        #get name
        depend.name = child.text
        
        #check if catkin package
        if depend.name in catkin_packages:
            depend.packageType = PackageType.catkin
        else:
            depend.packageType = PackageType.other
        
        depends.append(depend)
    
    #generate output file
    f = open(outputFile, "w")
    
    #write auto generate content
    f.write("#This is an autogenerated file. Do not edit!\n")
    f.write("#Changes will be overritten the next time cmake runs.\n")
    f.write("\n")
    
    #write all dependend packages
    packages = set()
    for depend in depends:
        packages.add(depend.name)
        #packages += " " + depend.name
    
    f.write("set(DEPENDEND_PACKAGES %s)\n" % ' '.join(packages))
    
    #write catkin packages
    packages = set()
    for depend in (s for s in depends if s.packageType == PackageType.catkin and s.build_depend == True):
        packages.add(depend.name)
        
    f.write("set(_CATKIN_PACKAGES_ %s)\n" % ' '.join(packages))
    
    #write catkin export packages
    packages = set()
    for depend in (s for s in depends if s.packageType == PackageType.catkin and s.build_export_depend == True):
        packages.add(depend.name)
        
    f.write("set(_CATKIN_EXPORT_PACKAGES_ %s)\n" % ' '.join(packages))
    
    #write catkin test packages
    packages = set()
    for depend in (s for s in depends if s.packageType == PackageType.catkin and s.test_depend == True):
        packages.add(depend.name)
        
    f.write("set(_CATKIN_TEST_PACKAGES_ %s)\n" % ' '.join(packages))
        
    #write non-catkin packages
    packages = set()
    for depend in (s for s in depends if s.packageType == PackageType.other and s.build_depend == True):
        packages.add(depend.name)
        
    f.write("set(_OTHER_PACKAGES_ %s)\n" % ' '.join(packages))

    #write non-catkin export packages
    packages = set()
    for depend in (s for s in depends if s.packageType == PackageType.other and s.build_export_depend == True):
        packages.add(depend.name)
        
    f.write("set(_OTHER_EXPORT_PACKAGES_ %s)\n" % ' '.join(packages))
    
    #write non-catkin test packages
    packages = set()
    for depend in (s for s in depends if s.packageType == PackageType.other and s.test_depend == True):
        packages.add(depend.name)
        
    f.write("set(_OTHER_TEST_PACKAGES_ %s)\n" % ' '.join(packages))
    
    #write cmake variables (only those which are used in this package)
    for depend in (s for s in depends if s.name in cmakeVarData):
        cmakeData = cmakeVarData[depend.name]
        f.write("set(_" + depend.name + "_CMAKE_NAME_ " + cmakeData.name + ")\n")
        if cmakeData.includeDirs:
            f.write("set(_" + depend.name + "_CMAKE_INCLUDE_DIRS_ " + ' '.join(cmakeData.includeDirs) + ")\n")
        if cmakeData.libraryDirs:
            f.write("set(_" + depend.name + "_CMAKE_LIBRARY_DIRS_ " + ' '.join(cmakeData.libraryDirs) + ")\n")
        if cmakeData.libraries:
            f.write("set(_" + depend.name + "_CMAKE_LIBRARIES_ " + ' '.join(cmakeData.libraries) + ")\n")
        if cmakeData.components:
            f.write("set(_" + depend.name + "_CMAKE_COMPONENTS_ " + ' '.join(cmakeData.components) + ")\n")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
