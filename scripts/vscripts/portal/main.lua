local portalx = 35
local portaly = 75
local portalz = 20
local detectRadius = portaly*2

local tickrate = 0.05

local velTable = {}

local LightOmniTemplate = {
    targetname = "bluePortal_light_omni",
    color = "15 121 148 255",
    brightness = "0.05",
	directlight = 2,
    indirectlight = 0,
    lightsourceradius = 30,
    baked_light_indexing = 0,
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
Colors ={
    Blue = "blue",
    Orange = "orange",
}

PortalManager = _G.PortalManager or {
    
    ColorEnts = {},
    BluePortalGroup = {},
    RedPortalGroup = {},
}





function PortalManager:init()
    PortalManager.ColorEnts = {
        [Colors.Orange] = Entities:FindByName(nil, "orangePortal"),
       [Colors.Blue] = Entities:FindByName(nil, "bluePortal"),
    }
    local rootEntity = Entities:FindAllByClassname("point_aimat")
    for i = 1, 4, 1 do
        local ent = rootEntity[i]
        --print(ent)
        if ent then
        local dir = ent:GetForwardVector()
        local org = ent:GetOrigin()
        local min = Vector(portalx/2,portaly/2,portalz/2)
        local max = Vector(-(portalx/2),-(portaly/2),-(portalz/2))
        local portableEnt=Entities:FindAllInSphere(org,detectRadius)
        --DebugDrawLine(org,org+(dir*10),255,0,0,true,1)
        for key, value in pairs(portableEnt) do
            if portableEnt[key]:GetClassname() ~= "info_particle_system" and portableEnt[key]:GetClassname() ~= "prop_static" and portableEnt[key]:GetClassname() ~= "light_omni" then
            if PortalManager:CanTeleport(portableEnt[key],ent) and vlua.contains(velTable,portableEnt[key]) then
                PortalManager:teleport(portableEnt[key],rootEntity,i)
            else
                velTable[portableEnt[key]] = portableEnt[key]:GetOrigin()
            end
        end
        end
        --DebugDrawBoxDirection(org,min,max,dir,Vector(0,0,255),20,0.1)
        --DebugDrawSphere(org,Vector(0,0,50),10,detectRadius,true,0.1)
        end
    end
    return tickrate

end

function PortalManager:CanTeleport(ent,port)
    local v = port:TransformPointWorldToEntity(ent:GetOrigin())
    if v.y < portalx and v.x <portalz and v.z < portaly then
        return true
    else
        return false
    end
end

function PortalManager:getPosOnBounty(ent,port)
    return port:TransformPointWorldToEntity(ent:GetOrigin())
end

function PortalManager:teleport(portableEnt,colorportal)
    local Portal = PortalManager:getPortal(colorportal)
    local pos = PortalManager:getPosOnBounty(portableEnt,Portal)
    portableEnt:SetOrigin(pos)
end    


function PortalManager:getPortal(colorportal)
    local Portal = PortalManager.ColorEnts[colorportal]
    return Portal
end


function PortalManager:CreatePortalAt(position,normal,colortype)
    if colortype ~= Colors.Blue and colortype ~= Colors.Orange then
        return
    end
    if Entities:FindByName(nil,colortype.."LogicScript") then
        PortalManager:ClosePortal(colortype)
    end
    LightOmniTemplate.targetname = colortype.."Portal_light_omni"
    local colorent =  PortalManager.ColorEnts[colortype]:GetOrigin()
    LightOmniTemplate.color = (colorent.x*255).." "..(colorent.y*255).." "..(colorent.z*255).." 255"
    local Light = SpawnEntityFromTableSynchronous("light_omni",LightOmniTemplate)
    AimatTemplate.targetname = colortype.."Portal_aimat"
    AimatTemplate.origin = position
    AimatTemplate.angles = VectorToAngles(normal)
    local aimat = SpawnEntityFromTableSynchronous("point_aimat",AimatTemplate)
    DebugDrawLine(aimat:GetOrigin(),aimat:GetOrigin()+normal*10,255,0,0,true,1)
    ParticleSystemTemplate.targetname = colortype.."Portal_particles"
    ParticleSystemTemplate.cpoint5 = colortype.."Portal"
    ParticleSystemTemplate.origin = position + normal
    ParticleSystemTemplate.angles = RotateOrientation(VectorToAngles(normal),QAngle(90,0,0))
    local particlesEnt = SpawnEntityFromTableSynchronous("info_particle_system",ParticleSystemTemplate)
    local particles = ParticleManager:CreateParticleForPlayer(ParticleSystemTemplate.effect_name,1,particlesEnt,player)
    ParticleManager:SetParticleControl(particles,5,PortalManager.ColorEnts[colortype]:GetOrigin())

    local projectedTexture = "materials/portal/portal_"..colortype..".vmat"

    LogicScriptTemplate.targetname = colortype.."LogicScript"
    LogicScriptTemplate.Group00 = colortype.."Portal_aimat"
    LogicScriptTemplate.Group01 = colortype.."Portal_light_omni"
    LogicScriptTemplate.Group02 = colortype.."Portal_particles"
    local logic = SpawnEntityFromTableSynchronous("logic_script",LogicScriptTemplate)

    if particles then
        print("particles created")
    end

    if colortype == Colors.Blue then
        PortalManager.BluePortalGroup = {
            Light,
            aimat,
            particles,
            particlesEnt,
            logic
        }
    elseif colortype == Colors.Orange then
        PortalManager.OrangePortalGroup = {
            Light,
            aimat,
            particles,
            particlesEnt,
            logic
        }
    end

    print("Portal Created")


end


function PortalManager:ClosePortal(colortype)
    if colortype ~= Colors.Blue and colortype ~= Colors.Orange then
        return
    end
    if colortype == Colors.Blue then
        for key, value in pairs(PortalManager.BluePortalGroup) do
            if key == 3 then
                ParticleManager:DestroyParticle(PortalManager.BluePortalGroup[key],true)
            else
                PortalManager.BluePortalGroup[key]:Kill()
            end
        end
    else
        for key, value in pairs(PortalManager.OrangePortalGroup) do
            if key == 3 then
                ParticleManager:DestroyParticle(PortalManager.OrangePortalGroup[key],true)

            else
                PortalManager.OrangePortalGroup[key]:Kill()
            end
        end
    end
end

currentPortal = Colors.Blue

function PlayerShoot()
    player = player or GetListenServerHost()
    if player:IsUsePressed() then
        local traceTable ={
            startpos = player:EyePosition(),
            endpos = player:EyePosition()+player:GetForwardVector()*1000,
            ignore = player,
        }
        TraceLine(traceTable)
        if traceTable.hit 
        then
        	DebugDrawLine(traceTable.startpos, traceTable.pos, 0, 255, 0, false, 1)
        	DebugDrawLine(traceTable.pos, traceTable.pos + traceTable.normal * 10, 0, 0, 255, false, 1)
            if currentPortal == Colors.Blue then
                currentPortal = Colors.Orange
            else
                currentPortal = Colors.Blue
            end
            print("Createing Portal Color:"..currentPortal)
            PortalManager:CreatePortalAt(traceTable.pos,traceTable.normal,currentPortal)
        else
        	DebugDrawLine(traceTable.startpos, traceTable.endpos, 255, 0, 0, false, 1)
        end
        
    end
    return 0.1
end
















function Activate()
    print("Portal Activated")
    thisEntity:SetThink(function() return PortalManager:init() end,"flybyUpdater",0.5)
    thisEntity:SetThink(function() return PlayerShoot() end,"shootUpdater",2)
end
function Precache(context)
    print("Portal Precache")
    PrecacheResource("particle", "particles/portal_effect_parent.vpcf", context)
end
function Spawn()
    print("Portal Spawn")
end

