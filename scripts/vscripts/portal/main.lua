local portalx = 25
local portaly = 55
local portalz = 100
local detectRadius = portaly

local mins = Vector(-(portalx / 2), -(portaly / 2), -(portalz / 2))
local maxs = Vector(portalx / 2, portaly / 2, portalz / 2)

Debugging = _G.Debugging or false


tickrate = _G.tickrate or 0.05

local LightOmniTemplate = {
    targetname = "bluePortal_light_omni",
    color = "15 121 148 255",
    brightness = "0.05",
    directlight = 2,
    indirectlight = 0,
    lightsourceradius = 30,
    baked_light_indexing = 0
}
local AimatTemplate = {
    targetname = "bluePortal_aimat"
}
local ParticleSystemTemplate = {
    targetname = "bluePortal_particles",
    effect_name = "particles/portal_effect_parent.vpcf",
    cpoint5 = "bluePortal"
}
local LogicScriptTemplate = {
    targetname = "LogicScript",
    Group00 = "bluePortal_aimat",
    Group01 = "bluePortal_light_omni",
    Group02 = "bluePortal_particles"
}
local ViewPortalTemplate = {
    targetname = "Portal_view",
    model = "models/vrportal/portalshape.vmdl",
    skin = "default"
}
local PointCameraTemplate = {
    targetname = "Portal_camera",
    ZNear = "4",
    ZFar = "10000",
    FOV = "90",
    UseScreenAspectRatio = "1"
}
local FuncMonitorTemplate = {
    targetname = "FuncMonitor",
    target = "Portal_camera",
    resolution = "3",
    unique_target = "1",
    render_shadows = "1"
}
Colors = _G.Colors or {
    Blue = "blue",
    Orange = "orange"
}

PortalManager = _G.PortalManager or {
    PortableFunc = false,

    ColorEnts = {},
    BluePortalGroup = {},
    OrangePortalGroup = {},

    BlueCamera = {},
    OrangeCamera = {},
}

PortalWhitelist= {
    "prop_physics",
    "func_physbox",
    "npc_manhack",
    "item_hlvr_grenade_frag",
    "item_hlvr_grenade_xen",
    "item_hlvr_prop_battery",
    "prop_physics_interactive",
    "prop_physics_override",
    "prop_ragdoll",
    "generic_actor",
    "hlvr_weapon_energygun",
    "item_healthvial",
    "item_item_crate",
    "item_hlvr_crafting_currency_large",
    "item_hlvr_crafting_currency_small",
    "item_hlvr_clip_energygun",
    "item_hlvr_clip_energygun_multiple",
    "item_hlvr_clip_rapidfire",
    "item_hlvr_clip_shotgun_single",
    "item_hlvr_clip_shotgun_multiple",
    "item_hlvr_clip_generic_pistol",
    "item_hlvr_clip_generic_pistol_multiple",
}
local laspplayerteleport = 0


DoIncludeScript("portal/storage", thisEntity:GetPrivateScriptScope())

