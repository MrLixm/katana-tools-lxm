# Katana launcher script
# made for git-bash on Windows

cd ..

KATANA_VERSION="4.5v1"
KATANA_HOME=/C/Program\ Files/Katana$KATANA_VERSION
KATANA_TAGLINE="Katana demo - arnold, delight, prman"

export PATH="$PATH:$KATANA_HOME/bin"
export KATANA_CATALOG_RECT_UPDATE_BUFFER_SIZE=1

export KATANA_USER_RESOURCE_DIRECTORY="./dev/prefs"
# ideally here you would append by add $KATANA_RESOURCES but if the variable is
# empty it caus eissues with git bash on windows
export KATANA_RESOURCES="$CWD/resources"

# LUA: OPTIONAL
# bug on windows git bash where the ? break the path expansion
# so we have to write it the windows way
export LUA_PATH="$LUA_PATH;.\?.lua"

# RENDER-ENGINES
# --------------

export DEFAULT_RENDERER="dl"

# 3Delight
U_DELIGHT=/C/Program\ Files/3Delight
export DLFK_INSTALL_PATH="$U_DELIGHT/3DelightForKatana"
export DL_DISPLAYS_PATH="$U_DELIGHT/displays"
export DL_SHADERS_PATH="$U_DELIGHT/shaders"
export DLC_KATANA="$DLFK_INSTALL_PATH/Plugins"
export PATH="$PATH:$U_DELIGHT/bin"
export KATANA_RESOURCES="$KATANA_RESOURCES:$DLFK_INSTALL_PATH"

# Arnold
U_KTOA_VERSION="ktoa-4.0.0.2-kat4.5-windows"
U_KTOA_HOME="/C/Users/lcoll/ktoa/$U_KTOA_VERSION"
export ARNOLD_PLUGIN_PATH="$U_KTOA_HOME/Plugins"
export PATH="$PATH:$U_KTOA_HOME/bin"
export KATANA_RESOURCES="$KATANA_RESOURCES:$U_KTOA_HOME"

# Prman
U_PRMAN_HOME="/C/Program Files/Pixar/RenderManForKatana-24.3"
U_PRMAN_KATANA_VERSION="katana4.5"
export RMANTREE="/C/Program Files/Pixar/RenderManProServer-24.3"
export KATANA_RESOURCES="$KATANA_RESOURCES:$U_PRMAN_HOME/plugins/$U_PRMAN_KATANA_VERSION"

# Xgen for render-engine supporting it
export U_MAYA_INSTALLATION="/C/Program Files/Autodesk/Maya2020"
export U_XGEN_LOCATION="$U_MAYA_INSTALLATION/plug-ins/xgen"
export PATH="$PATH:$U_XGEN_LOCATION:$U_XGEN_LOCATION/bin:$U_MAYA_INSTALLATION/bin"

"$KATANA_HOME\bin\katanaBin.exe"
