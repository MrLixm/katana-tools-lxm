"""
version=2
author=Liam Collod
last_modified=22/03/2022
python=>2.7.1

From the selected nodes, if it's a Backdrop, set the hideAsBookmark attribute
as true so the node doesn't appear in bookmarks.

[howto]
- Select all the backdropes nodes
    (you can also select other node types they will be filtered out)
- run script in Python Tab

[LICENSE]

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


def bd_remove_bookmark(bdnode):
    """
    https://community.foundry.com/discuss/topic/145909/can-we-create-a-backdrop-using-nodegraphapi?mode=Post&postID=1162565&show=backdrop%2cpython#1162565

    Args:
        bdnode(NodegraphAPI.Node): backdrop node
    """

    attrs = NodegraphAPI.GetNodeShapeAttrs(bdnode)  # type: dict
    attrs["hideAsBookmark"] = True
    NodegraphAPI.SetNodeShapeNodeAttrs(bdnode, attrs)

    return


def run():

    sel = NodegraphAPI.GetAllSelectedNodes()
    # remove nodes that are not Backdrops
    sel = filter(lambda knode: knode.getType() == "Backdrop", sel)

    for node in sel:
        bd_remove_bookmark(node)

    print("[remove_bookmark][run] Finished.\n{} nodes processed.".format(sel))
    return


run()