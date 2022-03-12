"""
version=2
python>=2.7.1
author=Liam Collod
last_modified=03/03/2022

Convert the selected nodes to an XML representation. You can then write it to a
file or just print it in the console.

"""
import os

from Katana import NodegraphAPI


def get_selection_xml():
    nodes = NodegraphAPI.GetAllSelectedNodes()
    return NodegraphAPI.BuildNodesXmlIO(nodes)


def print_xml(xml=None):
    xml = xml or get_selection_xml()
    print(xml.writeString())
    return


def write_xml(target_dir, target_name, display=False):

    target_path = os.path.join(target_dir, "{}.xml".format(target_name))

    xml = get_selection_xml()

    if display:
        print_xml(xml)

    xml.write(
        file=target_path,
        outputStyles=None
    )

    print(
        "[write_xml] Finished. XML written to <{}>".format(target_path)
    )
    return


print_xml()
# write_xml(
#     target_dir=r"G:\personal\code\KUI\workspace\v0001\KUI",
#     target_name="KUI_Nodes"
# )