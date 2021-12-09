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
    BlockFire = false,
    PickupRange = 100,
    
    PickedEntity = nil,
    SupendPickupFire = false,
    NotActive = false,

    CantFireBlue = false,
    CantFireOrange = false,

    MuzzleAttachment = "firebarrel",

    HoldingHand = {},
    Player = {},
}

PickupWhitelist = {
    "prop_physics",
    "func_physbox",
    "prop_physics_override",
    "prop_physics_interactive",
}

DoIncludeScript("portal/storage", thisEntity:GetPrivateScriptScope())

function Precache(context)
    print("Portalgun Precache")
    PrecacheResource("particle", "particles/portalgun_barrel.vpcf", context)
    PrecacheResource("particle", "particles/portalgun_light.vpcf", context)
end
function Activate(activateType)
    print("PortalGun Activated")
    if activateType == 2 then
        thisEntity:SetThink(function ()
            GunRestore()
            
        end,"restoregun",0.5)
        return
    end

    thisEntity:SetThink(function()
        return PortalGun:init()
    end, "portalguninit", 0.5)
    thisEntity:SetThink(function()
        return PortalGun:shoot()
    end, "portalgunshooting", 1.2)

    _G.PortalGun = PortalGun
end


function GunRestore()
    print("Restoring PortalGun")
    PortalGun.BlockFire = Storage:LoadBoolean("BlockFire")
    PortalGun.NotActive = Storage:LoadBoolean("NotActive")

    PortalGun.CantFireBlue = Storage:LoadBoolean("CantFireBlue")
    PortalGun.CantFireOrange = Storage:LoadBoolean("CantFireOrange")

    --print("Restored BlockFire: " .. tostring(PortalGun.BlockFire))
    --print("Restored NotActive: " .. tostring(PortalGun.NotActive))
    --print("Restored CantFireBlue: " .. tostring(PortalGun.CanFireBlue))
    --print("Restored CantFireOrange: " .. tostring(PortalGun.CanFireOrange))

    player = player or Entities:GetLocalPlayer()
    PortalGun.Player = player
    if not player:GetHMDAvatar() then
        return
    end
    PortalGun.Hand = player:GetHMDAvatar():GetVRHand(1)
    PortalGun.HoldingHand = player:GetHMDAvatar():GetVRHand(1):FirstMoveChild()
    PortalGun.entity = thisEntity

    thisEntity:RegisterAnimTagListener(AnimGraphListener)

    PortalGun.BarrelParticleIndex = ParticleManager:CreateParticle("particles/portalgun_barrel.vpcf", 1, thisEntity)
    PortalGun.LightParticleIndex = ParticleManager:CreateParticle("particles/portalgun_light.vpcf", 1, thisEntity)
    ParticleManager:SetParticleAlwaysSimulate(PortalGun.BarrelParticleIndex)
    ParticleManager:SetParticleAlwaysSimulate(PortalGun.LightParticleIndex)
    
    --ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,_G.PortalManager.ColorEnts[Colors.Blue]:GetOrigin())
    ParticleManager:SetParticleControlEnt(PortalGun.BarrelParticleIndex, 0,thisEntity,5,"innerlaser",Vector(0,0,0),true)
    ParticleManager:SetParticleControlEnt(PortalGun.BarrelParticleIndex, 1,thisEntity,5,"innerlaser_end",Vector(0,0,0),true)
    ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,Vector(0,0.4,1))
    ParticleManager:SetParticleControlEnt(PortalGun.LightParticleIndex, 0,thisEntity,5,"light",Vector(0,0,0),true)
    ParticleManager:SetParticleControl(PortalGun.LightParticleIndex, 5,Vector(0,0.4,1))

    ListenToGameEvent("weapon_switch",HandeWeaponSwitch,player)

    thisEntity:SetThink(function()
        return PortalGun:shoot()
    end, "portalgunshooting", 1.2)
    _G.PortalGun = PortalGun
end