function PortalManager:init()
    PortalManager.ColorEnts = {
        [Colors.Orange] = Entities:FindByName(nil, "@OrangePortalColor"),
        [Colors.Blue] = Entities:FindByName(nil, "@BluePortalColor")
    }
    local loopColor = Colors.Blue


    for i = 1, 2, 1 do
        -- print("i: " .. i)
        local ent = nil
        if i == 1 then
            loopColor = Colors.Orange
            ent = PortalManager:GetPortalGroup(loopColor)[1]
        else
            loopColor = Colors.Blue
            ent = PortalManager:GetPortalGroup(loopColor)[1]
        end




        -- print(ent)
        if ent then
            if laspplayerteleport- GetFrameCount() < 0 and PortalManager:CanTeleport(player, loopColor) and player:GetHMDAvatar() ~= nil then
                if loopColor == Colors.Blue then
                    player:GetHMDAnchor():SetAbsOrigin((PortalManager.OrangePortalGroup[1]:GetAbsOrigin()+PortalManager.OrangePortalGroup[1]:GetForwardVector()*30)+(player:GetHMDAnchor():GetOrigin()-player:GetHMDAvatar():GetOrigin()))
                else
                    player:GetHMDAnchor():SetAbsOrigin((PortalManager.BluePortalGroup[1]:GetAbsOrigin()+PortalManager.BluePortalGroup[1]:GetForwardVector()*30)+(player:GetHMDAnchor():GetOrigin()-player:GetHMDAvatar():GetOrigin()))
                end
                StartSoundEvent("PortalPlayer.Enter",player)
                laspplayerteleport = GetFrameCount() + 50
            elseif laspplayerteleport- GetFrameCount() < 0 and PortalManager:CanTeleport(player, loopColor) and player:GetHMDAvatar() == nil then
                player:SetOrigin(player:GetOrigin()+Vector(0,0,10))
                PortalManager:teleport(player, loopColor)
                laspplayerteleport = GetFrameCount() + 10
            end
            local dir = ent:GetForwardVector()
            local org = ent:GetOrigin()
            
            local portableEnts = Entities:FindAllInSphere(org, detectRadius)
            if Debugging then
                DebugDrawLine(org, org + (dir * 10), 255, 0, 0, true, 1)
                --DebugDrawSphere(org, Vector(0, 0, 50), 10, detectRadius, true, 0.1)

                DebugDrawBoxDirection(org, mins, maxs,dir , Vector(255,0,0), 20, tickrate)
            end

            for _, portableEnt in pairs(portableEnts) do
                local classname = portableEnt:GetClassname()

                if portableEnt:GetOwner() then
                    local ownerentity = portableEnt:GetOwner():GetClassname()
                    if ownerentity == "player" or ownerentity == "hl_prop_vr_hand" or ownerentity == "prop_hmd_avatar" or ownerentity == "hl_vr_teleport_controller" then
                        return tickrate
                    end
                end

                if vlua.find(PortalWhitelist, classname) then
                    if PortalManager:CanTeleport(portableEnt, loopColor) then
                        print("Teleporting " .. portableEnt:GetClassname())
                        PortalManager:teleport(portableEnt, loopColor)
                    end
                end
            end
        end
    end

    return tickrate

end
--
function PortalManager:CanTeleport(ent, LoopColor)
    local org = PortalManager:GetConnectedPortal(LoopColor)
    if not org then
        return false
    end
    org = PortalManager:GetPortalGroup(LoopColor)[1]
    if org == nil then
        return false
    end

    local pos = PortalManager:getPosOnBounty(ent,org)
    local entMins = pos+ent:GetBoundingMins()
    local entMaxs = pos+ent:GetBoundingMaxs()

    --print(entMins)
    --print(entMaxs)
    --print("Portal:")
    --print(mins)
    --print(maxs)
    --print(LoopColor)
    --print("_____________")

    --calculate if v is inside mins and maxs

    return BBoxIntersect( entMins, entMaxs,mins,maxs )
end

function BBoxIntersect(mins1, maxs1, mins2, maxs2)
    local intersect = true
    for i = 1, 3, 1 do
        if mins1[i] > maxs2[i] or maxs1[i] < mins2[i] then
            intersect = false
        end
    end
    return intersect
end

function PortalManager:getPosOnBounty(ent, port)
    return port:TransformPointWorldToEntity(ent:GetOrigin())
end
function PortalManager:GetConnectedPortal(originalColor)
    local connectedPortal = nil
    if originalColor == Colors.Blue then
        connectedPortal = PortalManager:GetPortalGroup(Colors.Orange)[1]
    else
        connectedPortal = PortalManager:GetPortalGroup(Colors.Blue)[1]
    end
    return connectedPortal
end

