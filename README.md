# PortalsInHLA
Portals in HLA using VScript


## Important Information:
the Scripts folder needs to go to the HLA/Game/HLVR_Addons/YOURADDON/
folder otherwise the scripts won't work

The PortalManager Prefab is Require to be present in any map. it also needs to be at World origin so 0,0,0
The Position of the Angle Sensors in the prefab determine the Colors of the Portals. so you can change them if you like.
Through Map I/O you can Close all Portals if you like. for stuff like a Material Emancipation Grill

The PortalGun Prefab just has the Script attached to a NPC_Furniture. so if you want to not give the player a PortalGun just don't spawn it into the map.
if you want to remove the PortalGun, just do Hammer I/O and Kill @PortalGun. That should remove the PortalGun from the player.

The Portal_Spawner Prefab allows to spawn portals through I/O. thats about it

