^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Changelog for package mrt_cmake_modules
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1.0.11 (2024-09-20)
-------------------
* Merge pull request #38 from nobleo/fix/find-flann-cmake-module
  fix(FindFLANN): set(FLANN_FOUND ON) if target already defined
* Contributors: keroe

1.0.10 (2024-07-26)
-------------------
* FindGeographicLib: Fix for GeographicLib 2.* and Windows
  Since GeographicLib version 2, the library name changed from `libGeographic.so` to `libGeographicLib.so`, see https://github.com/geographiclib/geographiclib/blob/5e4425da84a46eb70e59656d71b4c99732a570ec/NEWS#L208 .
  To ensure that GeographicLib 2.* is found correcty, I think we should add also `GeographicLib` to the names used by `find_library`.
  Furthermore, on Windows the import library is called `GeographicLib-i.lib` (see https://github.com/geographiclib/geographiclib/blob/v2.3/src/CMakeLists.txt#L119), so to find the library correctly on Windows we also look for GeographicLib-i .
* add ortools
* Revert "mrt_add_library now adds a compilation tests for all headers used by the library"
  This reverts commit b05cac0200ce6b8de8e8a18789dbd58cd9d8d1eb.
* Merge branch 'master' into HEAD
* Changes how the check for formatting is done.
  Now the CI job uses the --check flag provided by cmake_format instead of
  the `git diff` check, because git caused some problems in this repo.
* format
* mrt_add_library now adds a compilation tests for all headers used by the library
* Add ZeroMQ
* Add zxing-cpp to cmake.yaml.
* hard coded ignore files which start with "mocs_compilation and delete the corresponding gcda file, because otherwise our current coverage pipeline fails.
* Contributors: Fabian Poggenhans, Jan-Hendrik Pauls, Johannes Beck, Kevin Rösch, Mrt Builder, Yinzhe Shen

1.0.9 (2021-11-26)
------------------
* Set python version
* Set PYTHON_EXECUTABLE for rolling
* Add find script and cmake.yml entry for proj.
* Update FLANN find script to work with newer versions.
* add boost iostreams component
* Removed debug message.
* Fix find boost python for cmake 3.20.
* add xerces and curl to camke.yaml
* Fix warnings in CUDA code.
* Remove cmake 3.20-only syntax
* Headers from dependencies are no longer marked as system, except from overlayed workspaces
* Set the ccache base dir as environment variable of the compiler command
* add pangolin
* Fix formatting of test failures on python3
* Fix recovering from sanitizer issues by making sure the flag is set only once
  resolves MRT/draft/simulation_adenauerring#34
* fix action build
* Use mrt_cgal again (brings a newer version than ubuntu)
* Adding or-tools to cmake.yaml.
* Sanitizers: enable recovering form nullptr issues even in no_recover mode
  this fixes otherwise unfixable issues e.g. in boost::serialization using this
* Update/remove old maintainer emails
* Improve evaluation of conditions in package.xml
  in order to make it more compliant with REP149
* Increase character limits for conditions specified package.xml
  This is necessary so that conditions that are based on ROS_DISTRO can be specified
* Add cmake entry for libnlopt-cpp-dev, new for focal
* Fix python script installation
  (shebang replacement)
* Add mrt_casadi to cmake.yaml
* Add mrt_hpipm to cmake.yaml
* Add mrt_blasfeo to cmake.yaml
* Add a small Readme pointing to cmake-format
* change name to match internal name
* add mrt-osqp-eigen
* add osqp
* Fix aravis find script.
* Switch to use aravis 0.8.
* Contributors: Fabian Poggenhans, Ilia Baltashov, Johannes Beck, Kevin Rösch, Maximilian Naumann, Piotr Orzechowski, Bernd Kröper, wep21

1.0.8 (2020-09-30)
------------------
* Fix finding boost python on versions with old cmake but new boost
* Contributors: Fabian Poggenhans

1.0.7 (2020-09-30)
------------------
* Fix versioning of sofiles
* Ensure unittests use the right gtest include dir
* Contributors: Fabian Poggenhans

1.0.6 (2020-09-30)
------------------
* Fix boost python building for python3
* Contributors: Fabian Poggenhans

1.0.5 (2020-09-29)
------------------
* Fix build for ROS2, gtest should no longer be installed in ROS2 mode
* Improve python nosetest info
* Update boost-python depend message
* Fix python module setup
* Packages can now have both a python module and a python api
* Add qtbase5-dev key
* Contributors: Fabian Poggenhans, Kevin Rösch, Maximilian Naumann

1.0.4 (2020-08-12)
------------------
* Deleted deprecated configuration files
* Fix cuda host compiler used for cuda 11
* Fix __init__.py template for python3
* Fix target handling for ros2
* Fix build failures on ROS1
* Fix the conan support
* Add a dependency on ros_environment to ensure ROS_VERSION is set
* Default to building shared libraries
* Add QtScript to the list of qt components
* Change license to BSD
* Remove traces of GPL-licensed libgps
* Remove unnecessary includes of cuda files
* Update tensorflow c findscript to set new tensorflow include paths
* Add cuda support for node and nodelet.
* Remove usage of ast package for evaulating package.xml conditions
* Fix crash if eval_coverage.py runs with python3
* Ensure that coverage is also generated for cpp code called from plain rostests
* Contributors: Fabian Poggenhans, Ilia Baltashov, Sven Richter

1.0.3 (2020-05-25)
------------------
* Replace deprecated platform.distro call with distro module
* Raise required CMake version to 3.0.2 to suppress warning with Noetic
* Remove boost signals component that is no longer part of boost
* Fixed c++14 test path include.
* Fix installation of python api files
* Update README.md
* Reformat with new version of cmake-format
* Add lcov as dependency again
* Fix FindBoostPython.cmake for cmake below 3.11 and python3
* Fix multiple include of MrtPCL
* Contributors: Christian-Eike Framing, Fabian Poggenhans, Johannes Beck, Johannes Janosovits, Moritz Cremer

1.0.2 (2020-03-24)
------------------
* Fix PCL findscript, disable precompiling
* added jsoncpp
* Make sure packages search for mrt_cmake_modules in their package config
* Fix resolution of packages in underlaying workspaces
* Mention rosdoc.yaml in package.xml
* Contributors: Fabian Poggenhans, Johannes Beck, Johannes Janosovits

1.0.1 (2020-03-11)
------------------
* Update maintainer
* Update generate_dependency_file to search CMAKE_PREFIX_PATH for packages instead of ROS_PACKAGE_PATH
* Update package xml to contain ROS urls and use format 3 to specify python version specific deps
* Add a rosdoc file so that ros can build the cmake api
* Contributors: Fabian Poggenhans

1.0.0 (2020-02-24)
------------------
* Initial release for ROS
* Contributors: Andre-Marcel Hellmund, Claudio Bandera, Fabian Poggenhans, Johannes Beck, Johannes Graeter, Niels Ole Salscheider, Piotr Orzechowski
