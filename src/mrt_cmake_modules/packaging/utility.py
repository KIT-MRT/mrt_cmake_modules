import platform
import os
import subprocess


def get_os_distro():
    os_distro = platform.dist()[2]
    if 'ROS_OS_OVERRIDE' in os.environ:
        ros_os_override = os.environ['ROS_OS_OVERRIDE'].split(':')
        if len(ros_os_override) == 2:
            os_distro = ros_os_override[1]

    return os_distro


def get_ros_distro():
    if 'ROS_DISTRO' not in os.environ:
        raise RuntimeError(
            "Unknown ROS distro. The ROS_DISTRO environment variable needs to be set.")

    ros_distro = os.environ['ROS_DISTRO']
    return ros_distro


def get_apt_package_name(name):
    return "mrt-ros-{}".format(name.replace('_', '-'))


def get_workspace_build_root(workspace=None):
    cmd = ['catkin', 'locate', '--build']
    if workspace:
        cmd += ['--workspace', workspace]
    return subprocess.check_output(cmd).strip("\n")


def get_workspace_packages(workspace=None):
    cmd = ['catkin', 'list', '--unformatted']
    if workspace:
        cmd += ['--workspace', workspace]
    return subprocess.check_output(cmd).strip("\n").split("\n")
