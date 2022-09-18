"""
version=4
author=Liam Collod
last_modified=11/04/2022
python=>2.7.1
"""
import json
import logging
import os
import re
import sys


# only for documentation. (keep compatibility with py2)
try:
    from typing import List, Type, Optional
except ImportError:
    pass

# try for standalone testing purposes
try:
    from Katana import (
        NodegraphAPI,
        PackageSuperToolAPI
    )
    from Katana.Plugins import GafferThreeAPI
except ImportError:
    pass

__all__ = [
    "GafferDict",
    "GafferChildrenDict",
    "TokenDict",
    "D2gtGaffer"
]

__PY3 = sys.version_info[0] == 3
if __PY3:
    basestring = str


def setup_logging(level):

    logger = logging.getLogger("d2gt")
    logger.setLevel(level)

    if not logger.handlers:

        # create a file handler
        handler = logging.StreamHandler(stream=sys.stdout)
        handler.setLevel(logging.DEBUG)
        # create a logging format
        formatter = logging.Formatter(
            '%(asctime)s - [%(levelname)7s] %(name)38s // %(message)s',
            datefmt='%H:%M:%S'
        )
        handler.setFormatter(formatter)
        # add the file handler to the logger
        logger.addHandler(handler)

    return logger


logger = setup_logging(logging.DEBUG)


class BaseD2gtDict(dict):
    """
    A regular python dictionnary object used in d2gt.
    Additional methods and property are provided.

    Args:
        build_object(str or dict):
    """

    filecheck = "d2gt"

    def __init__(self, build_object):

        if isinstance(build_object, basestring):
            self.build_from_file(build_object)
        else:
            super(BaseD2gtDict, self).__init__(build_object)
            self.__validate()

        return

    def __validate(self):
        """
        Check the data holded looks valid.
        If not raise an error.
        """

        v = self.get("__type")
        if not v == self.filecheck:
            raise TypeError(
                "The current dictionnary doesn't seems to be a proper d2gt "
                "asset: self['__type']={} != {}".format(v, self.filecheck)
            )

        return

    def build_from_file(self, filepath):
        """

        Args:
            filepath(str): path to a .json file.
        """

        if not os.path.exists(filepath):
            raise FileNotFoundError(
                "[build_from_file] Given filepath <{}> doesn't exists."
                "".format(filepath)
            )

        with open(filepath, "r") as d2gtfile:
            c = json.load(d2gtfile)

        super(BaseD2gtDict, self).__init__(c)
        self.__validate()
        return


class GafferDict(BaseD2gtDict):
    """
    Args:
        build_object(str or dict):
        tokendict(TokenDict):
    """
    filecheck = "d2gt_gaffer"

    def __init__(self, build_object, tokendict):
        super(GafferDict, self).__init__(build_object)
        self._build(tokendict)

    def _build(self, tokendict):

        children = self.get("children")
        for childname, childdata in children.items():

            child = dict_bake_tokens(
                sourcedict=childdata,
                tokendict=tokendict
            )
            child = GafferChildrenDict(build_object=child, name=childname)
            children[childname] = child

        return

    @property
    def name(self):
        return str(self.get("name"))

    @property
    def rootLocation(self):
        return str(self.get("rootLocation", "/root/world/lgt/gaffer"))

    @property
    def syncSelection(self):
        return bool(self.get("syncSelection", 1))

    @property
    def children(self):
        """
        Returns a list of Package to create.

        Returns:
            Dict[str, Type[GafferChildrenDict]]:
                Dict[str, Type[GafferChildrenDict]]
        """
        return self.get("children")


