"""

"""
import json
import os

# only for documentation. FOr compatibility with py2
import re

try:
    from typing import List
except:
    pass

# for standalone testing purposes
try:
    from Katana import (
        NodegraphAPI,
        PackageSuperToolAPI
    )
    from Katana.Plugins import GafferThreeAPI
except:
    pass


class BaseD2gtDict(dict):
    """
    A regular python dictionnary object used in d2gt.
    Additional methods and property are provided.

    Args:
        build_object(str or dict):
    """

    filecheck = "d2gt"

    def __init__(self, build_object):

        if isinstance(build_object, str):
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

        with open(filepath, "r", encoding="utf-8") as d2gtfile:
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
        return self.get("name")

    @property
    def rootLocation(self):
        return self.get("rootLocation")

    @property
    def syncSelection(self):
        return bool(self.get("syncSelection"))

    @property
    def children(self):
        """
        Returns a list of Package to create.

        Returns:
            dict of str:
        """
        return self.get("children")  # type: dict


class GafferChildrenDict(BaseD2gtDict):
    """
    Represent a PackageSuperToolAPI.Package as a dict for creation.
    Usually built from a GafferDict <children> key
    """
    filecheck = None

    def __init__(self, build_object, name):
        super(GafferChildrenDict, self).__init__(build_object)
        self.name = name

    @property
    def parent(self):
        return self.get("parent")

    @property
    def class_(self):
        return self.get("class")

    @property
    def params(self):
        return self.get("params")


class TokenDict(BaseD2gtDict):
    filecheck = "d2gt_token"



class D2gtGaffer(object):
    """
    A GafferThree node

    Args:
        gafferdict(GafferDict):

    Attributes:
        rigs(dict):
            exemple:
            {
                "/rigA": D2gtRigPackage,
                "/rigA/corridor": D2gtRigPackage,
                "/rigA/corridor/top": D2gtRigPackage,
                "/artistic/keys": D2gtRigPackage,
                "/artistic": D2gtRigPackage
            }
    """

    def __init__(self, gafferdict):

        self.gd = gafferdict
        self._node = None
        self._package_root = None
        self.packages = dict()

        return

    @property
    def node(self):
        """
        Returns:
            NodegraphAPI.Node: GafferThree node.
        """
        return self._node

    @node.setter
    def node(self, node_value):
        self._node = node_value
        self.pkg_root = node_value.getRootPackage()

    @property
    def package_root(self):
        """
        Returns:
            D2gtRigPackage: Rig package as custom python object
        """
        return self._package_root

    @package_root.setter
    def package_root(self, package_root_value):
        """
        Args:
            package_root_value(PackageSuperToolAPI.Packages.GroupPackage):
        """
        pkg = D2gtRigPackage(
            package=package_root_value,
            name=None,
            parent=None
        )
        self._package_root = pkg

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
        rig = self.packages.get(path)  # type: D2gtRigPackage
        if rig:
            return rig.package

        path = path[1::]  # remove the first "/"
        path_levels = len(path.split("/")) + 1  # we start counting at 1
        path_lvl = ""

        for i in range(1, path_levels):

            path_lvl = path.split("/", n-i)
            rig = self.rigs.get(path_lvl)
            if rig:
                continue

        return

    def create_rig_package(self, name, parent=None):
        """
        Args:
            name(str):
            parent(D2gtRigPackage):

        Returns:
            D2gtRigPackage:
        """

        parent = parent or self.package_root
        pkg = parent.package.createChildPackage("RigPackage", name)
        rig = D2gtRigPackage(
            package=pkg,
            name=name,
            parent=parent
        )
        self.rigs[str(rig)] = rig
        return rig

    def create_package(self, pkg_class, pkg_name, data):
        """
        Args:
            pkg_class(str): class of the package to create.
            pkg_name: scene graph name of the package
            data(GafferChildrenDict):
        """
        parent = self.get_package_at(data.parent)
        pkg = parent.createChildPackage(pkg_class, pkg_name)

        pkg.getMaterialNode()
        pkg.getShadowLinkingNode()
        pkg.getLinkingNodes()
        pkg.getLocationPath()
        return pkg

    def build(self, from_root=None):
        """

        Args:
            from_root(NodegraphAPI.GroupNode or None):
                the root node the gafferthree should be added in.

        Returns:
            NodegraphAPI.Node: created GafferThree node.
        """
        # create the node or replace it if it exists
        self.node = update_node(
            node_name=self.gd.name,
            node_type="GafferThree",
            root=from_root
        )
        self.pkg_root = self.node.getRootPackage()

        self.node.setRootLocation(self.gd.rootLocation)
        self.node.setSyncSelection(self.gd.syncSelection)

        for pkgname, pkgdata in self.gd.children.items():

            pkgdata = pkgdata  # type: GafferChildrenDict

            self.create_package(
                pkg_class=pkgdata.get("class"),
                pkg_name=pkgname,
                data=pkgdata
            )

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
    if isinstance(new, NodegraphAPI.GroupNode):
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

    new.setName(node_name)
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

        if isinstance(k, str):

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

        elif isinstance(v, str):

            for token in set(re.findall(regex, v)):
                v2 = tokendict.get(token[1::][:-1])
                if v2 is None:
                    raise ValueError(
                        "[dict_bake_tokens] Value <{}> for key <{}> not found"
                        " in token dict.".format(v, k)
                    )
                v2 = v.replace(token, v2)
                sourcedict[k] = v2

        continue

    return sourcedict


def package_get_param(package, param_path):
    """

    Args:
        package(PackageSuperToolAPI.Packages.Package):
        param_path(str):
            ex: getMaterialNode.params.arnoldSurfaceShader.exposure

    Returns:

    """
    param_root, param_name = param_path.split(".", 1)

    if param_root == "getCreateNode":
        node = package.getCreateNode()

    elif param_root == "getMaterialNode":
        node = package.getMaterialNode()

    elif param_root == "getShadowLinkingNode":
        node = package.getShadowLinkingNode()

    elif param_root == "getLinkingNodes":
        node = package.getLinkingNodes()

    elif param_root == "getOrientConstraintNode":
        node = package.getOrientConstraintNode()

    elif param_root == "getPointConstraintNode":
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

    return param


def run():

    token = "./tests/tokenDemo1.json"
    td = TokenDict(token)

    scene_list = [
        "./tests/demo1.json"
    ]

    for scene in scene_list:
        gd = GafferDict(scene, tokendict=td)
        print(json.dumps(gd, indent=4))
        # gaffer = D2gtGaffer(gafferdict=gd)
        # gaffer_node = gaffer.build()

    return

if __name__ == '__main__':

    run()