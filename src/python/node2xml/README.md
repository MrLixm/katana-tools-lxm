# node2xml

![Python](https://img.shields.io/badge/Python-2+-4f4f4f?labelColor=FED142&logo=python)
![katana version](https://img.shields.io/badge/Katana-any-4f4f4f?labelColor=111111&logo=katana&logoColor=FCB123)

Nothing ground-breaking, just wrap the Katana API methods for converting nodes
to an XML representation that you can write to file or print.

 - The interesting file is [node2xml.exporter.xml](node2xml.exporter.xml). You
can copy/paste it in Katana and you will get a node to quickly export any other
nodegraph's node to xml. (It uses [node2xml.button.py](node2xml.button.py))

 - [node2xml.py](node2xml.py) Can be quickly executed in the Python Tab to print
or write the selected nodes XML.

 - TODO: would be cool to make a shelf script.

Example of XML for an Alembic_In node :

```xml
<katana release="4.5v1" version="4.5.1.000008">
  <node name="__SAVE_exportedNodes" type="Group">
    <node baseType="Alembic_In" edited="true" name="Alembic_In_pointcloud1" ns_errorGlow="0.0" ns_fromContext="legacy" ns_viewState="2.0" selected="true" type="Alembic_In" x="-2048.0" y="880.0">
      <port name="out" type="out"/>
      <group_parameter name="Alembic_In_pointcloud1">
        <string_parameter name="name" useNodeDefault="false" value="/root/world/geo/asset/pointcloud"/>
        <string_parameter name="abcAsset" useNodeDefault="false" value="someparth/instancingDemo.pointcloud.0004.abc"/>
        <number_parameter name="addForceExpand" value="1"/>
        <string_parameter name="addBounds" value="root"/>
        <number_parameter name="fps" value="24"/>
        <number_parameter name="addToCameraList" value="0"/>
        <group_parameter name="timing">
          <string_parameter name="mode" value="Current Frame"/>
          <number_parameter expression="globals.inTime" isexpression="true" name="holdTime"/>
          <number_parameter expression="globals.inTime" isexpression="true" name="inTime"/>
          <number_parameter expression="globals.outTime" isexpression="true" name="outTime"/>
        </group_parameter>
        <group_parameter name="advanced">
          <number_parameter name="useOnlyShutterOpenCloseTimes" value="0"/>
        </group_parameter>
      </group_parameter>
    </node>
  </node>
</katana>
```