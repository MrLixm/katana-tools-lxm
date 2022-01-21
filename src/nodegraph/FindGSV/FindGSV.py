"""
VERSION = 0.0.5

Author: Liam Collod
Last modified: 21/01/2022

Script for Foundry's Katana software. (Python 2+)
Easily find all local GSV in your Katana scene and their setup.

[HowTo]
TODO
"""
import json
from collections import OrderedDict
import sys
import logging
# Python 2 ...
try:
    from typing import (
        Optional,
        List
    )
except ImportError:
    pass

import NodegraphAPI


"""____________________________________________________________________________

    SETUP

"""


def setup_logging(level):

    logger = logging.getLogger("FindGSV")
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


logger = setup_logging(logging.INFO)


""" config_dict(dict)
Configure how the script behave

[lvl0]
[key=exclude:value](list):
    variable names that will be removed from result
[key=nodes:value](dict):
    List the node that make use of local GSVs.

[lvl1]
[key=nodes:value.key](str):  
    katana node type 
[key=nodes:value.key:value](dict):  
    parameters path on node that help build the GSV
    
[lvl2]
[key=nodes:value.key:value.key=name:value](str):  
    parameters path on node to get the variable name
[key=nodes:value.key:value.key=values:value](str):  
    parameters path on node to get the values the variable can take
 
"""

CONFIG =

TIME = NodegraphAPI.GetCurrentTime()


"""____________________________________________________________________________

    API

"""


class GSVNode(object):
    """
    A Katana node that use the GSV feature.

    Args:
        node(NodegraphAPI.Node):
    """

    sources = CONFIG.get("nodes", dict())

    def __init__(self, node):

        self.kobj = node
        self.type = node.getType()

        self.gsv_name = self.get_parameter(
            param_path=self.sources[self.type]["name"]
        )[0]

        self.gsv_values = self.get_parameter(
            param_path=self.sources[self.type]["values"]
        )

        logger.debug(
            "[GSVNode][__init__] Finished for node <{}>."
            "gsv_name={},gsv_values={}"
            "".format(node, self.gsv_name, self.gsv_values)
        )

        return

    def __str__(self):
        return "{}({})".format(self.kobj.getName(), self.type)

    def get_parameter(self, param_path):
        """

        Args:
            param_path(str): parameter path on node

        Returns:
            list: list of values holded by this parameter.

        Notes:
            TODO support case where given param has multiple nested param
        """

        param = self.kobj.getParameter(param_path)
        if not param:
            raise ValueError(
                "Parameter <{}> not found on node <{}>"
                "".format(param_path, self.kobj)
            )

        output = list()

        if param.getNumChildren() != 0:
            for index in range(0, param.getNumChildren()):
                output.append(param.getChildByIndex(index).getValue(TIME))
        else:
            output = [param.getValue(TIME)]

        return output


class GSVLocal(object):
    """
    Represent a GSV as a python object. Allow to know which node is using this
    gsv and what value it can take.

    Args:
        name(str): gsv name used in the nodegraph
        scene(GSVScene): parent scene
    """

    instances = list()
    excluded = CONFIG.get("excluded", list())

    def __new__(cls, *args, **kwargs):

        name = kwargs.get("name") or args[0]  # type: str
        scene = kwargs.get("scene") or args[1]  # type: GSVScene

        # If the variable name is specified as excluded return None
        if name in cls.excluded:
            return None

        # try to find if an instance of this class with the same name and same
        # parented scene already exists.
        # If yes, return it instead of creating a new one.
        for instance in cls.instances:
            if instance.name == name and instance.scene == scene:
                return instance  # type: GSVLocal

        new_instance = super(GSVLocal, cls).__new__(cls)
        cls.instances.append(new_instance)
        return new_instance

    def __init__(self, name, scene):
        self.name = name
        self.scene = scene
        self.nodes = list()  # type: List[GSVNode]
        self.values = list()

    def _build_nodes(self):
        """
        Find all the nodes in the scene that use the current gsv name.
        """

        self.nodes = list()

        for gsvnode in self.scene.nodes:

            if gsvnode.gsv_name == self.name:
                self.nodes.append(gsvnode)

            continue

        return

    def _build_values(self):
        """

        """

        # reset self.value first
        self.values = list()

        # iterate through all the nodes (think to build it first !)
        for node in self.nodes:

            # the parameter holding the potential variables value might
            # have children (ex:VariableSwitch)
            if node.gsv_values:
                self.values.extend(map(str, node.gsv_values))

            continue

        # remove duplicates values
        self.values = list(OrderedDict.fromkeys(self.values))

        return

    def build(self):

        self._build_nodes()
        self._build_values()

        logger.debug(
            "[GSVLocal][build] Finished for name=<{}>".format(self.name)
        )
        return

    def todict(self):

        if not self.values:
            logger.warning("[GSVLocal][todict] self.values is empty")
        if not self.nodes:
            logger.warning("[GSVLocal][todict] self.nodes is empty")

        return {
            "name": self.name,
            "values": self.values,
            "nodes": map(str, self.nodes)
        }


class GSVScene(object):
    """
    A group of node associated with an arbitrary number of gsvs.
    """

    def __init__(self):

        self.nodes = list()  # type: List[GSVNode]
        self.gsvs = list()  # type: List[GSVLocal]

    def _build_nodes(self):
        """
        Find all the nodes in the nodegraph that use the gsv feature.
        """

        # reset self.nodes first
        self.nodes = list()

        for node_class, _ in GSVNode.sources.items():

            nodes = NodegraphAPI.GetAllNodesByType(node_class)  # type: list
            for node in nodes:
                self.nodes.append(GSVNode(node))

            continue

        logger.debug(
            "[GSVLocal][_build_nodes] Finished. {} nodes found."
            "".format(len(self.nodes))
        )

        return

    def _build_gsvs(self):
        """
        From the node list find what gsv is used and build its object.
        """

        # reset self.gsvs first
        self.gsvs = list()

        for gsvnode in self.nodes:

            gsv = GSVLocal(gsvnode.gsv_name, self)
            # gsv might be excluded, so it returns None
            if not gsv:
                continue
            # avoid adding multiples times the same instance
            if gsv in self.gsvs:
                continue

            self.gsvs.append(gsv)
            continue

        # we don't forget to build the gsv object if we want to use its attributes
        for gsvlocal in self.gsvs:
            gsvlocal.build()

        logger.debug(
            "[GSVLocal][_build_gsvs] Finished. {} gsv found."
            "".format(len(self.gsvs))
        )

        return

    def build(self):

        self._build_nodes()
        self._build_gsvs()

        return

    def todict(self):
        return {"gsvs": list(map(lambda obj: obj.todict(), self.gsvs))}


"""____________________________________________________________________________

    USECASE

"""


def run():

    gsv_scene = GSVScene()
    gsv_scene.build()

    logger.info(
        "GSVScene :\n{}"
        "".format(json.dumps(gsv_scene.todict(), indent=4, sort_keys=True))
    )

    for gsv in gsv_scene.gsvs:

        if gsv.name == "temp":
            for node in gsv.nodes:
                NodegraphAPI.SetNodeEdited(
                    node.kobj,
                    edited=True,
                    exclusive=False
                )

        continue

    return


# execute

run()
