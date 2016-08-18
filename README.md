# mrt_cmake_modules
## Package Summary
This package provides the necessary cmake scripts to make use of several helper functions like e.g. the AutoDeps or the MRT ParamGenerator functionality.

- Maintainer status: maintained
- Maintainer: Johannes Beck <johannes.beck@kit.edu>, Claudio Bandera <claudio.bandera@kit.edu>
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
                          package, e.g. boost, opencv.
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
