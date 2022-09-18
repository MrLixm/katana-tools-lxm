"""
VERSION = 0.0.6

Author: Liam Collod
Last modified: 07/01/2022

Script for Foundry's Katana software.
Add global graph state variable based on a dictionnary.

[HowTo]
Modify the GGSV_DICT to add/delete gsvs, then run the script.
"""
import NodegraphAPI


# each key is the gsv name, the value its the list of value the gsv can take.
GGSV_DICT = {
    "shading": ["Final", "Preview", "Grey"],
    "shot": ["A", "B", "C"],
}


def setup_gsvs():

    for gsv_name, gsv_data in GGSV_DICT.items():
        create_gsv(name=gsv_name, value_list=gsv_data)

    print(
        "[CreateGSV][setup_gsvs] Finished, {} gsv added."
        "".format(len(GGSV_DICT))
    )
    return


def create_gsv(name, value_list):
    """
    Create a graph state variable with the given name and with the given values.
    Delete it if it already exists.

    Args:
        name(str):
        value_list(list of str):

    """
    gsv_all = NodegraphAPI.GetRootNode().getParameter('variables')

    # check if the gsv already exists and delete it
    gsv_current = gsv_all.getChild(name)
    if gsv_current:
        gsv_all.deleteChild(gsv_current)

    new_gsv = gsv_all.createChildGroup(name)
    new_gsv.createChildNumber('enable', 1)
    new_gsv.createChildString('value', value_list[0])
    new_gsv_param = new_gsv.createChildStringArray(
        'options',
        len(value_list)
    )
    for option_param, option_value in zip(new_gsv_param.getChildren(), value_list):
        option_param.setValue(option_value, 0)
    
    print(
        "[CreateGSV][create_gsv] Gsv <{}> created with values <{}>."
        "".format(name, value_list)
    )
    return


# execute

setup_gsvs()
