# ![PyScript](https://img.shields.io/badge/type-Python-yellow) Get Logical Upstream Nodes (glun)

Parse scene to return a list of contributing node connected to the
given source node.

![demo](./demo.png)
Return all the node on the blue logical stream.

## Use

Code should be fairly documented.

### InLine

To quickly display node in teh script-editors :

- just add `__test()` at the end.
- Select source node.
- Run in the script editor
- Check result in script editor console.

You can optionaly modify `__test()` to filter evn more the result.

### Module

You can use it as a module.

- You can delete the __test() function
- Build your parsing settings using `ParseSettings()` special dict.
- run `get_logical_upstream_nodes()`, check docstring for required arguments.

## Licensing

Apache License 2.0

See [LICENSE.md](./LICENSE.md) for full licence.

- ✅ The licensed material and derivatives may be used for commercial purposes.
- ✅ The licensed material may be distributed.
- ✅ The licensed material may be modified.
- ✅ The licensed material may be used and modified in private.
- ✅ This license provides an express grant of patent rights from contributors.
- 📏 A copy of the license and copyright notice must be included with the licensed material.
- 📏 Changes made to the licensed material must be documented