function PortalManager:teleport(portableEnt, colorportal)
    local OriginalPortal = PortalManager:GetPortalGroup(colorportal)[1]
    local Portal = PortalManager:GetConnectedPortal(colorportal)
    local LocalPositionOnOriginalPortal = PortalManager:getPosOnBounty(portableEnt, OriginalPortal)
    local dir = Portal:GetForwardVector()
    -- Teleport from OriginalPortal to Portal but keep velocity and rotation of the entity with offset to keep it from constantly teleporting back and forth
    --+ (dir * 20 * (portableEnt:GetVelocity():Length() / 90))
    local newPos = Portal:GetOrigin()  +
                       (dir * LocalPositionOnOriginalPortal.x) + (dir * LocalPositionOnOriginalPortal.y) +
                       (dir * LocalPositionOnOriginalPortal.z)
    portableEnt:SetOrigin(Portal:TransformPointEntityToWorld(LocalPositionOnOriginalPortal+Vector(maxs.x,0,0)))

    -- Rotate Velocity to match the new direction
    local vel = GetPhysVelocity(portableEnt)
    local newVel = dir * vel:Length() * 0.95
    --local newAngles = VectorToAngles(Portal:TransformPointEntityToWorld(portableEnt:GetAnglesAsVector()))
    --portableEnt:SetAngles(-newAngles.x,-newAngles.y,-newAngles.z)
    portableEnt:ApplyAbsVelocityImpulse((-vel)+newVel-dir)
    if Debugging then
        DebugDrawLine(OriginalPortal:GetOrigin(), OriginalPortal:GetOrigin() + vel, 255, 0, 0, true, 10)
        DebugDrawLine(Portal:GetOrigin(), Portal:GetOrigin() + newVel, 0, 255, 0, true, 10)
        print(vel)
        print(newVel)
        print("___________")
    end
    if _G.PortalGun then
        if _G.PortalGun.PickedEntity == portableEnt then
            _G.PortalGun.PickedEntity = nil
        end
    end

    StartSoundEventFromPositionReliable("Portal.Enter",OriginalPortal:GetOrigin())
    StartSoundEventFromPositionReliable("Portal.Exit",Portal:GetOrigin())
    --local newVel = dir * vel:Length()
    --newVel = newVel - (dir * 20 * (portableEnt:GetVelocity():Length() / 90))

    --print("teleport")
end

function PortalManager:getPortal(colorportal)
    local Portal = PortalManager.ColorEnts[colorportal]
    return Portal
end
function PortalManager:GetPortalGroup(colorportal)
    if colorportal == Colors.Blue then
        return PortalManager.BluePortalGroup
    else
        return PortalManager.OrangePortalGroup
    end
end


function PortalManager:TryToCreatePortalAt(position, normal, colortype)
    local angles = VectorToAngles(normal)
    --print(position)
    --print(angles:Up()*portalz)
    local UpTrace = TraceDirection(position+angles:Forward()*10,angles:Up()*portalz/2)
    if not UpTrace.hit then
        UpTrace = TraceDirection(UpTrace.endpos,-angles:Forward()*30)
        if not UpTrace.hit then
            return false
        end
    else
        return false
    end
    local DownTrace = TraceDirection(position+angles:Forward()*10,(-angles:Up())*portalz/2)
    if not DownTrace.hit then
        
        DownTrace = TraceDirection(DownTrace.endpos,-angles:Forward()*30)
        if not DownTrace.hit then
            return false
        end
    else
        return false
    end
    local LeftTrace = TraceDirection(position+angles:Forward()*10,angles:Left()*portaly/2)
    if not LeftTrace.hit then
        LeftTrace = TraceDirection(LeftTrace.endpos,-angles:Forward()*30)
        --print(LeftTrace)
        if not LeftTrace.hit then
            return false
        end
    else
        return false
    end
    local RightTrace = TraceDirection(position+angles:Forward()*10,(-angles:Left())*portaly/2)
    if not RightTrace.hit then
        RightTrace = TraceDirection(RightTrace.endpos,-angles:Forward()*30)
        if not RightTrace.hit then
            return false
        end
    else
        return false
    end
    local otherPortal = PortalManager:GetConnectedPortal(colortype)
    if otherPortal ~= nil then
        local localPosition = otherPortal:TransformPointWorldToEntity(position)
        --print(localPosition)
        if abs(localPosition.y) < portaly  and abs(localPosition.z) < portalz and abs(localPosition.x) < 20 then
            return false
        end
    end

    PortalManager:CreatePortalAt(position,normal,colortype)
   
end
function TraceDirection(position,dir)
    local TraceTable = {
        startpos = position,
        endpos = position + dir,
        ignore = player,
    }
    TraceLine(TraceTable)
    if Debugging then
        if TraceTable.hit then
            DebugDrawLine(TraceTable.startpos,TraceTable.endpos,255,0,0,true,3)
        else
            DebugDrawLine(TraceTable.startpos,TraceTable.endpos,0,255,0,true,3)
        end
    end
    return TraceTable
end


