"""
VERSION = 0.0.1

Author: Liam Collod
Last modified: 18/01/2022

Script for Foundry's Katana software.
TODO

[HowTo]
TODO
"""
from collections import OrderedDict
import sys
import logging

import NodegraphAPI


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


logger = setup_logging(logging.DEBUG)


""" config_dict(dict)
Configure how the script behave

[lvl0]
[key=exclude:value](list):
    variable names that will be removed from result
[key=nodes:value](dict):
    List the node that make use of local GSVs.

[lvl1]
[key=nodes:value.key](str):  
    nodeType 
[key=nodes:value.key:value](str):  
    parameters path on node that return the GSV name
"""
config_dict = {
    "exclude": ["gafferState"],
    "nodes": {
        "VariableSwitch": "variableName",
        "VariableEnabledGroup": "variableName"
    }
}


class SceneGSV(list):

    def filter(self, remove_duplicates=True, exclude=None):
        """
        Args:
            remove_duplicates(bool):
            exclude(list or None):
        """
        if not exclude:
            exclude = list()

        if remove_duplicates:
            self[:] = SceneGSV(OrderedDict.fromkeys(self))

        for value in list.__iter__(self):
            if value in exclude:
                self.remove(value)

        return


def run():

    scene_gsvs = SceneGSV()

    for node_class, param_path in config_dict["nodes"].items():

        nodes = NodegraphAPI.GetAllNodesByType(node_class)

        for node in nodes:

            value = node.getParameterValue(
                param_path,
                NodegraphAPI.GetCurrentTime()
            )

            if not value:

                logger.error(
                    "Node <{}> doesn't have param <{}> or returned value is None."
                    "".format(node, param_path)
                )
                continue

            scene_gsvs.append(value)
            continue

        continue

    scene_gsvs.filter(exclude=config_dict["exclude"])
    logger.info(scene_gsvs)
    return


# execute

run()
