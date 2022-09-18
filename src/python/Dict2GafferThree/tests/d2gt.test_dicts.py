"""
python>3
"""
import json
from pathlib import Path
from typing import List, Type, Optional

import d2gt


def test01():
    """
    test tokens replacement is properly working.
    """

    token = Path("testTokenA.json").resolve()
    td = d2gt.TokenDict(str(token))

    scene_list = [
        str(Path("testGafferA.json").resolve())
    ]

    for scene in scene_list:
        gd = d2gt.GafferDict(scene, tokendict=td)
        print(json.dumps(gd, indent=4))
        print("-"*50)
        print(json.dumps(gd.children, indent=4))

    return


def test02():

    token = Path("testTokenA.json").resolve()
    td = d2gt.TokenDict(str(token))

    scene = str(Path("testGafferA.json").resolve())

    gd = d2gt.GafferDict(scene, tokendict=td)
    # we iter a first time through all package to assign their parent
    pkg2create_dict = gd.children
    pkg2create_list = list(pkg2create_dict.values())  # type: List[d2gt.GafferChildrenDict]
    for pkg2create in pkg2create_list:
        pkg = pkg2create_dict.get(pkg2create.direct_parent)
        if pkg:
            pkg2create.parent = pkg

    # DEBUG
    for pkg2create in pkg2create_list:
        parent = pkg2create.parent
        parent = parent.name if parent else parent
        children = pkg2create.children
        children = list(map(lambda c: c.name, children)) if children else children
        print(
            f"{pkg2create.name}\n"
            f"   parent = {parent},\n"
            f"   children = {children}\n"
        )

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

    print("pkg2create_list2 final order:")
    for pkg2create in pkg2create_list:
        parent = pkg2create.parent
        parent = parent.name if parent else parent
        print(f"- {pkg2create.name} with parent = <{parent}> and path = {pkg2create.path}")
    return


if __name__ == '__main__':

    # test01()
    test02()