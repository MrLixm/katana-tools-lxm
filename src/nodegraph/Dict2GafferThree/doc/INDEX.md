
# Token Dictionnary

Compatible with one render-engine only. So you should have one per render-engine.

# Gaffer Dictionnary

## `name`

Name must be unique in scene. If another node with the same name is found, this
node will be considered as previous version and updated. Updated means the found
version is deleted and a new version is created but this one will keep
the nodegraphs connections and position.

## `children`

Each key/value pair represents a Package to create in the GafferThree.
Where key = package scene graph name,
Value = dict representing the Package structure

### token support

For each key OR value in the Package dict you can use tokens 

### `dict.parent`

CEL like path, `/` is the separator
If at root use `""` or `"/"`

### `dict.params`

Dictionnary where each key represent the path to a parameter to modify, and
the value, the parameter value to set.