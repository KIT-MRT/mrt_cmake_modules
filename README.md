# mrt_cmake_modules
## Package Summary
This package provides the necessary cmake scripts to make use of several helper functions like e.g. the AutoDeps or the MRT ParamGenerator functionality and adds functions to simplify writing CMakeLists.txt files.

The mrt_cmake_modules contains the following functionalities to provide simple and portable build and [dependency management](#dependency-management):
* [Simplified CMake functions](#cmake-api)
* [Resolve Debian packages](#base-yaml)
* [Finding thirdparty packages](#findscripts)


Maintainer status: maintained
- Maintainer: Johannes Beck <johannes.beck@kit.edu>, Claudio Bandera <claudio.bandera@kit.edu>, Fabian Poggenhans <fabian.poggenhans@kit.edu>
- Author: Johannes Beck <johannes.beck@kit.edu>
- License: GPL-3.0+
- Bug / feature tracker: https://gitlab.mrt.uni-karlsruhe.de/MRT/mrt_cmake_modules/issues
- Source: git https://gitlab.mrt.uni-karlsruhe.de/MRT/mrt_cmake_modules.git (branch: master)

## Dependency management
When using the *mrt_cmake_modules* it is enough to specify your dependencies in your manifest file (i.e. `package.xml`). In your `CMakeLists.txt`, add the following lines, to automatically resolve those dependencies:
```cmake
find_package(mrt_cmake_modules REQUIRED)
include(UseMrtStdCompilerFlags)
include(UseMrtAutoTarget)
include(GatherDeps)
find_package(AutoDeps REQUIRED COMPONENTS ${DEPENDEND_PACKAGES})
```
Your manifest file should contain at least the following to dependencies:
```xml
<buildtool_depend>catkin</buildtool_depend>
<build_depend>mrt_cmake_modules</build_depend>
```
Other dependecies can be added with one of the following tags:
```xml
<build_depend>            Build-time dependency required to build
                          this package, e.g. boost, opencv.
<build_export_depend>     Exported build-time dependency required to
                          build packages that depend on this package,
                          e.g. boost, opencv.
<exec_depend>             Execution dependency required to run this
                          package, e.g. boost, opencv, but also all
                          python dependencies such as python-scipy.
<depend>                  Build-time, exported build-time and execution
                          dependency. This is a bundled synonym for
                          <build_depend>, <build_export_depend> and
                          <exec_depend>.
```
Additionally, the [MRT tools](https://gitlab.mrt.uni-karlsruhe.de/MRT/mrt_build) provide templates for both `CMakeLists.txt` and `package.xml`, that should be used for creating new packages.

## Unified Parameter Handling for ROS
**UPDATE**: the Documentation for the ParameterGenerator can be found [here](https://github.com/cbandera/rosparam_handler).  
The MRT version extends the GitHub version, by allowing the _mrtcfg_ fileending and integrating it into the CMake-Templates.

As always, the [MRT tools](https://gitlab.mrt.uni-karlsruhe.de/MRT/mrt_build) provide templates for the config file as well as for a sample node.

## CMake API
This package contains a lot of useful cmake functions that are automatically available in all packages using the _mrt_cmake_modules_ as dependency, e.g. `mrt_install()`, `mrt_add_node_and_nodelet()`, etc. See [here](http://htmlpreview.github.io/?https://github.com/KIT-MRT/mrt_cmake_modules/blob/master/doc/generated_cmake_api.html) for a full documentation.

## Base yaml
The [base.yml](yaml/base.yaml) controls how AutoDeps and Rosdep finds thirdparty dependencies.

__Rosdep__ is a tool that resolves and installs dependencies in package.xml files by searching the base.yaml (those added to the list of files in `/etc/ros/rosdep/sources.list.d/20-default.list`) for a matching entry and then installing the debian package stated in the _ubuntu_ section of each entry via `apt-get`.

__AutoDeps__ (provided by this package) is used to resolve dependencies in the _package.xml_ at CMAKE configure time so that the paths to all thirdparty libraries are known. It searches the _base.yaml_ for matching entries and evaluates the _cmake_ section of matching entry to find out which include/library paths will be set when calling the CMake Command `find_package()`. Only for `<exec_depend>`, CMAKE variables are not set.

## Findscripts
This package also contains a collection of [find-scripts](cmake/Modules) for thirdparty dependencies that are usually not shipped with a findscript. These are required by __AutoDeps__.