class GafferChildrenDict(BaseD2gtDict):
    """
    Represent a PackageSuperToolAPI.Package as a dict for creation.
    Usually built from a GafferDict <children> key
    """
    filecheck = None

    def __init__(self, build_object, name):
        super(GafferChildrenDict, self).__init__(build_object)
        self.name = str(name)
        self._parent = None  # type: Optional[GafferChildrenDict]
        self.children = list()  # type: List[GafferChildrenDict]

    def copy(self):
        """
        Returns:
            GafferChildrenDict:
        """
        v = super(GafferChildrenDict, self).copy()
        v = GafferChildrenDict(v, self.name)
        if self.parent:
            v.parent = self.parent
        v.children = list(self.children)
        return v

    @property
    def parent(self):
        """
        Returns:
            GafferChildrenDict or None:
        """
        return self._parent

    @parent.setter
    def parent(self, parent_value):
        """
        Args:
            parent_value(GafferChildrenDict):
        """
        self._parent = parent_value
        parent_value.children.append(self)
        self["parent"] = parent_value.path

    @property
    def location(self):
        """
        CEL like path relative to the GafferThree CEL indicating where
        self should be located.

        Returns:
            str:
        """
        return str(self.get("parent", ""))

    @property
    def path(self):
        """
        CEL like path relative to the GafferThree CEL indicating the path
        to self. (so location + name)

        Returns:
            str:
        """
        return self.location + "/" + self.name

    @property
    def direct_parent(self):
        """
        Return the first direct parent speicifed in the path.

        Returns:
            str:
        """
        return self.location.split("/")[-1] or ""

    @property
    def class_(self):
        """
        The Package class to create.

        Returns:
            str:
        """
        return str(self["class"])

    @property
    def params(self):
        """
        The params key that hold a pair of param_path:param_value

        Returns:
            dict:
        """
        return self.get("params", {})


class TokenDict(BaseD2gtDict):
    filecheck = "d2gt_token"


DefaultRigPkg = GafferChildrenDict(
    {"class": "RigPackage"},
    name="rig"
)


class D2gtGaffer(object):
    """
    A GafferThree node

    Args:
        gafferdict(GafferDict):

    Attributes:
        gd(GafferDict): gaffer to create as a dict object
        packages(dict):
            exemple:
            {
                "/rigA": PackageSuperToolAPI.Packages.GroupPackage,
                "/rigA/corridor": ...,
                "/rigA/corridor/top": ...,
                "/artistic/keys": ...,
                "/artistic": ...
            }
        node(NodegraphAPI.Node): GafferThree node created
    """

    def __init__(self, gafferdict):

        self.gd = gafferdict
        self.node = None  # type: NodegraphAPI.Node
        self.packages = dict()

        return

    def get_package_at(self, path):
        """

        Args:
            path(str):

        Returns:
            PackageSuperToolAPI.Packages.GroupPackage
        """
        if path == "" or path == "/":
            return self.node.getRootPackage()  # type: PackageSuperToolAPI.Packages.RootPackage

        # check first if the path is not already created
        pkg = self.packages.get(path)  # type: PackageSuperToolAPI.Packages.GroupPackage
        if pkg:
            return pkg

        path = path[1::]  # remove the first "/"
        path_lvl = ""
        # get a list of all levels
        path_levels = path.split("/")
        # ! loop start counting at 1
        for i in range(1, len(path_levels) + 1):
            # rebuild the current level from the previous one
            path_lvl = path_lvl + "/" + path_levels[i-1]  # type: str
            pkg = self.packages.get(path_lvl)  # type: PackageSuperToolAPI.Packages.GroupPackage
            if pkg:
                continue
            # else create the package
            gcd = DefaultRigPkg.copy()
            gcd.name = path_levels[i-1]
            gcd["parent"] = path_lvl.rsplit("/", 1)[0]
            pkg = self.create_package(data=gcd, parent=pkg)

        return pkg

    def create_package(self, data, parent=None):
        """
        Create the GafferThree package with the given class and name and
        configured with the data provided. Data include parent

        Args:
            parent(PackageSuperToolAPI.Packages.GroupPackage):
            data(GafferChildrenDict):
        """
        parent = parent or self.get_package_at(data.location)
        pkg_name = data.name
        pkg_class = data.class_
        pkg = parent.createChildPackage(pkg_class, pkg_name)
        self.packages[data.path] = pkg

        for parampath, paramvalue in data.params.items():
            param = package_set_param(
                package=pkg,
                param_path=parampath,
                param_value=paramvalue
            )
            continue

        logger.debug(
            "[D2gtGaffer][create_package] Finished for package <{}>({})"
            "".format(pkg_name, pkg_class)
        )
        return pkg

    def build(self, from_root=None):
        """

        Args:
            from_root(NodegraphAPI.GroupNode or None):
                the root node the gafferthree should be added in.

        Returns:
            NodegraphAPI.Node: created GafferThree node.
        """
        logger.debug(
            "[D2gtGaffer][build] Started with root={}".format(from_root)
        )

        # create the node or replace it if it exists
        self.node = update_node(
            node_name=self.gd.name,
            node_type="GafferThree",
            root=from_root
        )
        self.pkg_root = self.node.getRootPackage()

        self.node.setRootLocation(str(self.gd.rootLocation))
        self.node.setSyncSelection(self.gd.syncSelection)

        # we iter a first time through all packages to assign their parent
        pkg2create_dict = self.gd.children
        pkg2create_list = list(pkg2create_dict.values())  # type: List[GafferChildrenDict]
        for pkg2create in pkg2create_list:
            pkg = pkg2create_dict.get(pkg2create.direct_parent)  # type: GafferChildrenDict
            if pkg:
                pkg2create.parent = pkg

        # reorder the list where firstindex = first package to create
        pkg2create_prio = list()
        pkg2create_low = list()
        for pkg in pkg2create_list:
            if pkg.children:
                if pkg2create_prio and pkg2create_prio[-1].name == pkg.direct_parent:
                    pkg2create_prio.append(pkg)
                else:
                    pkg2create_prio.insert(0, pkg)
            else:
                pkg2create_low.append(pkg)

        pkg2create_list = pkg2create_prio
        pkg2create_list.extend(pkg2create_low)

        logger.debug(
            "[D2gtGaffer][build] Packages to create are:\n    {}"
            "".format(list(map(lambda p: p.path, pkg2create_list)))
        )

        # create the packages
        for pkgdata in pkg2create_list:
            self.create_package(data=pkgdata)
            continue

        return self.node


