local portalx = 35
local portaly = 75
local portalz = 20
local detectRadius = portaly

local tickrate = 0.05

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
Colors = {
    Blue = "blue",
    Orange = "orange"
}

PortalManager = _G.PortalManager or {

    ColorEnts = {},
    BluePortalGroup = {},
    OrangePortalGroup = {}
}

PortalGun = PortalGun or {}
