"""
version=3
python>=2.7.1
author=Liam Collod
last_modified=12/03/2022


Convert the selected nodes to an XML representation, and write or print it.

To be used in a scrip button.
The button parameter must be named <export> or <print> to execute the
 corresponding function.

The following parameters should also exists on the same node :
- user.node_name (str) : name of the node to export/print
- user.export_path (str) : export path of the xml

"""
import os

from Katana import NodegraphAPI, UI4


def err(message):
    """
    Raise a small dialog with the given message and then raise a RuntimeError

    Args:
        message(str): error maise to raise
    """
    message = "[ScriptButton][node2xml]{}".format(message)
    raise RuntimeError(message)


def log(message):
    # the print function for this script
    message = "[ScriptButton][node2xml]{}".format(message)
    print(message)
    return


def get_selection_xml():
    nodes = NodegraphAPI.GetAllSelectedNodes()
    return NodegraphAPI.BuildNodesXmlIO(nodes)


def print_xml(xml=None):
    xml = xml or get_selection_xml()
    return log("\n" + xml.writeString())


def write_xml(target_dir, target_name, display=False):
    """

    Args:
        target_dir(str): path to an existing directory
        target_name(str): name of the file to write without the extension
        display(bool): True to also print the xml file
    """

    target_path = os.path.join(target_dir, "{}.xml".format(target_name))

    xml = get_selection_xml()

    if display:
        print_xml(xml)

    xml.write(
        file=target_path,
        outputStyles=None
    )

    return log("[write_xml] Finished. XML written to <{}>".format(target_path))


def run():

    process = parameter.getName()

    export_node_name = node.getParameter("user.node_name").getValue(0)
    export_node = NodegraphAPI.GetNode(export_node_name)
    if not export_node:
        err("[run] Can't find node_name={}".format(export_node_name))

    # the xml function act on the selected node
    # we save the curent selection to override it and re-apply it at the end
    current_selection = NodegraphAPI.GetAllSelectedNodes()
    NodegraphAPI.SetAllSelectedNodes([export_node])

    if process == "export":

        export_path = node.getParameter("user.export_path").getValue(0)
        if not export_path.endswith(".xml"):
            err("[run] Export path doesn't ends with .xml: <{}>".format(
                export_path))

        export_dir, export_name = os.path.split(export_path)
        export_name = os.path.splitext(export_name)[0]  # strip the .xml
        if not os.path.exists(export_dir):
            err("[run] Export directory must exists ! <{}>".format(export_path))

        write_xml(
            target_dir=export_dir,
            target_name=export_name
        )

    elif process == "print":
        print_xml()

    else:
        err(
            "This button <{}> should be named <export> or <print>"
            "".format(process)
        )

    NodegraphAPI.SetAllSelectedNodes(current_selection)
    return


run()