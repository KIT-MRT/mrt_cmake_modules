import os
import sys
import re

# Convenience names for types
from string import Template

str_t = "str"
bool_t = "bool"
int_t = "int"
double_t = "double"
types = [str_t, bool_t, int_t, double_t]


# TODO Add array type


class ParameterGenerator(object):
    """Automatic config file and header generator"""

    minval = {
        'int': -0x80000000,  # 'INT_MIN',
        'double': '-std::numeric_limits<double>::infinity()',
        'str': '',
        'bool': False,
    }

    maxval = {
        'int': 0x7FFFFFFF,  # 'INT_MAX',
        'double': 'std::numeric_limits<double>::infinity()',
        'str': '',
        'bool': True,
    }

    defval = {
        'int': 0,
        'double': 0,
        'str': '',
        'bool': False,
    }

    def __init__(self):
        """Constructor for ParamGenerator"""
        self.parameters = []

        if len(sys.argv) != 4:
            print("Unexpected ammount of args")
            sys.exit(1)
        self.dynconfpath = sys.argv[1]  # FIXME this is awful
        self.share_dir = sys.argv[2]
        self.cpp_gen_dir = sys.argv[3]

        self.pkgname = None
        self.nodename = None
        self.classname = None

        self.dynamic_params = []
        self.static_params = []

    def add(self, name, paramtype, description, default=None, min=None, max=None, configurable=False,
            global_scope=False):
        newparam = {
            'name': name,
            'type': paramtype,
            'default': default,
            'description': description,
            'min': min,
            'max': max,
            'configurable': configurable,
            'global_scope': global_scope,
            'required': default is None
        }

        if paramtype == "str" and (max and min):
            raise Exception("Max or min specified for %s, which is of string type" % name)
        pattern = r'^[a-zA-Z][a-zA-Z0-9_]*$'
        if not re.match(pattern, name):
            raise Exception(
                "The name of field \'%s\' does not follow the ROS naming conventions, see http://wiki.ros.org/ROS/Patterns/Conventions" % name)
        if global_scope and configurable:
            raise Exception("Global Parameters can not be declared configurable! Parameter: %s" % name)
        if global_scope and default:
            raise Exception("Default values for global parameters should not be specified in node! Parameter: %s" %
                            name)

        self.fill_type(newparam)
        self.check_type_fill_default(newparam, 'default', self.defval[paramtype])
        self.check_type_fill_default(newparam, 'max', self.maxval[paramtype])
        self.check_type_fill_default(newparam, 'min', self.minval[paramtype])

        self.parameters.append(newparam)

    @staticmethod
    def fill_type(param):
        param['ctype'] = {'str': 'std::string', 'int': 'int', 'double': 'double', 'bool': 'bool'}[param['type']]
        param['cconsttype'] = \
            {'str': 'const char * const', 'int': 'const int', 'double': 'const double', 'bool': 'const bool'}[
                param['type']]

    @staticmethod
    def pytype(drtype):
        return {'str': str, 'int': int, 'double': float, 'bool': bool}[drtype]

    def check_type_fill_default(self, param, field, default):
        value = param[field]
        # If no value, use default.
        if value is None:
            param[field] = default
            return
        # Check that value type is compatible with type.
        self.check_type(param, field)

    def check_type(self, param, field):
        drtype = param['type']
        pytype = self.pytype(drtype)
        name = param['name']
        value = param[field]
        if param['type'] not in types:
            raise TypeError("'%s' has type %s, but allowed are: %s" % (param['name'], param['type'], types))
        if pytype != type(value) and (pytype != float or type(value) != int):
            raise TypeError("'%s' has type %s, but %s is %s" % (name, drtype, field, repr(value)))

    @staticmethod
    def get_cdefault(param):
        value = param["default"]
        if param['type'] == str_t:
            value = '"{}"'.format(param["default"])
        elif param['type'] == bool_t:
            value = str(param["default"]).lower()
        return str(param['ctype']) + "{" + str(value) + "}"

    def generate(self, pkgname, nodename, classname):
        self.pkgname = pkgname
        self.nodename = nodename
        self.classname = classname

        self.dynamic_params = [p for p in self.parameters if p["configurable"]]
        self.static_params = [p for p in self.parameters if not p["configurable"]]

        self.generatecfg()
        self.generatecpp()

        return 0

    def generatecfg(self):
        templatefile = os.path.join(self.dynconfpath, "templates", "ConfigType.h.template")
        with open(templatefile, 'r') as f:
            template = f.read()

        param_entries = []
        for param in self.dynamic_params:
            param_entries.append(Template(
                "gen.add(name = '$name', paramtype = '$paramtype', level = $level, description = '$description', "
                "default = $default,min = $min, max = $max, edit_method = $editmethod)").substitute(
                name=param["name"],
                paramtype=param['type'],
                level=0,
                description=param['description'],
                default=param['default'],
                min=param['min'],
                max=param['max'],
                editmethod='""'))
        param_entries = "\n".join(param_entries)

        template = Template(template).substitute(pkgname=self.pkgname, nodename=self.nodename,
                                                 classname=self.classname, params=param_entries)

        cfg_file = os.path.join(self.share_dir, "cfg", self.classname + ".cfg")
        if not os.path.exists(os.path.dirname(cfg_file)):
            os.makedirs(os.path.dirname(cfg_file))
        with open(cfg_file, 'w') as f:
            f.write(template)
        os.chmod(cfg_file, 509)  # entspricht 775 (octal)

    def generatecpp(self):
        templatefile = os.path.join(self.dynconfpath, "templates", "Parameters.h.template")
        with open(templatefile, 'r') as f:
            template = f.read()

        param_entries = []
        from_server = []
        from_config = []
        for param in self.parameters:
            paramname = param['name']
            if param["global_scope"]:
                paramname = "/" + paramname
            else:
                paramname = "~" + paramname
            if param["required"]:
                default = ""
            else:
                default = ', {}'.format(self.get_cdefault(param))

            param_entries.append(Template('  ${type} ${name}; /*!< ${description} */').substitute(
                type=param['ctype'], name=param['name'], description=param['description']))
            from_server.append(Template('    getParam("$paramname", $name$default);').substitute(
                paramname=paramname, name=param['name'], default=default, description=param['description']))
            if param['configurable']:
                from_config.append(Template('    $name = config.$name;').substitute(name=param['name']))

        param_entries = "\n".join(param_entries)
        from_server = "\n".join(from_server)
        from_config = "\n".join(from_config)

        content = Template(template).substitute(pkgname=self.pkgname, ClassName=self.classname,
                                                parameters=param_entries, fromConfig=from_config,
                                                fromParamServer=from_server)

        header_file = os.path.join(self.cpp_gen_dir, self.classname + "Parameters.h")
        if not os.path.exists(os.path.dirname(header_file)):
            os.makedirs(os.path.dirname(header_file))
        with open(header_file, 'w') as f:
            f.write(content)