function PortalGun:init()
    print("PortalGun init")
    local player = player or Entities:GetLocalPlayer()
    PortalGun.Player = player
    if not player:GetHMDAvatar() then
        return
    end
    PortalGun.Hand = player:GetHMDAvatar():GetVRHand(1)
    PortalGun.HoldingHand = player:GetHMDAvatar():GetVRHand(1):FirstMoveChild()
    --PortalGun.HoldingHand:AddHandAttachment(thisEntity)
    thisEntity:SetParent(PortalGun.HoldingHand, "hand_r")
    thisEntity:SetLocalOrigin(Vector(-7.5, -1, -2.2))
    thisEntity:SetLocalAngles(0,180,0)
    thisEntity:RegisterAnimTagListener(AnimGraphListener)
    thisEntity:SetOwner(player)

    PortalGun.entity = thisEntity


    --PortalGun.BarrelParticleSystem = SpawnEntityFromTableSynchronous("info_particle_system", {
    --    targetname = "portalgun_barrel",
    --    effect_name = "particles/portalgun_barrel.vpcf",
    --    cpoint0 = "portalgun",
    --})
    --
    --PortalGun.LightParticleSystem = SpawnEntityFromTableSynchronous("info_particle_system", {
    --    targetname = "portalgun_light",
    --    effect_name = "particles/portalgun_light.vpcf",
    --    cpoint0 = "portalgun",
    --})
    --PortalGun.LightParticleSystem:SetAbsOrigin(thisEntity:GetAbsOrigin())
    
    PortalGun.BarrelParticleIndex = ParticleManager:CreateParticle("particles/portalgun_barrel.vpcf", 1, thisEntity)
    PortalGun.LightParticleIndex = ParticleManager:CreateParticle("particles/portalgun_light.vpcf", 1, thisEntity)
    ParticleManager:SetParticleAlwaysSimulate(PortalGun.BarrelParticleIndex)
    ParticleManager:SetParticleAlwaysSimulate(PortalGun.LightParticleIndex)
    
    --ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,_G.PortalManager.ColorEnts[Colors.Blue]:GetOrigin())
    ParticleManager:SetParticleControlEnt(PortalGun.BarrelParticleIndex, 0,thisEntity,5,"innerlaser",Vector(0,0,0),true)
    ParticleManager:SetParticleControlEnt(PortalGun.BarrelParticleIndex, 1,thisEntity,5,"innerlaser_end",Vector(0,0,0),true)
    ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,Vector(0,0.4,1))
    ParticleManager:SetParticleControlEnt(PortalGun.LightParticleIndex, 0,thisEntity,5,"light",Vector(0,0,0),true)
    ParticleManager:SetParticleControl(PortalGun.LightParticleIndex, 5,Vector(0,0.4,1))

    ListenToGameEvent("weapon_switch",HandeWeaponSwitch,player)
end

function HandeWeaponSwitch(args,idk)
    --DeepPrintTable(idk)
    if idk["item"] ~= "hand_use_controller" then
        thisEntity:SetParent(nil,"")
        thisEntity:SetAbsOrigin(Vector(0,0,0))
        thisEntity:SetAbsAngles(0,0,0)
        PortalGun.NotActive = true
        Storage:SaveBoolean("NotActive",true)

    else
        thisEntity:SetParent(PortalGun.HoldingHand, "hand_r")
        thisEntity:SetLocalOrigin(Vector(-7.5, -1, -2.2))
        thisEntity:SetLocalAngles(15,180,0)
        thisEntity:SetOwner(player)

        StartSoundEvent("PortalGun.Equipped",thisEntity)
        
        PortalGun.NotActive = false
        Storage:SaveBoolean("NotActive",false)
    end

end
sincelastuse = 0
--The Portal Gun can pick things up similar to the Gravity Gun
function PortalGun:HandlePickupAbility()
    if player:GetAnalogActionPositionForHand(0,1).x > 0.5 and PortalGun.PickedEntity == nil  then
        PortalGun.MuzzleIndex = PortalGun.MuzzleIndex or thisEntity:ScriptLookupAttachment(PortalGun.MuzzleAttachment)
        local tracetable = {
            startpos = thisEntity:GetAttachmentOrigin(PortalGun.MuzzleIndex),
            endpos = thisEntity:GetAttachmentOrigin(PortalGun.MuzzleIndex) + PortalGun.entity:GetForwardVector() * PortalGun.PickupRange,
            ignore = thisEntity,
        }
        TraceLine(tracetable)
        if tracetable.hit and vlua.find(PickupWhitelist,tracetable.enthit:GetClassname()) then
            StartSoundEventFromPositionReliable("PortalGun.Use",thisEntity:GetAbsOrigin())
            StartSoundEvent("PortalGun.UseLoop",thisEntity)
            PortalGun.PickedEntity = tracetable.enthit
        else
            if sincelastuse < 0.2 then
                sincelastuse = sincelastuse + 0.1
            else
                StartSoundEventFromPositionReliable("PortalGun.UseFailed",thisEntity:GetAbsOrigin())
                sincelastuse = 0
            end
        end
        PortalGun.SupendPickupFire = true
    elseif player:GetAnalogActionPositionForHand(0,1).x < 0.5 and PortalGun.PickedEntity ~= nil then
        StopSoundEvent("PortalGun.UseLoop",player)
        PortalGun.PickedEntity = nil
        PortalGun.SupendPickupFire = false
    elseif PortalGun.PickedEntity ~= nil then
        local entity = PortalGun.PickedEntity
        if entity:IsNull() then
            return
        end
        local amountby = VectorDistance(thisEntity:GetOrigin(),entity:GetOrigin())/50
        local amount = math.min(amountby,2)
        local finalposition = (thisEntity:GetOrigin()+thisEntity:GetForwardVector()*100)
        if VectorDistance(finalposition,entity:GetOrigin()) < 25 then
            entity:ApplyAbsVelocityImpulse(-GetPhysVelocity(entity)/2)
        else
            entity:ApplyAbsVelocityImpulse((((finalposition-entity:GetOrigin()))*amount)-(GetPhysVelocity(entity)/5))
        end
    else
        PortalGun.SupendPickupFire = false
    end