function PortalManager:CreatePortalAt(position, normal, colortype)
    if colortype ~= Colors.Blue and colortype ~= Colors.Orange then
        return
    end
    if Entities:FindByName(nil, colortype .. "LogicScript") ~= nil then
        PortalManager:ClosePortal(colortype)
    end
    LightOmniTemplate.targetname = colortype .. "Portal_light_omni"
    local colorent = PortalManager.ColorEnts[colortype]:GetOrigin()
    LightOmniTemplate.color = (colorent.x * 255) .. " " .. (colorent.y * 255) .. " " .. (colorent.z * 255) .. " 255"
    local Light = SpawnEntityFromTableSynchronous("light_omni", LightOmniTemplate)
    AimatTemplate.targetname = colortype .. "Portal_aimat"
    AimatTemplate.origin = position
    AimatTemplate.angles = VectorToAngles(normal)
    local aimat = SpawnEntityFromTableSynchronous("point_aimat", AimatTemplate)
    aimat:SetForwardVector(normal)
    --DebugDrawLine(aimat:GetOrigin(), aimat:GetOrigin() + normal * 10, 255, 0, 0, true, 1)
    ParticleSystemTemplate.targetname = colortype .. "Portal_particles"
    ParticleSystemTemplate.cpoint5 = colortype .. "Portal"
    ParticleSystemTemplate.origin = position + normal*2.25
    ParticleSystemTemplate.angles = RotateOrientation(VectorToAngles(normal), QAngle(90, 0, 0))
    local particlesEnt = SpawnEntityFromTableSynchronous("info_particle_system", ParticleSystemTemplate)
    local particles = ParticleManager:CreateParticleForPlayer(ParticleSystemTemplate.effect_name, 1, particlesEnt,
        player)
    ParticleManager:SetParticleControl(particles, 5, PortalManager.ColorEnts[colortype]:GetOrigin())
    ViewPortalTemplate.targetname = colortype .. "Portalview"
    ViewPortalTemplate.angles = RotateOrientation(VectorToAngles(normal), QAngle(90, 0, 0))
    ViewPortalTemplate.skin = colortype
    local ViewPortal = SpawnEntityFromTableSynchronous("prop_dynamic", ViewPortalTemplate)
    ViewPortal:SetOrigin(position+normal)

    local teleportpoint = SpawnEntityFromTableSynchronous("point_teleport",{
        targetname = colortype .. "Portal_teleport",
        origin = aimat:GetOrigin() + normal * 50,
        target = "!player",
        teleport_parented_entities = "1",
    })

    LogicScriptTemplate.targetname = colortype .. "LogicScript"
    LogicScriptTemplate.Group00 = colortype .. "Portal_aimat"
    LogicScriptTemplate.Group01 = colortype .. "Portal_light_omni"
    LogicScriptTemplate.Group02 = colortype .. "Portal_particles"
    LogicScriptTemplate.Group03 = colortype .. "Portal_teleport"
    local logic = SpawnEntityFromTableSynchronous("logic_script", LogicScriptTemplate)

    if colortype == Colors.Blue then
        PortalManager.BluePortalGroup = {aimat, Light, particles, particlesEnt, logic,teleportpoint,ViewPortal}
    elseif colortype == Colors.Orange then
        PortalManager.OrangePortalGroup = {aimat, Light, particles, particlesEnt, logic,teleportpoint,ViewPortal}
    end

    if PortalManager.BluePortalGroup[1] and PortalManager.OrangePortalGroup[1] then
        PortalManager:CreateViewLink()
    else
        PortalManager:CloseViewLink()
    end

    PortalManager.Storage:SaveBoolean(colortype.."PortalActive", true)
    PortalManager.Storage:SaveVector(colortype.."PortalPos", position)
    PortalManager.Storage:SaveVector(colortype.."PortalNormal", normal)

    --print("GetPortalSaved"..tostring(PortalManager.Storage:LoadBoolean(colortype.."PortalActive")))
    --print("GetPortalSaved"..tostring(PortalManager.Storage:LoadVector(colortype.."PortalPos")))
    --print("GetPortalSaved"..tostring(PortalManager.Storage:LoadVector(colortype.."PortalNormal")))

end


