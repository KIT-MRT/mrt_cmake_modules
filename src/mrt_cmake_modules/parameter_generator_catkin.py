import os
import sys
import re

# Convenience names for types
from string import Template


# TODO add enums for dynamic reconfigure
# TODO add const
# TODO add group

class ParameterGenerator(object):
    """Automatic config file and header generator"""

    def __init__(self):
        """Constructor for ParamGenerator"""
        self.parameters = []

        if len(sys.argv) != 4:
            print("Unexpected amount of args")
            sys.exit(1)
        self.dynconfpath = sys.argv[1]
        self.share_dir = sys.argv[2]
        self.cpp_gen_dir = sys.argv[3]

        self.pkgname = None
        self.nodename = None
        self.classname = None

        self.dynamic_params = []
        self.static_params = []
        self.const_params = []

    ''' This is still work in progress
    def const(self, name, paramtype, value, description):
        """Add a constant to the dynamic reconfigure file"""
        newconst = {
            'name': name,
            'type': paramtype,
            'value': value,
            'const': True,
            'description': description
        }
        self.fill_type(newconst)
        self.check_type(newconst, 'value')
        self.const_params.append(newconst)
        return newconst  # So that we can assign the value easily.

    def enum(self, constants, description):
        """Add an enum to dynamic reconfigure file"""
        if len(set(const['type'] for const in constants)) != 1:
            raise Exception("Inconsistent types in enum!")
        return repr({'enum': constants, 'enum_description': description})
    '''

    def add(self, name, paramtype, description, default=None, min=None, max=None, configurable=False,
            global_scope=False, constant=False):
        """
        Add parameters to your parameter struct. Call this method from your mrtcfg file!

        - If no default value is given, you need to specify one in your launch file
        - Global parameters, vectors, maps and constant params can not be configurable
        - Global parameters, vectors and maps can not have a default, min or max value

        :param self:
        :param name: The Name of you new parameter
        :param paramtype: The C++ type of this parameter. Can be any of ['std::string', 'int', 'bool', 'float',
        'double'] or std::vector<...> or std::map<std::string, ...>
        :param description: Choose an informative documentation string for this parameter.
        :param default: (optional) default value
        :param min: (optional)
        :param max: (optional)
        :param configurable: Should this parameter be dynamic configurable
        :param global_scope: If true, parameter is searched in global ('/') namespace instead of private ('~') ns
        :param constant: If this is true, the parameter will not be fetched from param server, but the default value
        is kept.
        :return: None
        """
        newparam = {
            'name': name,
            'type': paramtype,
            'default': default,
            'description': description,
            'min': min,
            'max': max,
            'is_vector': False,
            'is_map': False,
            'configurable': configurable,
            'constant': constant,
            'global_scope': global_scope,
        }
        self._perform_checks(newparam)
        self.parameters.append(newparam)

    def _perform_checks(self, param):
        """
        Will test some logical constraints as well as correct types.
        Throws Exception in case of error.
        :param self:
        :param param: Dictionary of one param
        :return:
        """

        if param['type'].strip() == "std::string" and (param['max'] is not None or param['min'] is not None):
            raise Exception("Max or min specified for %s, which is of string type" % param['name'])
        if (param['is_vector'] or param['is_map']) and (param['max'] or param['min'] or param['default']):
            raise Exception("Max, min and default can not be specified for %s, which is of type %s" % (
                param['name'], param['type']))
        pattern = r'^[a-zA-Z][a-zA-Z0-9_]*$'
        if not re.match(pattern, param['name']):
            raise Exception("The name of field \'%s\' does not follow the ROS naming conventions, "
                            "see http://wiki.ros.org/ROS/Patterns/Conventions" % param['name'])
        if param['configurable'] and (
                    param['global_scope'] or param['is_vector'] or param['is_map'] or param['constant']):
            raise Exception("Global Parameters, vectors, maps and constant params can not be declared configurable! "
                            "Error when setting up parameter : %s" % param['name'])
        if param['global_scope'] and param['default'] is not None:
            raise Exception("Default values for global parameters should not be specified in node! "
                            "Error when setting up parameter : %s" % param['name'])
        if param['constant'] and param['default'] is None:
            raise Exception("Constant parameters need a default value!"
                            "Error when setting up parameter : %s" % param['name'])
        if param['name'] in [p['name'] for p in self.parameters]:
            raise Exception("Parameter with the same name exists already: %s" % param['name'])

        # Check type
        in_type = param['type'].strip()
        if in_type.startswith('std::vector'):
            param['is_vector'] = True
            ptype = in_type[12:-1].strip()
            self._test_primitive_type(param['name'], ptype)
            param['type'] = 'std::vector<{}>'.format(ptype)
        elif in_type.startswith('std::map'):
            param['is_map'] = True
            ptype = in_type[9:-1].split(',')
            if len(ptype) != 2:
                raise Exception("Wrong syntax used for setting up std::map<... , ...>: You provided '%s' with "
                                "parameter %s" % (in_type, param['name']))
            ptype[0] = ptype[0].strip()
            ptype[1] = ptype[1].strip()
            if ptype[0] != "std::string":
                raise Exception("Can not setup map with %s as key type. Only std::map<std::string, ...> are allowed: %s"
                                % (ptype[0], param['name']))
            self._test_primitive_type(param['name'], ptype[0])
            self._test_primitive_type(param['name'], ptype[1])
            param['type'] = 'std::map<{},{}>'.format(ptype[0], ptype[1])
        else:
            self._test_primitive_type(param['name'], in_type)

    @staticmethod
    def _test_primitive_type(name, drtype):
        """
        Test whether parameter has one of the accepted C++ types
        :param name: Parametername
        :param drtype: Typestring
        :return:
        """
        primitive_types = ['std::string', 'int', 'bool', 'float', 'double']
        if drtype not in primitive_types:
            raise TypeError("'%s' has type %s, but allowed are: %s" % (name, drtype, primitive_types))

    @staticmethod
    def _get_cdefault(param):
        """
        Helper function to convert strings and booleans to correct C++ syntax
        :param param:
        :return: C++ compatible representation
        """
        value = param["default"]
        if param['type'] == 'std::string':
            value = '"{}"'.format(param["default"])
        elif param['type'] == 'bool':
            value = str(param["default"]).lower()
        return str(value)

    def generate(self, pkgname, nodename, classname):
        """
        Main working Function, call this at the end of your mrtcfg file!
        :param self:
        :param pkgname: Name of the catkin package
        :param nodename: Name of the Node that will hold these params
        :param classname: This should match your file name, so that cmake will detect changes in config file.
        :return: Exit Code
        """
        self.pkgname = pkgname
        self.nodename = nodename
        self.classname = classname

        self.dynamic_params = [p for p in self.parameters if p["configurable"]]

        self._generatecfg()
        self._generatecpp()

        return 0

    def _generatecfg(self):
        """
        Generate .cfg file for dynamic reconfigure
        :param self:
        :return:
        """
        templatefile = os.path.join(self.dynconfpath, "templates", "ConfigType.h.template")
        with open(templatefile, 'r') as f:
            template = f.read()

        param_entries = []
        for param in self.dynamic_params:
            content_line = Template("gen.add(name = '$name', paramtype = '$paramtype', level = $level, description = "
                                    "'$description'").substitute(name=param["name"],
                                                                 paramtype=param['type'],
                                                                 level=0,
                                                                 description=param['description'])
            if param['default'] is not None:
                content_line += Template(", default=$default").substitute(default=param['default'])
            if param['min'] is not None:
                content_line += Template(", min=$min").substitute(min=param['min'])
            if param['max'] is not None:
                content_line += Template(", max=$max").substitute(max=param['max'])
            content_line += ")"
            param_entries.append(content_line)

        param_entries = "\n".join(param_entries)

        template = Template(template).substitute(pkgname=self.pkgname, nodename=self.nodename,
                                                 classname=self.classname, params=param_entries)

        cfg_file = os.path.join(self.share_dir, "cfg", self.classname + ".cfg")
        if not os.path.exists(os.path.dirname(cfg_file)):
            os.makedirs(os.path.dirname(cfg_file))
        with open(cfg_file, 'w') as f:
            f.write(template)
        os.chmod(cfg_file, 509)  # entspricht 775 (octal)

    def _generatecpp(self):
        """
        Generate C++ Header file, holding the parameter struct.
        :param self:
        :return:
        """

        # Read in template file
        templatefile = os.path.join(self.dynconfpath, "templates", "Parameters.h.template")
        with open(templatefile, 'r') as f:
            template = f.read()

        param_entries = []
        debug_output = []
        from_server = []
        non_default_params = []
        from_config = []
        test_limits = []

        # Create dynamic parts of the header file for every parameter
        for param in self.parameters:
            paramname = param['name']

            # Adjust key for parameter server
            if param["global_scope"]:
                paramname = "/" + paramname
            else:
                paramname = "~" + paramname

            # Test for default value
            if param["default"] is None:
                default = ""
                non_default_params.append(Template('      << ros::names::resolve("$paramname") << " ($type) '
                                                   '\\n"\n').substitute(paramname=paramname, type=param["type"]))
            else:
                default = ', {}'.format(str(param['type']) + "{" + self._get_cdefault(param) + "}")

            # Test for constant value
            if param['constant']:
                param_entries.append(Template('  static constexpr auto ${name} = $default; /*!< ${description} '
                                              '*/').substitute(type=param['type'], name=param['name'],
                                                               description=param['description'],
                                                               default=self._get_cdefault(param)))
                from_server.append(Template('    testConstParam("$paramname");').substitute(paramname=paramname))
            else:
                param_entries.append(Template('  ${type} ${name}; /*!< ${description} */').substitute(
                    type=param['type'], name=param['name'], description=param['description']))
                from_server.append(Template('    getParam("$paramname", $name$default);').substitute(
                    paramname=paramname, name=param['name'], default=default, description=param['description']))

            # Test for configurable params
            if param['configurable']:
                from_config.append(Template('    $name = config.$name;').substitute(name=param['name']))

            # Test limits
            if param['min'] is not None:
                test_limits.append(Template('    testMin<$type>("$paramname", $name, $min);').substitute(
                    paramname=paramname, name=param['name'], min=param['min'], type=param['type']))
            if param['max'] is not None:
                test_limits.append(Template('    testMax<$type>("$paramname", $name, $max);').substitute(
                    paramname=paramname, name=param['name'], max=param['max'], type=param['type']))

            # Add debug output
            debug_output.append(Template('      << ros::names::resolve("$paramname") << ": " << $param << '
                                         '"\\n"\n').substitute(paramname=paramname, param=param["name"]))

        param_entries = "\n".join(param_entries)
        debug_output = "".join(debug_output)
        non_default_params = "".join(non_default_params)
        from_server = "\n".join(from_server)
        from_config = "\n".join(from_config)
        test_limits = "\n".join(test_limits)

        content = Template(template).substitute(pkgname=self.pkgname, ClassName=self.classname,
                                                parameters=param_entries, fromConfig=from_config,
                                                fromParamServer=from_server, debug_output=debug_output,
                                                non_default_params=non_default_params, nodename=self.nodename,
                                                test_limits=test_limits)

        header_file = os.path.join(self.cpp_gen_dir, self.classname + "Parameters.h")
        if not os.path.exists(os.path.dirname(header_file)):
            os.makedirs(os.path.dirname(header_file))
        with open(header_file, 'w') as f:
            f.write(content)