end

sinceLastshot = 0
function PortalGun:shoot()
    
    if not player:GetHMDAvatar() then
        return 0.5
    end
    PortalGun:HandlePickupAbility()
    if PortalGun.CanFire == false and sinceLastshot < 1 then
        sinceLastshot = sinceLastshot + FrameTime()*5
        --print("Cant fire yet")
        --print(sinceLastshot)
    elseif sinceLastshot > 1 then
        sinceLastshot = 0
        PortalGun.CanFire = true
        --print("Can fire")
        --print(PortalGun.CanFire)
    end
    if PortalGun.CanFire == false or PortalGun.BlockFire == true or PortalGun.SupendPickupFire == true or PortalGun.NotActive == true then
        return 0.1
    end
    if PortalGun.Player:IsDigitalActionOnForHand(0,PortalGun.BluePortalButton) and PortalGun.CantFireBlue == false then
        PortalGun:FireGun(Colors.Blue)
    end
    if PortalGun.Player:IsDigitalActionOnForHand(0,PortalGun.OrangePortalButton) and PortalGun.CantFireOrange == false then
        PortalGun:FireGun(Colors.Orange)
    end
    return 0.1
end

function PortalGun:FireGun(Color)
    if Debugging then
        print(Color.." Portal")
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
        if Color == Colors.Blue then
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
        local pindex = ParticleManager:CreateParticle("particles/portalgun_shooting.vpcf", 1, thisEntity)
        ParticleManager:SetParticleControl(pindex, 0, gunmuzzle)
        ParticleManager:SetParticleControlForward(pindex, 1, gunforward)
        ParticleManager:SetParticleControl(pindex, 5, PortalManager.ColorEnts[Color]:GetOrigin())
        if Color == Colors.Blue then
            StartSoundEventFromPositionReliable("PortalGun.Shoot.Blue",gunmuzzle)
        else
            StartSoundEventFromPositionReliable("PortalGun.Shoot.Orange",gunmuzzle)
        end
        if Debugging then
            DebugDrawLine(traceTable.startpos, traceTable.endpos, 0, 255, 0, false, 1)
            DebugDrawLine(traceTable.pos, traceTable.endpos + traceTable.normal * 10, 0, 0, 255, false, 1)
        end
        if _G.PortalManager:TryToCreatePortalAt(traceTable.pos, traceTable.normal, Color) == false then
        else
            if Color == Colors.Blue then
                StartSoundEventFromPositionReliable("Portal.Open",traceTable.pos)
                StartSoundEventFromPositionReliable("Portal.Open.Blue",traceTable.pos)
            else
                StartSoundEventFromPositionReliable("Portal.Open",traceTable.pos)
                StartSoundEventFromPositionReliable("Portal.Open.Orange",traceTable.pos)
            end
        end
    else
        local pindex = ParticleManager:CreateParticle("particles/portalgun_shooting.vpcf", 1, thisEntity)
        ParticleManager:SetParticleControl(pindex, 0, gunmuzzle)
        ParticleManager:SetParticleControlForward(pindex, 1, gunforward)
        ParticleManager:SetParticleControl(pindex, 5, PortalManager.ColorEnts[Color]:GetOrigin())
        if Color == Colors.Blue then
            StartSoundEventFromPositionReliable("PortalGun.Shoot.Blue",gunmuzzle)
        else
            StartSoundEventFromPositionReliable("PortalGun.Shoot.Orange",gunmuzzle)
        end
    end

    
    PortalGun.CanFire = false
    PortalGun.Hand:FireHapticPulse(1)

    ParticleManager:SetParticleControl(PortalGun.BarrelParticleIndex, 5,_G.PortalManager.ColorEnts[Color]:GetOrigin())
    ParticleManager:SetParticleControl(PortalGun.LightParticleIndex, 5,_G.PortalManager.ColorEnts[Color]:GetOrigin())
    sinceLastshot = 0
end

function ActivatePortalGun()
    PortalGun.BlockFire = false
    Storage:SaveBoolean("BlockFire",false)
end
function DeactivatePortalGun()
    PortalGun.BlockFire = true
    Storage:SaveBoolean("BlockFire",true)
end
function EnableBluePortalGun()
    PortalGun.CantFireBlue = false
    Storage:SaveBoolean("CantFireBlue",false)
end
function DisableBluePortalGun()
    PortalGun.CantFireBlue = true
    Storage:SaveBoolean("CantFireBlue",true)
end
function EnableOrangePortalGun()
    PortalGun.CantFireOrange = false
    Storage:SaveBoolean("CantFireOrange",false)
end
function DisableOrangePortalGun()
    PortalGun.CantFireOrange = true
    Storage:SaveBoolean("CantFireOrange",true)
end



function AnimGraphListener(name,status)
    if name == "Fired" and status == 2 then
            --print("PortalGun AnimGraphListener Fired")
            PortalGun.CanFire = true
    end
end
