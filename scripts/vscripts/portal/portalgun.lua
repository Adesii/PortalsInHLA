tickrate = _G.tickrate or 0.05
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
    end, "portalguninit", 0.1)
    thisEntity:SetThink(function()
        return PortalGun:shoot()
    end, "portalgunshooting", 1)
end

function PortalGun:init()
    print("PortalGun init")
    PortalGun.BarrelParticleIndex = ParticleManager:CreateParticle("particles/portalgun_barrel.vpcf", 1, thisEntity)
    ParticleManager:SetParticleControlEnt(PortalGun.BarrelParticleIndex, 0, thisEntity, 1, "innerlaser",Vector(0, 0, 0), true)
    local player = player or Entities:GetLocalPlayer()
    PortalGun.Player = player
    PortalGun.HoldingHand = player:GetHMDAvatar():GetVRHand(1)
    --PortalGun.HoldingHand:AddHandAttachment(thisEntity)
    thisEntity:SetParent(PortalGun.HoldingHand:FirstMoveChild(), "grabbity_glove")
    thisEntity:SetLocalOrigin(Vector(5, 0, 0))
    thisEntity:SetLocalAngles(0,0,0)
    thisEntity:RegisterAnimTagListener(AnimGraphListener)
    thisEntity:SetOwner(player)

    PortalGun.entity = thisEntity

end

function PortalGun:shoot()
    
    if PortalGun.CanFire == false then
        return 0.1
    end
    if PortalGun.Player:IsDigitalActionOnForHand(0,PortalGun.BluePortalButton) then
        print("Blue Portal")
        PortalGun.entity:SetGraphParameterBool("bfired",true)
        PortalGun.MuzzleIndex = PortalGun.MuzzleIndex or thisEntity:ScriptLookupAttachment(PortalGun.MuzzleAttachment)
        local gunmuzzle = thisEntity:GetAttachmentOrigin(PortalGun.MuzzleIndex)
        local gunforward = thisEntity:GetAttachmentForward(PortalGun.MuzzleIndex)
        local traceTable = {
            startpos = gunmuzzle,
            endpos = gunmuzzle + gunforward * 1000,
            ignore = player
        }
        TraceLine(traceTable)
        if traceTable.hit then
            DebugDrawLine(traceTable.startpos, traceTable.pos, 0, 255, 0, false, 1)
            DebugDrawLine(traceTable.pos, traceTable.pos + traceTable.normal * 10, 0, 0, 255, false, 1)
            _G.PortalManager:CreatePortalAt(traceTable.pos, traceTable.normal, Colors.Blue)
        end
        
        PortalGun.CanFire = false
        PortalGun.HoldingHand:FireHapticPulse(1)
    end
    if PortalGun.Player:IsDigitalActionOnForHand(0,PortalGun.OrangePortalButton) then
        print("Orange Portal")
        PortalGun.entity:SetGraphParameterBool("bfired",true)
        PortalGun.MuzzleIndex = PortalGun.MuzzleIndex or thisEntity:ScriptLookupAttachment(PortalGun.MuzzleAttachment)
        local gunmuzzle = thisEntity:GetAttachmentOrigin(PortalGun.MuzzleIndex)
        local gunforward = thisEntity:GetAttachmentForward(PortalGun.MuzzleIndex)
        local traceTable = {
            startpos = gunmuzzle,
            endpos = gunmuzzle + gunforward * 1000,
            ignore = player
        }
        TraceLine(traceTable)
        if traceTable.hit then
            DebugDrawLine(traceTable.startpos, traceTable.pos, 0, 255, 0, false, 1)
            DebugDrawLine(traceTable.pos, traceTable.pos + traceTable.normal * 10, 0, 0, 255, false, 1)
            _G.PortalManager:CreatePortalAt(traceTable.pos, traceTable.normal, Colors.Orange)
        end

        
        PortalGun.CanFire = false
        PortalGun.HoldingHand:FireHapticPulse(1)
    end
    return 0.1
end


function AnimGraphListener(name,status)
    print("PortalGun AnimGraphListener")
    print(name,status)
    if name == "Fired" and status == 2 then
            print("PortalGun AnimGraphListener Fired")
            PortalGun.CanFire = true
    end
end
