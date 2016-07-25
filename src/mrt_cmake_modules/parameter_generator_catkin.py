import os
import sys
import re

# Convenience names for types
from string import Template

# TODO add enums for dynamic reconfigure

class ParameterGenerator(object):
    """Automatic config file and header generator"""

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
            'is_vector': False,
            'is_map': False,
            'configurable': configurable,
            'global_scope': global_scope,
            'required': default is None
        }
        self.perform_checks(newparam)
        self.parameters.append(newparam)

    def perform_checks(self, param):

        if param['type'].strip() == "std::string" and (param['max'] and param['min']):
            raise Exception("Max or min specified for %s, which is of string type" % param['name'])
        if (param['is_vector'] or param['is_map']) and (param['max'] or param['min'] or param['default']):
            raise Exception("Max, min and default can not be specified for %s, which is of type %s" % (param['name'], param['type']))
        pattern = r'^[a-zA-Z][a-zA-Z0-9_]*$'
        if not re.match(pattern, param['name']):
            raise Exception("The name of field \'%s\' does not follow the ROS naming conventions, "
                            "see http://wiki.ros.org/ROS/Patterns/Conventions" % param['name'])
        if param['configurable'] and (param['global_scope'] or param['is_vector'] or param['is_map']):
            raise Exception("Global Parameters, vectors and maps can not be declared configurable! "
                            "Error when setting up parameter : %s" % param['name'])
        if param['global_scope'] and param['default']:
            raise Exception("Default values for global parameters should not be specified in node! "
                            "Error when setting up parameter : %s" % param['name'])
        if param['name'] in [param['name'] for param in self.parameters]:
            raise Exception("Parameter with the same name exists already: %s" % param['name'])

        # Check type
        in_type = param['type'].strip()
        if in_type.startswith('std::vector'):
            param['is_vector'] = True
            ptype = in_type[12:-1].strip()
            self.test_primitive_type(param['name'], ptype)
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
            self.test_primitive_type(param['name'], ptype[0])
            self.test_primitive_type(param['name'], ptype[1])
            param['type'] = 'std::map<{},{}>'.format(ptype[0], ptype[1])
        else:
            self.test_primitive_type(param['name'], in_type)
            # Pytype and defaults can only be applied to primitives
            param['pytype'] = self.pytype(in_type)

    @staticmethod
    def pytype(drtype):
        return {'std::string': str, 'int': int, 'double': float, 'bool': bool}[drtype]


    @staticmethod
    def test_primitive_type(name, drtype):
        primitive_types = ['std::string', 'int', 'bool', 'float', 'double']
        if drtype not in primitive_types:
            raise TypeError("'%s' has type %s, but allowed are: %s" % (name, drtype, primitive_types))

    @staticmethod
    def get_cdefault(param):
        value = param["default"]
        if param['type'] == 'std::string':
            value = '"{}"'.format(param["default"])
        elif param['type'] == 'bool':
            value = str(param["default"]).lower()
        return str(param['type']) + "{" + str(value) + "}"

    def generate(self, pkgname, nodename, classname):
        self.pkgname = pkgname
        self.nodename = nodename
        self.classname = classname

        self.dynamic_params = [p for p in self.parameters if p["configurable"]]

        self.generatecfg()
        self.generatecpp()

        return 0

    def generatecfg(self):
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
            if param['default']:
                content_line += Template(", default=$default").substitute(default=param['default'])
            if param['min']:
                content_line += Template(", min=$min").substitute(min=param['min'])
            if param['max']:
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
                type=param['type'], name=param['name'], description=param['description']))
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
