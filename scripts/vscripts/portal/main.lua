local portalx = 35
local portaly = 75
local portalz = 20
local detectRadius = portaly

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
Colors = _G.Colors or {
    Blue = "blue",
    Orange = "orange"
}

PortalManager = _G.PortalManager or {

    ColorEnts = {},
    BluePortalGroup = {},
    OrangePortalGroup = {}
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
                laspplayerteleport = GetFrameCount() + 100
            elseif laspplayerteleport- GetFrameCount() < 0 and PortalManager:CanTeleport(player, loopColor) and player:GetHMDAvatar() == nil then
                if loopColor == Colors.Blue then
                    player:SetAbsOrigin((PortalManager.OrangePortalGroup[1]:GetAbsOrigin()+PortalManager.OrangePortalGroup[1]:GetForwardVector()*30))
                else
                    player:SetAbsOrigin((PortalManager.BluePortalGroup[1]:GetAbsOrigin()+PortalManager.BluePortalGroup[1]:GetForwardVector()*30))
                end
                laspplayerteleport = GetFrameCount() + 100
            end
            local dir = ent:GetForwardVector()
            local org = ent:GetOrigin()
            local min = Vector(portalx / 2, portaly / 2, portalz / 2)
            local max = Vector(-(portalx / 2), -(portaly / 2), -(portalz / 2))
            local portableEnt = Entities:FindAllInSphere(org, detectRadius)
            if Debugging then
                DebugDrawLine(org, org + (dir * 10), 255, 0, 0, true, 1)
                DebugDrawSphere(org, Vector(0, 0, 50), 10, detectRadius, true, 0.1)
            end
            
            for key, value in pairs(portableEnt) do
                local classname = portableEnt[key]:GetClassname()
                    
                if portableEnt[key]:GetOwner() then
                    local ownerentity = portableEnt[key]:GetOwner():GetClassname()
                    if ownerentity == "player" or ownerentity == "hl_prop_vr_hand" or ownerentity == "prop_hmd_avatar" or ownerentity == "hl_vr_teleport_controller" then
                        return tickrate
                    end
                end

                for key, value in pairs(PortalWhitelist) do
                    if classname == value then
                        if PortalManager:CanTeleport(portableEnt[key], loopColor) then
                            if Debugging then
                                print("Teleporting " .. portableEnt[key]:GetClassname())
                            end
                            PortalManager:teleport(portableEnt[key], loopColor)
                        end
                    end
                end
            end
        end
    end

    return tickrate

end

function PortalManager:CanTeleport(ent, LoopColor)
    local org = PortalManager:GetConnectedPortal(LoopColor)
    if not org then
        return false
    end
    org = PortalManager:GetPortalGroup(LoopColor)[1]
    if org == nil then
        return false
    end

    local v = org:TransformPointWorldToEntity(ent:GetOrigin())

    if v.y < portalx and v.x < portalz and v.z < portaly then
        return true
    else
        return false
    end
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
    local newPos = Portal:GetOrigin() + (dir * 20 * (portableEnt:GetVelocity():Length() / 90)) +
                       (dir * LocalPositionOnOriginalPortal.x) + (dir * LocalPositionOnOriginalPortal.y) +
                       (dir * LocalPositionOnOriginalPortal.z)
    portableEnt:SetOrigin(newPos)

    -- Rotate Velocity to match the new direction
    local vel = portableEnt:GetVelocity()
    local newVel = dir * vel:Length()
    newVel = newVel - (dir * 20 * (portableEnt:GetVelocity():Length() / 90))
    portableEnt:SetVelocity(newVel)

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

function PortalManager:CreatePortalAt(position, normal, colortype)
    if colortype ~= Colors.Blue and colortype ~= Colors.Orange then
        return
    end
    if Entities:FindByName(nil, colortype .. "LogicScript") then
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
    --DebugDrawLine(aimat:GetOrigin(), aimat:GetOrigin() + normal * 10, 255, 0, 0, true, 1)
    ParticleSystemTemplate.targetname = colortype .. "Portal_particles"
    ParticleSystemTemplate.cpoint5 = colortype .. "Portal"
    ParticleSystemTemplate.origin = position + normal
    ParticleSystemTemplate.angles = RotateOrientation(VectorToAngles(normal), QAngle(90, 0, 0))
    local particlesEnt = SpawnEntityFromTableSynchronous("info_particle_system", ParticleSystemTemplate)
    local particles = ParticleManager:CreateParticleForPlayer(ParticleSystemTemplate.effect_name, 1, particlesEnt,
        player)
    ParticleManager:SetParticleControl(particles, 5, PortalManager.ColorEnts[colortype]:GetOrigin())

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
        PortalManager.BluePortalGroup = {aimat, Light, particles, particlesEnt, logic,teleportpoint}
    elseif colortype == Colors.Orange then
        PortalManager.OrangePortalGroup = {aimat, Light, particles, particlesEnt, logic,teleportpoint}
    end

    if Debugging then
        print("Portal Created")
        
    end

end

function PortalManager:ClosePortal(colortype)
    if colortype ~= Colors.Blue and colortype ~= Colors.Orange then
        return
    end
    if colortype == Colors.Blue then
        for key, value in pairs(PortalManager.BluePortalGroup) do
            if key == 3 then
                ParticleManager:DestroyParticle(PortalManager.BluePortalGroup[key], true)
            else
                PortalManager.BluePortalGroup[key]:Kill()
            end
            PortalManager.BluePortalGroup[key] = nil
        end
    else
        for key, value in pairs(PortalManager.OrangePortalGroup) do
            if key == 3 then
                ParticleManager:DestroyParticle(PortalManager.OrangePortalGroup[key], true)
            else
                PortalManager.OrangePortalGroup[key]:Kill()
            end
            PortalManager.OrangePortalGroup[key] = nil
        end
    end
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
            if traceTable.enthit:GetClassname() == "func_brush" then
                return tickrate
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
            PortalManager:CreatePortalAt(traceTable.pos, traceTable.normal, currentPortal)
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

function Activate()
    print("Portal Activated")
    thisEntity:SetThink(function()
        return PortalManager:init()
    end, "flybyUpdater", 0.1)
    player = player or Entities:GetLocalPlayer()
    
    thisEntity:SetThink(function()
        return PlayerShoot()
    end, "shootUpdater", 1)

    _G.PortalManager =_G.PortalManager or PortalManager
    _G.Debugging = _G.Debugging or Debugging
end
function Precache(context)
    print("Portal Precache")
    PrecacheResource("particle", "particles/portal_effect_parent.vpcf", context)
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

function CloseAllPortals(args)
    PortalManager:ClosePortal(Colors.Blue)
    PortalManager:ClosePortal(Colors.Orange)
end
