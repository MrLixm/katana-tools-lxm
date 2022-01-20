"""
VERSION = 0.0.1

Author: Liam Collod
Last modified: 18/01/2022

Script for Foundry's Katana software.
TODO

[HowTo]
TODO
"""
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


""" variable_nodes_setup(dict)
List the node that make use of local GSVs.
key = nodeType : value = parameters path that return the GSV name
"""
variable_nodes_setup = {
    "VariableSwitch": "variableName",
    "VariableEnabledGroup": "variableName"
}


def run():

    variables_list = list()

    for node_type, param_path in variable_nodes_setup.items():

        nodes = NodegraphAPI.GetAllNodesByType(node_type)

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

            variables_list.append(value)
            continue

        continue


    logger.info(variables_list)
    return


# execute

run()
