# <img src="img/logotype.svg" width="100"> Index

Welcome on the `getLogicalUpstreamNodes` (glun) module documentation.

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)


# Use

## InLine

You just need to quickly list nodes in the ScriptEditor :

- just add `__test()` at the end.
- Select source node.
- Run in the script editor
- Check result in script editor console.

You can optionaly modify `__test()` to filter even more the result.

## Module

The file [getLogicalUpstreamNodes.py](../getLogicalUpstreamNodes.py) can be used
as it is as a python module for any of your projects.

> In that case you can delete the __test() function

Basic process is :

- Build your parsing settings using `ParseSettings()` special dict.
- Instance `SceneParser()`
- Set the instance's settings
- run `yourInstance.get_upstream_nodes(...)` to get the results

**Check the `__test()` function** and the bottom API documentation for more details.

# API

## ![class](https://img.shields.io/badge/class-6F5ADC) ParseSettings

Used to configure the output result of the scene parsing.

A regular dictionary object with a fixed structure. Structure is verified
through ``validate()`` method.

You can set the keys using the regular `dict["keyName"]` syntax or use the
properties mentioned under.

The class support all the regular methods supported by `dict`.

### ![method](https://img.shields.io/badge/method-4f4f4f) ParseSettings.`__init__`

When creating a new instance of the class, you can leave it empty and build
the key one by one, or pass a dictionnary which have already ALL the keys.

Exemple :

```python
setting_dict = {
    "include_groups": True,
    "excluded": {
        "asGroupsNodeType": ["GafferThree", "Importomatic"]
    },
    "logical": True
}
settings = ParseSettings(setting_dict)
```


### ![key](https://img.shields.io/badge/key-4f4f4f) ParseSettings["excluded"]
```
dict: see under for the keys
```
#### ![key](https://img.shields.io/badge/key-4f4f4f) ParseSettings["excluded"]["asGroupsNodeType"]

List of node type to exclude from being considered as `Group`. This mean it's
content will not be visited.

This can be the case for a `GafferThree` which is a subclass of a Group node, but
you might not want to visit all the nodes inside. So for this you can pass 
`["GafferThree"]`

```
list of str: str are node types. (Node.getType())
```

### ![key](https://img.shields.io/badge/key-4f4f4f) ParseSettings["include_groups"]

If the node visited is a Group (or a subclass) and this is set to `True`, it's
added to the output.
This just cover the case where you might want to visit a Group's content, but
you don't care about the group itself.

```
bool
```

### ![key](https://img.shields.io/badge/key-4f4f4f) ParseSettings["logical"]

If `True`, only node that contribute to building the scene are visited. For
exemple, a switch node will only yield one input that contribute to build the
scene.

```
bool
```

### ![property](https://img.shields.io/badge/property-4f4f4f) ParseSettings.exluded_asGroupsNodeType

Set the `ParseSettings["excluded"]["asGroupsNodeType"]` key.

### ![property](https://img.shields.io/badge/property-4f4f4f) ParseSettings.include_groups
### ![property](https://img.shields.io/badge/property-4f4f4f) ParseSettings.logical

### ![method](https://img.shields.io/badge/method-4f4f4f) ParseSettings.validate

Verify the structure of self and raise an AssertionError if a key is not
build properly/missing.

```
Raises:
    AssertionError: if self is not built properly.
```

## ![class](https://img.shields.io/badge/class-6F5ADC) SceneParser

The class with the method you want. (to do what the script is supposed to do)

At some point you will need to specify the starting point for the parsing. (`source`)
You have 3 way to do it as detailed below.


### ![method](https://img.shields.io/badge/method-4f4f4f) ParseSettings.`__init__`

```
Args:
    source(None or NodegraphAPI.Node or NodegraphAPI.Port):
        Set the nodegraph object used as a start point for parsing.
```


### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) SceneParser.settings

Dictionary of options for the scene parsing

```
ParseSettings
```

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) SceneParser.source

Set the nodegraph object used as a start point for parsing. 

Can also be set in `ParseSettings.get_upstream_nodes` `source` argument

```
None or NodegraphAPI.Node or NodegraphAPI.Port
```

### ![method](https://img.shields.io/badge/method-4f4f4f) ParseSettings.get_upstream_nodes

Return a list of node upstream of the given nodegraph object using the
pre-configured settings.

Make sure the settings attributes is set accordingly before calling.

```
Args:
    source(None or NodegraphAPI.Node or NodegraphAPI.Port):
        source nodegraph object from where to start the upstream parsing
        You also can use SceneParser.source to set it. (and pass None here)

Returns:
    list of NodegraphAPI.Node:
        Order of visit is respected but being a 1D list
        this might not be the order you except. 

```

---

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
