# ![python](https://img.shields.io/badge/python-333333?labelColor=FED142) Get Logical Upstream Nodes (glun)

![Python](https://img.shields.io/badge/Python-2+-4f4f4f?labelColor=FED142&logo=python)
![katana version](https://img.shields.io/badge/Katana-any-4f4f4f?labelColor=111111&logo=katana&logoColor=FCB123)

Parse scene to return a list of contributing node connected to the
given source node.

<img src="doc/img/demo.png" width="500">

Return all the node on the blue logical stream.

# Features

- Configurable : choose how to treat groups nodes.
- Logical parsing: visit only node contributing to building the scene
- Should cover the majority of nodegraph cases (if you do have one that yield
a weird result please fill an issue !)

```python
settings = ParseSettings()
settings.exluded_asGroupsNodeType = ["GafferThree"]
scene = SceneParser()
scene.settings = settings
scene.source = NodegraphAPI.GetAllSelectedNodes()[0]

result = scene.get_upstream_nodes()
print(result)
```


# Documentation

[![visit_documentation](https://img.shields.io/badge/visit_documentation-blue)](doc/INDEX.md)


> Or see the [./doc directory](doc).

# Licensing

Apache License 2.0

See [LICENSE.md](./LICENSE.md) for full licence.

- ✅ The licensed material and derivatives may be used for commercial purposes.
- ✅ The licensed material may be distributed.
- ✅ The licensed material may be modified.
- ✅ The licensed material may be used and modified in private.
- ✅ This license provides an express grant of patent rights from contributors.
- 📏 A copy of the license and copyright notice must be included with the licensed material.
- 📏 Changes made to the licensed material must be documented