"""

"""
import json
from pathlib import Path

import d2gt


def test01():
    """
    test tokens replacement is properly working.
    """

    token = Path("tokenDemo1.json").resolve()
    td = d2gt.TokenDict(str(token))

    scene_list = [
        str(Path("demo1.json").resolve())
    ]

    for scene in scene_list:
        gd = d2gt.GafferDict(scene, tokendict=td)
        print(json.dumps(gd, indent=4))
        print("-"*50)
        print(json.dumps(gd.children, indent=4))

    return


if __name__ == '__main__':

    test01()