function PortalManager:CreateViewLink()

    local BlueCamera = Entities:FindByName(nil,"@"..Colors.Blue .. "PointCamera")
    PortalManager.BlueCamera = BlueCamera
    local OrangeCamera = Entities:FindByName(nil,"@"..Colors.Orange .. "PointCamera")
    PortalManager.OrangeCamera = OrangeCamera
    local BluePortal = Entities:FindByName(nil,"@"..Colors.Blue .. "FuncMonitor")
    local OrangePortal = Entities:FindByName(nil,"@"..Colors.Orange .. "FuncMonitor")

    BluePortal:SetOrigin(PortalManager.BluePortalGroup[1]:GetOrigin()+ PortalManager.BluePortalGroup[1]:GetForwardVector()*2)
    OrangePortal:SetOrigin(PortalManager.OrangePortalGroup[1]:GetOrigin()+ PortalManager.OrangePortalGroup[1]:GetForwardVector()*2)
    
    local angles = VectorToAngles(-PortalManager.BluePortalGroup[1]:GetForwardVector())
    BluePortal:SetAngles(angles.x,angles.y,angles.z)

    angles = VectorToAngles(-PortalManager.OrangePortalGroup[1]:GetForwardVector())
    OrangePortal:SetAngles(angles.x,angles.y,angles.z)




    BlueCamera:SetOrigin(PortalManager.BluePortalGroup[1]:GetOrigin() + PortalManager.BluePortalGroup[1]:GetForwardVector() * -40)
    OrangeCamera:SetOrigin(PortalManager.OrangePortalGroup[1]:GetOrigin()+ PortalManager.OrangePortalGroup[1]:GetForwardVector() * -40)
    

    
    
    angles = VectorToAngles(PortalManager.BluePortalGroup[1]:GetForwardVector())
    BlueCamera:SetAngles(angles.x,angles.y,angles.z)

    angles = VectorToAngles(PortalManager.OrangePortalGroup[1]:GetForwardVector())
    OrangeCamera:SetAngles(angles.x,angles.y,angles.z)

    
    EntFire(BlueCamera,"@"..Colors.Blue .. "FuncMonitor","Enable")
    EntFire(OrangeCamera,"@"..Colors.Orange .. "FuncMonitor","Enable")

    --EntFireByHandle(thisEntity,PortalManager.OrangePortalGroup[7],"Disable")
    --EntFireByHandle(thisEntity,PortalManager.BluePortalGroup[7],"Disable")
end
function PortalManager:UpdateView()
    if PortalManager.BlueCamera == nil or PortalManager.OrangeCamera == nil or player == nil or PortalManager.BluePortalGroup[1] == nil or PortalManager.OrangePortalGroup[1] == nil then
        return tickrate
    end
    
    local BlueCamera = PortalManager.BlueCamera
    local OrangeCamera = PortalManager.OrangeCamera
    local BluePortal = PortalManager.BluePortalGroup[1]
    local OrangePortal = PortalManager.OrangePortalGroup[1]
    local Player = player

    local PlayerToBlue = OrangePortal:TransformPointWorldToEntity(player:EyePosition())
    local PlayerToBlueOrg = BluePortal:TransformPointEntityToWorld(-PlayerToBlue)
    local PlayerToOrange = BluePortal:TransformPointWorldToEntity(player:EyePosition())
    local PlayerToOrangeOrg = OrangePortal:TransformPointEntityToWorld(-PlayerToOrange)
    PlayerToOrange.z = PlayerToOrange.z * -1
    PlayerToBlue.z = PlayerToBlue.z * -1
    PlayerToBlue.x = Clamp(PlayerToBlue.x, 0, 40)
    PlayerToBlue.y = Clamp(PlayerToBlue.y/10, -15,15)
    PlayerToBlue.z = Clamp(PlayerToBlue.z/10, -10,10)

    PlayerToOrange.x = Clamp(PlayerToOrange.x, 0, 40)
    PlayerToOrange.y = Clamp(PlayerToOrange.y/10, -15, 15)
    PlayerToOrange.z = Clamp(PlayerToOrange.z/10, -10, 10)
    --print(PlayerToOrange)

    local OrangeCamPos = OrangePortal:TransformPointEntityToWorld(-PlayerToOrange)
    OrangeCamera:SetOrigin(OrangeCamPos)
    local BlueCamPos = BluePortal:TransformPointEntityToWorld(-PlayerToBlue)
    BlueCamera:SetOrigin(BlueCamPos)


    local angles = VectorToAngles(OrangePortal:TransformPointEntityToWorld(PlayerToOrange) - OrangePortal:GetOrigin())
    OrangeCamera:SetAngles(angles.x,angles.y,angles.z)

    angles = VectorToAngles(BluePortal:TransformPointEntityToWorld(PlayerToBlue) - BluePortal:GetOrigin())
    BlueCamera:SetAngles(angles.x,angles.y,angles.z)

    --the smaller x of PlayerToOrangeOrg is the higher the FOV is
    --1 meter is 100 units
    --local OrangeFOV = 300/abs(PlayerToOrangeOrg.x)
    --local BlueFOV =  300/abs(PlayerToBlueOrg.x)
    ----print(abs(PlayerToOrangeOrg.x))
    ----print(tostring(OrangeFOV))
    ----print(tostring(BlueFOV))
    --OrangeFOV = Lerp(Clamp(OrangeFOV-0.5,0,1),50, 90)
    --BlueFOV = Lerp(Clamp(BlueFOV-0.5,0,1), 50, 90)