def update_node(node_name, node_type, root=None):
    """
    ! Node is assumed to have only one input and one output port with a maximum
    of one connection for each.

    Returns:
        NodegraphAPI.Node: newly created node
    """
    new = NodegraphAPI.CreateNode(node_type, root or NodegraphAPI.GetRootNode())
    if new.getType() == "Group":
        new_in = new.addInputPort("in")
        new_out = new.addOutputPort("out")
    else:
        new_in = new.getInputPortByIndex(0)
        new_out = new.getOutputPortByIndex(0)

    existingn = NodegraphAPI.GetNode(node_name)
    if existingn:

        # we assume there is only 1 input/output port with only one connection
        in_port = existingn.getInputPorts()[0]
        in_port = in_port.getConnectedPort(0)
        out_port = existingn.getOutputPorts()[0]
        out_port = out_port.getConnectedPort(0)
        pos = NodegraphAPI.GetNodePosition(existingn)  # type: tuple

        existingn.delete()

        NodegraphAPI.SetNodePosition(new, pos)
        if in_port:
            in_port.connect(new_in)
        if out_port:
            out_port.connect(new_out)

        logger.info("[update_node] Found existing node, it has been updated.")

    new.setName(node_name)
    logger.info("[update_node] Finished for node <{}>".format(node_name))
    return new


def dict_bake_tokens(sourcedict, tokendict):
    """
    Find tokens in keys and values of <sourcedict> and replace them by their
    corresponding value stored in <tokendict>.

    Args:
        sourcedict(dict):
        tokendict(TokenDict):

    Returns:
        dict: sourcedict with the token baked
    """
    regex = r"<[a-zA-Z0-9_]+>"

    for k, v in list(sourcedict.items()):

        if isinstance(k, basestring):

            for token in set(re.findall(regex, k)):
                if sourcedict.get(k) is not None: del sourcedict[k]
                # remove the "<>" with [1::][:-1]
                k2 = tokendict.get(token[1::][:-1])
                if k2 is None:
                    raise ValueError(
                        "[dict_bake_tokens] Key <{}> not found in token dict."
                        "".format(k)
                    )
                k2 = k.replace(token, k2)
                sourcedict[k2] = v

        if isinstance(v, dict):

            sourcedict[k] = dict_bake_tokens(v, tokendict)

        elif isinstance(v, basestring):

            for token in set(re.findall(regex, v)):
                v2 = tokendict.get(token[1::][:-1])
                if v2 is None:
                    raise ValueError(
                        "[dict_bake_tokens] token <{}> for key <{}> not found"
                        " in token dict.".format(token, k)
                    )
                v2 = v.replace(token, str(v2))
                sourcedict[k] = v2

        continue

    return sourcedict


