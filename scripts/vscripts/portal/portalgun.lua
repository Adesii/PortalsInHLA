tickrate = _G.tickrate or 0.05
Debugging = _G.Debugging or false
Colors = _G.Colors or {
    Blue = "blue",
    Orange = "orange"
}
PortalGun = _G.PortalGun or {
    entity = nil,
    BluePortalButton = 16,
    OrangePortalButton = 9,
    PickupTrigger = 1,
    CanFire = true,
    SupendFire = false,

    MuzzleAttachment = "firebarrel",

    HoldingHand = {},
    Player = {},
}

function Precache(context)
    print("Portalgun Precache")
    PrecacheResource("particle", "particles/portalgun_barrel.vpcf", context)
    PrecacheResource("particle", "particles/portalgun_light.vpcf", context)
end
function Activate()
    print("PortalGun Activated")
    thisEntity:SetThink(function()
        return PortalGun:init()
    end, "portalguninit", 0.5)
    thisEntity:SetThink(function()
        return PortalGun:shoot()
    end, "portalgunshooting", 1.2)
end

function PortalGun:init()
    print("PortalGun init")
    local player = player or Entities:GetLocalPlayer()
    PortalGun.Player = player
    if not player:GetHMDAvatar() then
        return
    end
    PortalGun.HoldingHand = player:GetHMDAvatar():GetVRHand(1)
    --PortalGun.HoldingHand:AddHandAttachment(thisEntity)
    thisEntity:SetParent(PortalGun.HoldingHand:FirstMoveChild(), "grabbity_glove")
    thisEntity:SetLocalOrigin(Vector(5, 0, 0))
    thisEntity:SetLocalAngles(0,0,0)
    thisEntity:RegisterAnimTagListener(AnimGraphListener)
    thisEntity:SetOwner(player)

    PortalGun.entity = thisEntity


    PortalGun.BarrelParticleSystem = SpawnEntityFromTableSynchronous("info_particle_system", {
        targetname = "portalgun_barrel",
        effect_name = "particles/portalgun_barrel.vpcf",
        cpoint0 = "portalgun",
    })
    
    PortalGun.LightParticleSystem = SpawnEntityFromTableSynchronous("info_particle_system", {
        targetname = "portalgun_light",
        effect_name = "particles/portalgun_light.vpcf",
        cpoint0 = "portalgun",
    })
    --PortalGun.LightParticleSystem:SetAbsOrigin(thisEntity:GetAbsOrigin())
    
    PortalGun.BarrelParticleIndex = ParticleManager:CreateParticleForPlayer("particles/portalgun_barrel.vpcf", 1, PortalGun.BarrelParticleSystem,player)
    PortalGun.LightParticleIndex = ParticleManager:CreateParticleForPlayer("particles/portalgun_light.vpcf", 1, PortalGun.LightParticleSystem,player)
    ParticleManager:SetParticleAlwaysSimulate(PortalGun.BarrelParticleIndex)
    ParticleManager:SetParticleAlwaysSimulate(PortalGun.LightParticleIndex)
    
    --ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,_G.PortalManager.ColorEnts[Colors.Blue]:GetOrigin())
    ParticleManager:SetParticleControlEnt(PortalGun.BarrelParticleIndex, 0,PortalGun.entity,5,"innerlaser",Vector(0,0,0),true)
    ParticleManager:SetParticleControlEnt(PortalGun.BarrelParticleIndex, 1,PortalGun.entity,5,"innerlaser_end",Vector(0,0,0),true)
    ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,Vector(0,0.4,1))
    ParticleManager:SetParticleControlEnt(PortalGun.LightParticleIndex, 0,PortalGun.entity,5,"light",Vector(0,0,0),true)
    ParticleManager:SetParticleControl(PortalGun.LightParticleIndex, 5,Vector(0,0.4,1))

end

function PortalGun:shoot()
    
    if not player:GetHMDAvatar() then
        return 0.5
    end
    if PortalGun.CanFire == false or PortalGun.SupendFire == true then
        return 0.1
    end
    if PortalGun.Player:IsDigitalActionOnForHand(0,PortalGun.BluePortalButton) then
        if Debugging then
            print("Blue Portal")
        end
        PortalGun.entity:SetGraphParameterBool("bfired",true)
        PortalGun.MuzzleIndex = PortalGun.MuzzleIndex or thisEntity:ScriptLookupAttachment(PortalGun.MuzzleAttachment)
        local gunmuzzle = thisEntity:GetAttachmentOrigin(PortalGun.MuzzleIndex)
        local gunforward = thisEntity:GetAttachmentForward(PortalGun.MuzzleIndex)
        local traceTable = {
            startpos = gunmuzzle,
            endpos = gunmuzzle + gunforward * 10000,
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
            _G.PortalManager:CreatePortalAt(traceTable.pos, traceTable.normal, Colors.Blue)
        end
        
        PortalGun.CanFire = false
        PortalGun.HoldingHand:FireHapticPulse(1)

        ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,_G.PortalManager.ColorEnts[Colors.Blue]:GetOrigin())
        ParticleManager:SetParticleControl(PortalGun.LightParticleIndex, 5,_G.PortalManager.ColorEnts[Colors.Blue]:GetOrigin())
    end
    if PortalGun.Player:IsDigitalActionOnForHand(0,PortalGun.OrangePortalButton) then
        if Debugging then
            print("Orange Portal")
        end
        PortalGun.entity:SetGraphParameterBool("bfired",true)
        PortalGun.MuzzleIndex = PortalGun.MuzzleIndex or thisEntity:ScriptLookupAttachment(PortalGun.MuzzleAttachment)
        local gunmuzzle = thisEntity:GetAttachmentOrigin(PortalGun.MuzzleIndex)
        local gunforward = thisEntity:GetAttachmentForward(PortalGun.MuzzleIndex)
        local traceTable = {
            startpos = gunmuzzle,
            endpos = gunmuzzle + gunforward * 10000,
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
            _G.PortalManager:CreatePortalAt(traceTable.pos, traceTable.normal, Colors.Orange)
        end

        
        PortalGun.CanFire = false
        PortalGun.HoldingHand:FireHapticPulse(1)

        ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,_G.PortalManager.ColorEnts[Colors.Orange]:GetOrigin())
        ParticleManager:SetParticleControl(PortalGun.LightParticleIndex, 5,_G.PortalManager.ColorEnts[Colors.Orange]:GetOrigin())
    end
    return 0.1
end

function ActivatePortalGun()
    PortalGun.SupendFire = false
end
function DeactivatePortalGun()
    PortalGun.SupendFire = true
end



function AnimGraphListener(name,status)
    if name == "Fired" and status == 2 then
            --print("PortalGun AnimGraphListener Fired")
            PortalGun.CanFire = true
    end
end