--
    --local BlueCamFOV = Clamp(abs((1/PlayerToOrangeOrg:Length())*-0.1),10,180)
    --local OrangeCamFOV = Clamp(abs((1/PlayerToBlueOrg:Length())*-0.1),10,180)
--
    --EntFireByHandle(nil,BlueCamera,"ChangeFOV",tostring(BlueFOV))
    --EntFireByHandle(nil,OrangeCamera,"ChangeFOV",tostring(OrangeFOV))

   
--
    --print("_______")



    return tickrate
end

function PortalManager:CloseViewLink()
    local BlueCamera = Entities:FindByName(nil,"@"..Colors.Blue .. "PointCamera")
    local OrangeCamera = Entities:FindByName(nil,"@"..Colors.Orange .. "PointCamera")
    local BluePortal = Entities:FindByName(nil,"@"..Colors.Blue .. "FuncMonitor")
    local OrangePortal = Entities:FindByName(nil,"@"..Colors.Orange .. "FuncMonitor")
    BluePortal:SetOrigin(Vector(0,0,0))
    BluePortal:SetAngles(-90,0,0)
    OrangePortal:SetOrigin(Vector(0,0,0))
    OrangePortal:SetAngles(-90,0,0)
    EntFire(BlueCamera,"@"..Colors.Blue .. "FuncMonitor","Disable")
    EntFire(OrangeCamera,"@"..Colors.Orange .. "FuncMonitor","Disable")
    --EntFireByHandle(thisEntity,PortalManager.OrangePortalGroup[7],"Enable")
    --EntFireByHandle(thisEntity,PortalManager.BluePortalGroup[7],"Enable")
end



function PortalManager:ClosePortal(colortype)
    if colortype ~= Colors.Blue and colortype ~= Colors.Orange then
        return
    end
    if colortype == Colors.Blue and PortalManager.BluePortalGroup[1] ~= nil  then
        StartSoundEventFromPositionReliable("Portal.Close",PortalManager.BluePortalGroup[1]:GetOrigin())
        for key, value in pairs(PortalManager.BluePortalGroup) do
            if key == 3 then
                ParticleManager:DestroyParticle(PortalManager.BluePortalGroup[key], true)
            else
                PortalManager.BluePortalGroup[key]:Kill()
            end
            PortalManager.BluePortalGroup[key] = nil
        end
    elseif PortalManager.OrangePortalGroup[1] ~= nil then
        StartSoundEventFromPositionReliable("Portal.Close",PortalManager.OrangePortalGroup[1]:GetOrigin())
        for key, value in pairs(PortalManager.OrangePortalGroup) do
            if key == 3 then
                ParticleManager:DestroyParticle(PortalManager.OrangePortalGroup[key], true)
            else
                PortalManager.OrangePortalGroup[key]:Kill()
            end
            PortalManager.OrangePortalGroup[key] = nil
        end
    else
        return
    end
    PortalManager:CloseViewLink()
    Storage:SaveBoolean(colortype.."PortalActive", false)
end

currentPortal = Colors.Blue
pressedUse = false

function PlayerShoot()
    player = player or Entities:GetLocalPlayer()
    if player:GetHMDAvatar() then
        return
    end
    if player:IsUsePressed() and not pressedUse then
        pressedUse = true
        local traceTable = {
            startpos = player:EyePosition(),
            endpos = player:EyePosition() + player:GetForwardVector() * 1000,
            ignore = player
        }

        TraceLine(traceTable)
        if traceTable.hit then
            if currentPortal == Colors.Blue then
                EntFireByHandle(thisEntity,traceTable.enthit,"FireUser1")
            else
                EntFireByHandle(thisEntity,traceTable.enthit,"FireUser2")
            end
            if PortalManager.PortableFunc then
                if  traceTable.enthit:GetClassname() ~= "func_brush" then
                    return tickrate
                end
            else
                if  traceTable.enthit:GetClassname() == "func_brush" then
                    return tickrate
                end
            end
            
        
            if Debugging then
                DebugDrawLine(traceTable.startpos, traceTable.pos, 0, 255, 0, false, 1)
                DebugDrawLine(traceTable.pos, traceTable.pos + traceTable.normal * 10, 0, 0, 255, false, 1)
            end
            if currentPortal == Colors.Blue then
                currentPortal = Colors.Orange
            else
                currentPortal = Colors.Blue
            end
            if Debugging then
                print("Createing Portal Color:" .. currentPortal)
            end
            PortalManager:TryToCreatePortalAt(traceTable.pos, traceTable.normal, currentPortal)
        else
            if Debugging then
                DebugDrawLine(traceTable.startpos, traceTable.endpos, 255, 0, 0, false, 1)
            end
        end
    elseif not player:IsUsePressed() then
        pressedUse = false
    end
    return 0.1
