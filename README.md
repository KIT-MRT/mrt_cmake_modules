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
When working with ROS and Parameters, there are a couple of tools to help you with handing Parameters to your nodes and to modify them, e.g. [Parameter Server](http://wiki.ros.org/Parameter%20Server) and [dynamic_reconfigure](http://wiki.ros.org/dynamic_reconfigure/).

But with the multitude of options on where to specify your parameters, we often face the problem that we get a redundancy in our code and config files.

The `generate_parameter_files` macro helps you to specify your parameters in a single file and to generate all necessary headers from there.

### What you have to do
Create a `.mrtcfg` file in the `cfg` folder of your package. (e.g. If your node is called `my_dummy_node`, then name the file `cfg/MyDummy.mrtcfg`)
It should have at least the following content:
```python
#!/usr/bin/env python
from mrt_cmake_modules.parameter_generator_catkin import *
gen = ParameterGenerator()

# Add your desired parameters here. All required headers will be generated from this.

#Syntax : Package, Node, Config Name(The final name will be MyDummyConfig)
exit(gen.generate("my_dummy_ros_tool", "my_dummy_node", "MyDummy"))

```
For every parameter you need add a line like this:
```python
gen.add(name, paramtype, description, default=None, min=None, max=None, configurable=False, global_scope=False)
```
It has the following arguments:

- name: The name of your variable
- paramtype: Any of *std::string*, *int*, *bool*, *float*, *double* or containerized types of these: *std::vector<...>*, *std::map<std::string,...>*
- description: A meaningfull and understandable description of what this parameter does.
- default (optional): Default value for this parameter. If not provided you will have to pass it from your launchfile or similar.
- min (optional): Only of interest when using dynamic reconfigure -> min allowed value
- max (optional): Only of interest when using dynamic reconfigure -> max allowed value
- configurable (optional): Make this parameter reconfigurable at run time. Default: False
- global_scope (optional): Make this parameter live in the global namespace. Default: False

### What it will do for you
1. Create `MyDummy.cfg` file in the devel/share space and call dynamic_reconfigure for you to generate `MyDummyConfig.h`.
(It will also call `generate_dynamic_reconfigure_options` with all other `*.cfg` files in your package, so you don't need to do that in your `CMakeLists.txt` anymore.)
2. Create a header that defines a `MyDummyParameters`-SingletonStruct that holds all your parameters.
Include it with
```cpp
#include "my_dummy_ros_tool/MyDummyParameters.h"
```
When initializing your node, call:
```cpp
MyDummyParameters& params = MyDummyParameters::getInstance()
params.fromParamServer();
```
This will take care of getting all parameter values from the parameter server, checking their type, and checking that a default value is set, if you haven't provided one on your own in the `mrtcfg` file.  
Your dynamic_reconfigure callback looks as simple as:
```cpp
void reconfigureRequest(MyDummyConfig& config, uint32_t level) {
    params.fromConfig(config);
}
```
This will update all values that were specified as configurable. At the same time, it assures that all dynamic_reconfigure parameters live in the same namespace as those on the parameter server to avoid problems with redundant parameters.

As always, the [MRT tools](https://gitlab.mrt.uni-karlsruhe.de/MRT/mrt_build) provide templates for the config file as well as for a sample node.
