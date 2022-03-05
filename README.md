![header](./img/header.jpg)

**Author:** Liam Collod.

Collections of scripting stuff I wrote for Foundry's Katana software.


| | | |
|:-------------------------:|:-------------------------:|:-------------------------:|
|<img width="800" alt="Create GSV scipt" src="./src/nodegraph/CreateGSV/demo.gif">  CreateGSV |  <img width="800" alt="LightViewerAnnotate script" src="./src/viewer/LightViewerAnnotate/demo.gif"> LightViewerAnnotate |<img width="800" alt="PointcloudWidth" src="./src/viewer/PointcloudWidth/demo.gif">  PointcloudWidth  |


## Utilisation

You can have a look at the  `README.md` file in each folder.

Else each script should always have a top docstring for documentation.



## What's Inside

- attributes

  - [`attrTypeSwap`](./src/attributes/attrTypeSwap) 
      
      Quickly change the data type used for an attribute for another one.

- viewer
  
  - [`LightViewerAnnotate`](./src/viewer/LightViewerAnnotate) 
  
      Annotate (& color) lights in the viewer using their attributes.
  
  - [`PointcloudWidth`](./src/viewer/PointcloudWidth)
  
      Add a `geometry.point.width` attribute to control the size of the points in the viewer.
  
  - [`PointcloudXform2P`](./src/viewer/PointcloudXform2P)
  
      Allow merging xform transformations on a pointcloud location to the `geometry.point.P` attribute.
  
- instancing

  - [`KUI`](./src/instancing/KUI) 
      
      Provide a flexible solution for instancing based on point-cloud locations. 

- nodegraph

  - [`CreateGSV`](./src/nodegraph/CreateGSV)

      Configure the scene's graph state variables as simple as configuring a python dictionary.

  - [`DivideResolution`](./src/nodegraph/DivideResolution)

      Divide the current render resolution by the given amount.

- utility
  
  - [`llloger`](./src/utility/lua_logger)
  
    A simple lua logging module based on Python's one.
  
  - [`getLogicalUpstreamNodes`](./src/utility/getLogicalUpstreamNodes)
     
    Parse scene to return a list of contributing node connected to the
    given source node.

    

## Licensing

See [LICENSE.md](./LICENSE.md) for full licence.

License should be specified in each directory or in the top of each file else
the terms specified in the above LICENSE.md file shoudl apply.


## Contact

[monsieurlixm@gmail.com](mailto:monsieurlixm@gmail.com)