end

function Activate(ActivateType)
    print("Portal Activated")
    if _G.PortalManager ~= nil then
        return
    end
    
    if ActivateType == 2  then
        print("Restoring Portals")
        thisEntity:SetThink(function ()
            if PortalManager.Storage:LoadBoolean("bluePortalActive") == true then
                Entities:FindByName(nil,Colors.Blue.."Portal_light_omni"):Destroy()
                Entities:FindByName(nil,Colors.Blue.."Portal_teleport"):Destroy()
                Entities:FindByName(nil,Colors.Blue.."LogicScript"):Destroy()
                Entities:FindByName(nil,Colors.Blue.."Portal_particles"):Destroy()
                Entities:FindByName(nil,Colors.Blue.."Portal_aimat"):Destroy()
                Entities:FindByName(nil,Colors.Blue.."Portalview"):Destroy()
                PortalManager:CreatePortalAt(PortalManager.Storage:LoadVector("bluePortalPos"),PortalManager.Storage:LoadVector("bluePortalNormal"),Colors.Blue)
            end
            if Storage:LoadBoolean("orangePortalActive") == true then
                Entities:FindByName(nil,Colors.Orange.."Portal_light_omni"):Destroy()
                Entities:FindByName(nil,Colors.Orange.."Portal_teleport"):Destroy()
                Entities:FindByName(nil,Colors.Orange.."LogicScript"):Destroy()
                Entities:FindByName(nil,Colors.Orange.."Portal_particles"):Destroy()
                Entities:FindByName(nil,Colors.Orange.."Portal_aimat"):Destroy()
                Entities:FindByName(nil,Colors.Orange.."Portalview"):Destroy()
                PortalManager:CreatePortalAt(PortalManager.Storage:LoadVector("orangePortalPos"),PortalManager.Storage:LoadVector("orangePortalNormal"),Colors.Orange)
            end
            PortalManager.PortableFuncs = PortalManager.Storage:LoadBoolean("PortableFunc")
        end,"restorg",0.2)
        
    end
    thisEntity:SetThink(function()
        return PortalManager:init()
    end, "flybyUpdater", 0.1)
    player = player or Entities:GetLocalPlayer()
    
    thisEntity:SetThink(function()
        return PlayerShoot()
    end, "shootUpdater", 1)
    thisEntity:SetThink(function()
        return PortalManager:UpdateView()
    end, "viewUpdater", 1)
    PortalManager.Storage = Storage
    _G.PortalManager =_G.PortalManager or PortalManager
    _G.Debugging = _G.Debugging or Debugging
end
function Precache(context)
    print("Portal Precache")
    PrecacheResource("particle", "particles/portal_effect_parent.vpcf", context)
    PrecacheResource("model", "models/vrportal/portalshape.vmdl", context)
end

function SpawnOrangePortal(args)
    if Debugging then
        print("Create Orange Portal")
        
    end
    local caller = args.caller
    PortalManager:CreatePortalAt(caller:GetOrigin(), caller:GetForwardVector(), Colors.Orange)
end
function SpawnBluePortal(args)
    if Debugging then
        print("Create Blue Portal")
        
    end
    local caller = args.caller
    PortalManager:CreatePortalAt(caller:GetOrigin(), caller:GetForwardVector(), Colors.Blue)
end

function SetFuncMode(args)
    if Debugging then
        print("Set Func Mode")
        
    end
    PortalManager.PortableFunc =  true
    Storage:SaveBoolean("PortableFunc", true)
end

function CloseAllPortals(args)
    PortalManager:ClosePortal(Colors.Blue)
    PortalManager:ClosePortal(Colors.Orange)
end
