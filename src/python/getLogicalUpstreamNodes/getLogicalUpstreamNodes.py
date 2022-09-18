"""
version=2
author=Liam Collod
last_modified=11/03/2022
python=>2.7.1

Script for Foundry's Katana software.
Parse scene to return a list of contributing node connected to the
given source node.

[License]

Copyright 2022 Liam Collod

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""
import NodegraphAPI

# error on Python2, for comments only anyway
try:
    from typing import Tuple, Optional
except ImportError:
    pass

__all__ = [
    "SceneParser",
    "ParseSettings"
]


class ParseSettings(dict):
    """
    A regular dictionary object with a fixed structure. Structure is verified
    through ``validate()`` method.

    Used to configure the output result of the scene parsing.

    [include_groups](bool)
         If True, before visiting its content, include the group node in the output
    [excluded.asGroupsNodeType](list of str):
        list of node type that should not be considered as groups and children
        are as such not processed.
    [logical](bool):
        True to process only logical connections between nodes.
        (ex: Switch node only have 1 logical connection)
    """

    __default = {
        "include_groups": False,
        "excluded": {
            "asGroupsNodeType": []
        },
        "logical": True
    }

    def __init__(self, *args, **kwargs):

        if not args and not kwargs:
            super(ParseSettings, self).__init__(self.__default)
        else:
            super(ParseSettings, self).__init__(*args, **kwargs)
            self.validate()

        return

    def __setitem__(self, *args, **kwargs):
        super(ParseSettings, self).__setitem__(*args, **kwargs)
        self.validate()

    # Defined some properties to set/get values. Allow to use autocompletion.

    @property
    def exluded_asGroupsNodeType(self):
        return self["excluded"]["asGroupsNodeType"]

    @exluded_asGroupsNodeType.setter
    def exluded_asGroupsNodeType(self, value):
        self["excluded"]["asGroupsNodeType"] = value

    @property
    def logical(self):
        return self["logical"]

    @logical.setter
    def logical(self, logical_value):
        self["logical"] = logical_value

    @property
    def include_groups(self):
        return self["include_groups"]

    @include_groups.setter
    def include_groups(self, include_groups_value):
        self["include_groups"] = include_groups_value

    def validate(self):
        """
        Raises:
            AssertionError: if self is not built properly.
        """
        pre = "[{}] ".format(self.__class__.__name__)

        assert self.get("excluded"),\
            pre + "Missing key <excluded>"

        assert isinstance(self["excluded"].get("asGroupsNodeType"), list),\
            pre + "Missing key <excluded.asGroupsNodeType>"

        assert isinstance(self.get("logical"), bool),\
            pre + "Missing key <logical> or value is not <bool>."

        assert isinstance(self.get("include_groups"), bool),\
            pre + "Missing key <include_groups> or value is not <bool>."

        return


class SceneParser(object):
    """
    Attributes:

        __buffer(list of NodegraphAPI.Node):
            list of visited node in "pseudo-order" after a parsing operation.
            Must be returned by the parsing function and reset after.

        settings(ParseSettings):
            Options for the scene parsing
    """

    def __init__(self, source=None):

        self.source = source
        self.__buffer = list()
        self.settings = ParseSettings()

        return

    def __get_upstream_nodes(self, source, grp_node=None):
        """
        From a given node, find all upstream nodes connected.

        Groups node themself are not included in the output but their children are
        processed (unless contrary specified in settings).

        Args:
            grp_node (NodegraphAPI.GroupNode or None): GroupNode the source might belongs to.
            source(NodegraphAPI.Node or NodegraphAPI.Port):
                object to start the parsing from.

        Returns:
            None:
        """

        # we always have at least source_node != None
        if isinstance(source, NodegraphAPI.Port):
            source_port = source
            source_node = source.getNode()
        elif isinstance(source, NodegraphAPI.Node):
            source_port = None
            source_node = source
        else:
            raise TypeError(
                "Submited source argument <{}> is not supported."
                "Must be Port or Node."
                "".format(source)
            )

        # We are goint out of a group, its potential inputs have all already
        # been processed.
        if grp_node == source_node:
            if self.settings.include_groups:
                self.__buffer.append(source_node)
            return

        # When we got a groupNode we need to also parse what's inside (unless
        # the node it is excluded). To do so we swap the passed inputPort/node
        # of the group by the ones from the first children in the group.
        # (i): We reach this only when going in a group.
        if isinstance(
            source_node,
            NodegraphAPI.GroupNode
        ) and (
            source_node.getType() not in self.settings.exluded_asGroupsNodeType
        ):

            # if we passed a port we can just find what child node is connected
            if source_port:
                # at first we assume we a going inside the group = return port
                __port = source_node.getReturnPort(source_port.getName())
                if not __port:
                    raise RuntimeError(
                        "[__get_upstream_nodes][is grp] No Return port found"
                        "  on node <{}> with source port <{}>."
                        " This should not happens ?!"
                        "".format(source_node, source_port)
                    )

                source_port = __port.getConnectedPorts()[0]
                # instead of continuing we parse directly the upstream node
                # of the connected output node. Not returning would create an
                # issue when 2 grp are connected and the top one doesnt have inputs.

            else:
                # if no port supplied we assume the group only have one output
                source_port = source_node.getOutputPortByIndex(0)
                # and if he doesn't even have an output port ...
                if not source_port:
                    raise TypeError(
                        "The given source_obj[0] is a GroupNode with no output "
                        "port which is not currently supported."
                    )
                source_port = source_node.getReturnPort(source_port.getName())
                source_port = source_port.getConnectedPorts()[0]
                # make sure that if the new node is a group, it is properly
                # parsed too.

            # the group is added first in the buffer
            if self.settings.include_groups:
                self.__buffer.append(source_node)
            # now parse the node inside the group starting by the
            # most downstream one we found
            self.__get_upstream_nodes(source_port, grp_node=source_node)
            if source_node.getInputPorts():
                grp_node = source_node
                # we continue the method, by finding connections on the group
                pass
            else:
                # we have already visited it's content so stop here
                return

        else:
            # as not a grp, add to the buffer (grp have already been added)
            self.__buffer.append(source_node)

        # We need to find a list of port connected to this node
        connected_ports = node_get_connections(
            node=source_node,
            logical=self.settings.logical
        )
        # Node doesn't have any inputs so return.
        if not connected_ports:
            return

        # now process all the input of this node
        for connected_port in connected_ports:

            # avoid processing multiples times the same node/port
            if connected_port.getNode() in self.__buffer:
                continue

            self.__get_upstream_nodes(
                source=connected_port,
                grp_node=grp_node
            )

            continue

        return

    def __reset(self):
        """
        Operations done after a parsing to reset the instance before the next
        parsing.
        """
        self.__buffer = list()
        self.settings = ParseSettings()
        return

    def get_upstream_nodes(self, source=None):
        """
        Make sure the settings attributes is set accordingly before calling.

        Args:
            source(NodegraphAPI.Node or NodegraphAPI.Port):
                source nodegraph object from where to start the upstream parsing

        Returns:
            list of NodegraphAPI.Node:
        """
        source = source or self.source
        if not source:
            raise ValueError(
                "[get_upstream_nodes] Source argument is nul. Set the class "
                "source attribute or pass a source argument to this method."
            )
        self.__get_upstream_nodes(source=source)
        out = self.__buffer  # save the buffer before reseting it
        self.__reset()

        return out


def node_get_connections(node, logical=True):
    """
    From a given node return a set of the connected output ports .

    If logical is set to True only port's nodes contributing to building
    the scene as returned. For example, in the case of a VariableSwitch,
    return only the connected port active.

    Works for any node type even with only one input or no input.

    Args:
        logical(bool): True to return only logical connections.
        node(NodegraphAPI.Node):

    Returns:
        set of NodeGraphAPI.Port: set of ports connected to the passed node
    """

    output = set()
    in_ports = node.getInputPorts()

    for in_port in in_ports:
        # we assume input port can only have one connection
        connected_port = in_port.getConnectedPort(0)
        if not connected_port:
            continue

        if logical:
            # Having a GraphState means the node is evaluated.
            if connected_port.getNode().getGraphState():
                output.add(connected_port)
        else:
            output.add(connected_port)

    return output


def __test():
    """
    Example use case of the above functions.
    """

    # we avoid visiting GT nodes content.
    setting_dict = {
        "include_groups": True,
        "excluded": {
            "asGroupsNodeType": ["GafferThree"]
        },
        "logical": True
    }
    excluded_ntype = ["Dot"]

    sel = NodegraphAPI.GetAllSelectedNodes()  # type: list

    scene = SceneParser()
    scene.settings = ParseSettings(setting_dict)
    result = scene.get_upstream_nodes(sel[0])

    # removed nodes of unwanted type
    result = filter(lambda node: node.getType() not in excluded_ntype, result)
    # convert nodes objects to string
    result = map(lambda obj: obj.getName(), result)
    # result.sort()  # break the visited order ! but nicer for display

    import pprint
    print("_"*50)
    pprint.pprint(result)

    return