def package_set_param(package, param_path, param_value):
    """

    Args:
        param_value(any): value to set on the parameter found.
        package(PackageSuperToolAPI.Packages.Package):
        param_path(str):
            ex: material.shaders.arnoldLightParams.exposure.value

    Raises:
        RuntimeError: if param_path is invalid somehow.

    Returns:
        NodegraphAPI.Parameter: parameter found and modified
    """
    param_root, param_name = param_path.split(".", 1)
    # safe format param_root
    param_root = param_root.lower()

    if param_root == "create":
        node = package.getCreateNode()

    elif param_root == "material":
        node = package.getMaterialNode()
        node.checkDynamicParameters()

    elif param_root == "shadowlinking":
        node = package.getShadowLinkingNode()

    elif param_root == "linking":
        node = package.getLinkingNodes()

    elif param_root == "orientconstraint":
        node = package.getOrientConstraintNode()

    elif param_root == "pointconstraint":
        node = package.getPointConstraintNode()

    else:
        raise RuntimeError(
            "The parameter <{}> root <{}> is not supported."
            "".format(param_name, param_root)
        )

    if node is None:
        raise RuntimeError(
            "The parameter_path <{}> for package <{}> doesn't return a node."
            "".format(param_path, package)
        )

    param = node.getParameter(param_name)
    if param is None:
        raise RuntimeError(
            "The parameter <{}> for package <{}> doesn't exists on node <{}>."
            "".format(param_name, package, node)
        )

    try:
        param.setValue(param_value, 0)
    except TypeError as excp:
        if "needs a string" in excp.args[0]:
            param.setValue(str(param_value), 0)

    try:
        node.checkDynamicParameters()
    except AttributeError:
        pass

    return param


def __test01():

    token = {
        "__type": "d2gt_token",
        "lg_hdri_dome": "ArnoldHDRISkydomeLightPackage",
        "lg_hdri_quad": "ArnoldQuadLightPackage",
        "exposure": "shaders.arnoldLightParams.exposure",
        "filepath": "shaders.arnoldSurfaceParams.filename",
        "color": "shaders.arnoldLightParams.color"
    }
    td = TokenDict(token)

    scene = {
        "__type": "d2gt_gaffer",
        "name": "GafferThree_studio",
        "rootLocation": "/root/world/lgt/gaffer",
        "syncSelection": 1,
        "children": {
            "lg_hdri": {
                "parent": "/rig",
                "class": "<lg_hdri_dome>",
                "params": {
                    "material.<filepath>.value": "C:/test.tx",
                    "material.<filepath>.enable": 1,
                    "material.<exposure>.value": 1,
                    "material.<exposure>.enable": 1
                }
            },
            "lg_quad": {
                "parent": "",
                "class": "<lg_hdri_quad>",
                "params": {
                    "material.<exposure>.value": 15,
                    "material.<exposure>.enable": 1,
                    "material.<color>.value.i0": 0.9,
                    "material.<color>.value.i1": 0.3,
                    "material.<color>.value.i2": 0.1,
                    "material.<color>.enable": 1,
                }
            },

        }
    }
    gd = GafferDict(scene, tokendict=td)
    print(json.dumps(gd, indent=4))
    gaffer = D2gtGaffer(gafferdict=gd)
    gaffer_node = gaffer.build()

    print("[__test01] Finished")
    return


if __name__ == '__main__' or __name__ == "__builtin__":

    __test01()