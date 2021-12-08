# PortalsInHLA
Portals in HLA using VScript. **THIS IS NOT A STANDALONE MOD**, it needs to be integrated into workshop maps, and does not work with the Campaign or out of the box.

Placing the PortalManager Prefab into your own workshop map will allow portals to exist either through the PortalSpawner prefabs or through the seperate PortalGun Prefab which will automatically attach to the players right hand on map spawn


## Important Information:
the Scripts folder needs to go to the HLA/Game/HLVR_Addons/YOURADDON/
folder otherwise the scripts won't work

to restrict a portal from being placed simply tie that mesh to a func_brush (or better duplicate that mesh and apply the notportable.vmat material to it that way it will still calculate vis properly. because i think func_brush doesn't compute vis) and set `always solid` as the solidity.
transparent objects like glass can just be directly tied to a func_brush because they shouldn't generate vis regardless.


### Prefab infos:

The PortalManager Prefab is Require to be present in any map. it also needs to be at World origin so 0,0,0
The Position of the Angle Sensors in the prefab determine the Colors of the Portals. so you can change them if you like.
Through Map I/O you can Close all Portals if you like. for stuff like a Material Emancipation Grill

The PortalGun Prefab just has the Script attached to a NPC_Furniture. so if you want to not give the player a PortalGun just don't spawn it into the map.
if you want to remove the PortalGun, just do Hammer I/O and Kill @PortalGun. That should remove the PortalGun from the player.

The Portal_Spawner Prefab allows to spawn portals through I/O. thats about it

