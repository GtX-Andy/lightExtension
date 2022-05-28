--[[
Copyright (C) GtX (Andy), 2018

Author: GtX | Andy
Date: 17.12.2018
Revision: FS22-04

Contact:
https://forum.giants-software.com
https://github.com/GtX-Andy

Thankyou:
Sven777b @ http://ls-landtechnik.com    -   Allowing me to use parts of his strobe light code as found in ‘Beleuchtung v3.1.1’.
Inerti and Nicolina                     -   FS17 suggestions, testing in single and multiplayer.

Important:
Free for use in mods (FS22 Only) - no permission needed.
No modifications may be made to this script, including conversion to other game versions without written permission from GtX | Andy

Frei verwendbar (Nur LS22) - keine erlaubnis nötig
Ohne schriftliche Genehmigung von GtX | Andy dürfen keine Änderungen an diesem Skript vorgenommen werden, einschließlich der Konvertierung in andere Spielversionen
]]


LightExtension = {}

LightExtension.MOD_NAME = g_currentModName
LightExtension.SPEC_NAME = string.format("spec_%s.lightExtension", g_currentModName)

LightExtension.strobeLightXMLSchema = nil
LightExtension.runningLightXMLSchema = nil

LightExtension.stepCharacters = {
    ["X"] = "ON",
    ["-"] = "OFF"
}

function LightExtension.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Lights, specializations)
end

function LightExtension.initSpecialization()
    local schema = Vehicle.xmlSchema

    schema:setXMLSpecializationType("LightExtension")

    schema:register(XMLValueType.STRING, "vehicle.lightExtension.strobeLights.strobeLight(?)#filename", "Strobe light XML file")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.strobeLights.strobeLight(?)#linkNode", "Shared I3d link node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.strobeLights.strobeLight(?)#node", "Visibility toggle node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.strobeLights.strobeLight(?)#shaderNode", "Light control shader node")
    schema:register(XMLValueType.FLOAT, "vehicle.lightExtension.strobeLights.strobeLight(?)#realLightRange", "Factor that is applied on real light range of the strobe light", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.strobeLights.strobeLight(?)#realLightNode", "Real light node. Only required if shared i3d does not include it or light is part of vehicle")
    schema:register(XMLValueType.INT, "vehicle.lightExtension.strobeLights.strobeLight(?)#intensity", "Strobe light intensity override or base value when light shader is part of vehicle")

    schema:register(XMLValueType.STRING, "vehicle.lightExtension.strobeLights.strobeLight(?)#blinkPattern", "Uses a string of X and - characters to define the sequence times, X represents ON state and - represents OFF state for the given 'blinkStepLength'.")
    schema:register(XMLValueType.FLOAT, "vehicle.lightExtension.strobeLights.strobeLight(?)#blinkStepLength", "A float value representing the duration of one step inside blink pattern in seconds.", 0.5)

    schema:register(XMLValueType.STRING, "vehicle.lightExtension.strobeLights.strobeLight(?)#sequence", "When 'blinkPattern' is not used then a string of millisecond values each separated with a space are used to create an alternating light sequence.")
    schema:register(XMLValueType.BOOL, "vehicle.lightExtension.strobeLights.strobeLight(?)#invert", "Invert the sequence. When true the first ms value will represent OFF.", false)
    schema:register(XMLValueType.INT, "vehicle.lightExtension.strobeLights.strobeLight(?)#minOn", "The minimum 'ON' time in ms used to randomise if no sequence is given", 100)
    schema:register(XMLValueType.INT, "vehicle.lightExtension.strobeLights.strobeLight(?)#maxOn", "The maximum 'ON' time in ms used to randomise if no sequence is given", 100)
    schema:register(XMLValueType.INT, "vehicle.lightExtension.strobeLights.strobeLight(?)#minOff", "The minimum 'OFF' time in ms used to randomise if no sequence is given", 100)
    schema:register(XMLValueType.INT, "vehicle.lightExtension.strobeLights.strobeLight(?)#maxOff", "The maximum 'OFF' time in ms used to randomise if no sequence is given", 400)

    schema:register(XMLValueType.STRING, "vehicle.lightExtension.runningLights.runningLight(?)#filename", "Running / DRL light XML file")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.runningLights.runningLight(?)#linkNode", "Shared I3d link node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.runningLights.runningLight(?)#node", "Visibility toggle node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.runningLights.runningLight(?)#shaderNode", "Light control shader node")
    schema:register(XMLValueType.FLOAT, "vehicle.lightExtension.runningLights.runningLight(?)#realLightRange", "Factor that is applied on real light range of the strobe light", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.lightExtension.runningLights.runningLight(?)#realLightNode", "Real light node. Only required if shared i3d does not include it or light is part of vehicle")
    schema:register(XMLValueType.INT, "vehicle.lightExtension.runningLights.runningLight(?)#intensity", "Running / DRL light intensity override or base value when light shader is part of vehicle")

    SoundManager.registerSampleXMLPaths(schema, "vehicle.lightExtension", "beaconSound")
    schema:register(XMLValueType.FLOAT, "vehicle.lightExtension.autoCombineBeaconLights#percent", "The percentage when the beacon lights should be activated & deactivated when operated by a player")

    schema:setXMLSpecializationType()

    local strobeLightXMLSchema = XMLSchema.new("sharedStrobeLight")

    strobeLightXMLSchema:register(XMLValueType.STRING, "lightExtensionShared.strobeLight.filename", "Path to i3d file", nil, true)
    strobeLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.strobeLight.rootNode#node", "Root node", nil, true)
    strobeLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.strobeLight.light#node", "Visibility toggle node")
    strobeLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.strobeLight.light#shaderNode", "Light control shader node")
    strobeLightXMLSchema:register(XMLValueType.FLOAT, "lightExtensionShared.strobeLight.light#intensity", "Light intensity of shader node", 100)
    strobeLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.strobeLight.realLight#node", "Real light source node")

    LightExtension.strobeLightXMLSchema = strobeLightXMLSchema

    local runningLightXMLSchema = XMLSchema.new("sharedRunningLight")

    runningLightXMLSchema:register(XMLValueType.STRING, "lightExtensionShared.runningLight.filename", "Path to i3d file", nil, true)
    runningLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.runningLight.rootNode#node", "Root node", nil, true)
    runningLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.runningLight.light#node", "Visibility toggle node")
    runningLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.runningLight.light#shaderNode", "Light control shader node")
    runningLightXMLSchema:register(XMLValueType.FLOAT, "lightExtensionShared.runningLight.light#intensity", "Light intensity of shader node", 100)
    runningLightXMLSchema:register(XMLValueType.NODE_INDEX, "lightExtensionShared.runningLight.realLight#node", "Real light source node")

    LightExtension.runningLightXMLSchema = runningLightXMLSchema
end

function LightExtension.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadLightExtensionLightFromXML", LightExtension.loadLightExtensionLightFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadLightExtensionLightStrobeDataFromXML", LightExtension.loadLightExtensionLightStrobeDataFromXML)
    SpecializationUtil.registerFunction(vehicleType, "setLightExtensionLightData", LightExtension.setLightExtensionLightData)
    SpecializationUtil.registerFunction(vehicleType, "onLightExtensionLightI3DLoaded", LightExtension.onLightExtensionLightI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "setRunningLightsState", LightExtension.setRunningLightsState)
end

function LightExtension.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onBeaconLightsVisibilityChanged", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onStartMotor", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onStopMotor", LightExtension)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", LightExtension)
end

function LightExtension:onLoad(savegame)
    self.spec_lightExtension = self[LightExtension.SPEC_NAME]

    if self.spec_lightExtension == nil then
        Logging.error("[%s] Specialization with name 'lightExtension' was not found in modDesc!", LightExtension.MOD_NAME)
    end

    local spec = self.spec_lightExtension

    spec.xmlLoadingHandles = {}
    spec.sharedLoadRequestIds = {}

    spec.runningLights = {}
    spec.strobeLights = {}

    spec.runningLightsActive = false
    spec.strobeLightsActive = false
    spec.strobeLightsNeedReset = false

    -- This can be achieved with Dashboard in 22 but this allows easy conversion
    self.xmlFile:iterate("vehicle.lightExtension.runningLights.runningLight", function (_, key)
        self:loadLightExtensionLightFromXML(self.xmlFile, key, "lightExtensionShared.runningLight", false)
    end)

    -- A flexible strobe light system allowing for random sequences or ms sequences or patterns using X (ON) and - (OFF).
    self.xmlFile:iterate("vehicle.lightExtension.strobeLights.strobeLight", function (_, key)
        self:loadLightExtensionLightFromXML(self.xmlFile, key, "lightExtensionShared.strobeLight", true)
    end)

    -- Plays a sample when beacons are active, maybe a police siren or similar
    local beaconSoundSample = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lightExtension", "beaconSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)

    if beaconSoundSample ~= nil then
        spec.beaconSound = {
            sample = beaconSoundSample,
            isActive = false
        }
    end

    -- No need for sounds in 22 as you can use the 'FillUnit.alarmTrigger' function. This now just toggles beacons
    local percent = self.xmlFile:getValue("vehicle.lightExtension.autoCombineBeaconLights#percent")

    if percent ~= nil then
        if (self.spec_combine ~= nil and self.spec_pipe ~= nil) and self.spec_fillUnit ~= nil then
            spec.autoCombineBeaconLights = {
                percent = MathUtil.clamp(percent * 0.01, 0.01, 1),
                active = false
            }
        else
            Logging.xmlWarning(self.xmlFile, "Auto combine beacon lights is only for use on combines and requires the 'fillUnit', 'combine' and 'pipe' specializations.")
        end
    end
end

function LightExtension:onLoadFinished(savegame)
    local spec = self.spec_lightExtension

    spec.hasRealStrobeLights = g_gameSettings:getValue("realBeaconLights")

    spec.hasRunningLights = #spec.runningLights > 0
    spec.hasStrobeLights = #spec.strobeLights > 0

    spec.hasAutoCombineBeaconLights = spec.autoCombineBeaconLights ~= nil
end

function LightExtension:onDelete()
    local spec = self.spec_lightExtension

    spec.hasRunningLights = false
    spec.hasStrobeLights = false
    spec.hasAutoCombineBeaconLights = false

    if spec.xmlLoadingHandles ~= nil then
        for lightXMLFile, _ in pairs(spec.xmlLoadingHandles) do
            lightXMLFile:delete()

            spec.xmlLoadingHandles[lightXMLFile] = nil
        end

        spec.xmlLoadingHandles = nil
    end

    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end

        spec.sharedLoadRequestIds = nil
    end

    if spec.beaconSound ~= nil then
        g_soundManager:deleteSample(spec.beaconSound.sample)

        spec.beaconSound = nil
    end
end

function LightExtension:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_lightExtension

    if self.isClient and spec.hasStrobeLights then
        if spec.strobeLightsActive then
            spec.strobeLightsNeedReset = true

            for i, light in ipairs(spec.strobeLights) do
                if light.time >= light.sequenceTime then
                    light.active = not light.active

                    if light.lightNode ~= nil then
                        setVisibility(light.lightNode, light.active)
                    end

                    if light.lightShaderNode ~= nil then
                        local intensity = light.active and (1 * light.intensity) or 0
                        local _, y, z, w = getShaderParameter(light.lightShaderNode, "lightControl")

                        setShaderParameter(light.lightShaderNode, "lightControl", intensity, y, z, w, false)
                    end

                    if spec.hasRealStrobeLights and light.realLightNode ~= nil then
                        setVisibility(light.realLightNode, light.active)
                    end

                    if light.isRandom then
                        if light.active then
                            light.sequenceTime = math.random(light.minOn, light.maxOn)
                        else
                            light.sequenceTime = math.random(light.minOff, light.maxOff)
                        end
                    else
                        light.sequenceTime = light.sequence[light.index]

                        light.index = light.index + 1

                        if light.index > light.sequenceCount then
                            light.index = 1
                        end
                    end

                    light.time = 0
                else
                    light.time = light.time + dt
                end
            end

            self:raiseActive()
        else
            if spec.strobeLightsNeedReset then
                for i = 1, #spec.strobeLights do
                    local light = spec.strobeLights[i]

                    if light.lightNode ~= nil then
                        setVisibility(light.lightNode, false)
                    end

                    if light.lightShaderNode ~= nil then
                        local _, y, z, w = getShaderParameter(light.lightShaderNode, "lightControl")
                        setShaderParameter(light.lightShaderNode, "lightControl", 0, y, z, w, false)
                    end

                    if spec.hasRealStrobeLights and light.realLightNode ~= nil then
                        setVisibility(light.realLightNode, false)
                    end

                    if not light.isRandom then
                        light.index = 1
                        light.active = light.invert

                        light.time = math.huge
                        light.sequenceTime = 0
                    end
                end

                spec.strobeLightsNeedReset = false
            end
        end
    end

    if spec.hasAutoCombineBeaconLights and not self:getIsAIActive() then
        local fillLevel, capacity = 0, 0
        local dischargeNode = self:getCurrentDischargeNode()

        if dischargeNode ~= nil then
            fillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
            capacity = self:getFillUnitCapacity(dischargeNode.fillUnitIndex)
        end

        if fillLevel > spec.autoCombineBeaconLights.percent * capacity then
            if not spec.autoCombineBeaconLights.active then
                self:setBeaconLightsVisibility(true)
                spec.autoCombineBeaconLights.active = true
            end
        else
            if spec.autoCombineBeaconLights.active then
                self:setBeaconLightsVisibility(false)
                spec.autoCombineBeaconLights.active = false
            end
        end
    end
end

function LightExtension:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_lightExtension

    if self.isClient and spec.hasRunningLights then
        local rootVehicle = self:getRootVehicle()

        if rootVehicle ~= nil and rootVehicle.getIsMotorStarted ~= nil then
            local runningLightsActive = rootVehicle:getIsMotorStarted()

            if runningLightsActive ~= spec.runningLightsActive then
                self:setRunningLightsState(runningLightsActive)
            end
        else
            if spec.runningLightsActive then
                self:setRunningLightsState(false)
            end
        end
    end
end

function LightExtension:onBeaconLightsVisibilityChanged(visibility)
    local spec = self.spec_lightExtension

    spec.strobeLightsActive = Utils.getNoNil(visibility, false)

    if self.isClient and spec.beaconSound ~= nil then
        spec.beaconSound.isActive = spec.strobeLightsActive

        if spec.beaconSound.isActive then
            g_soundManager:playSample(spec.beaconSound.sample)
        else
            g_soundManager:stopSample(spec.beaconSound.sample)
        end
    end

    self:raiseActive()
end

function LightExtension:onStartMotor()
    self:setRunningLightsState(true)
end

function LightExtension:onStopMotor()
    self:setRunningLightsState(false)
end

function LightExtension:onPostDetach()
    self:setRunningLightsState(false)
end

function LightExtension:setRunningLightsState(isActive)
    local spec = self.spec_lightExtension

    spec.runningLightsActive = Utils.getNoNil(isActive, false)

    if self.isClient and spec.hasRunningLights then
        for _, light in ipairs(spec.runningLights) do
            if light.lightNode ~= nil then
                setVisibility(light.lightNode, isActive)
            end

            if light.lightShaderNode ~= nil then
                local intensity = isActive and (1 * light.intensity) or 0
                local _, y, z, w = getShaderParameter(light.lightShaderNode, "lightControl")

                setShaderParameter(light.lightShaderNode, "lightControl", intensity, y, z, w, false)
            end

            if spec.hasRealStrobeLights and light.realLightNode ~= nil then
                setVisibility(light.realLightNode, isActive)
            end
        end
    end
end

function LightExtension:loadLightExtensionLightFromXML(xmlFile, key, sharedKey, isStrobeLight)
    local spec = self.spec_lightExtension
    local lightXmlFilename = xmlFile:getValue(key .. "#filename")

    local light = {
        realLightRange = xmlFile:getValue(key .. "#realLightRange", 1),
        isStrobeLight = isStrobeLight
    }

    if lightXmlFilename ~= nil then
        local linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)

        if linkNode ~= nil then
            local schema = isStrobeLight and LightExtension.strobeLightXMLSchema or LightExtension.runningLightXMLSchema
            local lightXMLFile = XMLFile.load("lightExtensionSharedLightXML", Utils.getFilename(lightXmlFilename, self.baseDirectory), schema)

            if lightXMLFile ~= nil then
                local i3dFilename = lightXMLFile:getValue(sharedKey .. ".filename")

                if i3dFilename ~= nil then
                    spec.xmlLoadingHandles[lightXMLFile] = true

                    light.xmlFile = lightXMLFile
                    light.key = sharedKey
                    light.linkNode = linkNode

                    light.filename = Utils.getFilename(i3dFilename, self.baseDirectory)
                    light.intensity = xmlFile:getValue(key .. "#intensity") -- Allow override in vehicle XML
                    light.realLightNode = xmlFile:getValue(key .. "#realLightNode", nil, self.components, self.i3dMappings) -- Allow override or standalone in vehicle XML

                    if light.realLightNode ~= nil and not getHasClassId(light.realLightNode, ClassIds.LIGHT_SOURCE) then
                        Logging.xmlWarning(xmlFile, "Node '%s' is not a real light source in '%s'", getName(light.realLightNode), key)
                        light.realLightNode = nil
                    end

                    if isStrobeLight then
                        self:loadLightExtensionLightStrobeDataFromXML(xmlFile, key, light)
                    end

                    local sharedLoadRequestId = self:loadSubSharedI3DFile(light.filename, false, false, self.onLightExtensionLightI3DLoaded, self, light)

                    table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
                else
                    Logging.xmlWarning(lightXMLFile, "Missing light i3d filename at '%s.filename'!", sharedKey)
                    lightXMLFile:delete()
                end
            end
        else
            Logging.xmlWarning(xmlFile, "Missing light linkNode in '%s'!", key)
        end
    else
        local lightNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        local lightShaderNode = xmlFile:getValue(key .. "#shaderNode", nil, self.components, self.i3dMappings)
        local realLightNode = xmlFile:getValue(key .. "#realLightNode", nil, self.components, self.i3dMappings)

        if self:setLightExtensionLightData(xmlFile, key, lightNode, lightShaderNode, realLightNode, light) then
            light.intensity = xmlFile:getValue(key .. "#intensity", 100)

            if isStrobeLight then
                self:loadLightExtensionLightStrobeDataFromXML(xmlFile, key, light)

                table.insert(spec.strobeLights, light)
            else
                table.insert(spec.runningLights, light)
            end
        else

        end
    end
end

function LightExtension:loadLightExtensionLightStrobeDataFromXML(xmlFile, key, light)
    light.time = math.huge
    light.sequenceTime = 0

    local blinkPattern = xmlFile:getValue(key .. "#blinkPattern") -- Closely replicates ETS2 and ATS strobe patterns for those more familiar with this using a string of X and - characters, where X represents ON state and - represents OFF state.

    if blinkPattern ~= nil then
        blinkPattern = blinkPattern:trim()

        local blinkStepLength = xmlFile:getValue(key .. "#blinkStepLength", 0.5) * 1000 -- Float representing duration of one step inside blink pattern in seconds.

        local sequence = {}
        local stepTime = 0

        local invert = blinkPattern:sub(1, 1) == "-"
        local lastCharacter = invert and "-" or "X"
        local patternLength = #blinkPattern

        for i = 1, patternLength do
            local character = blinkPattern:sub(i, i)

            if LightExtension.stepCharacters[character] ~= nil then
                if lastCharacter ~= character then
                    table.insert(sequence, math.floor(stepTime + 0.5))
                    stepTime = 0
                end

                stepTime = stepTime + blinkStepLength
                lastCharacter = character

                if i == patternLength then
                    table.insert(sequence, math.floor(stepTime + 0.5))
                end
            end
        end

        if #sequence > 0 then
            light.isRandom = false
            light.sequence = sequence
            light.sequenceCount = #sequence
            light.invert = invert
            light.active = invert
            light.index = 1
        else
            light.isRandom = true
            light.active = false
            light.minOn = 100
            light.maxOn = 100
            light.minOff = 100
            light.maxOff = 400

            Logging.xmlWarning(xmlFile, "Invalid or no Blink Pattern' given in '%s'. Loading random sequence instead!", key)
        end
    else
        -- Make sure there is a real sequence or at least 1 value
		local sequence = string.getVectorN(xmlFile:getValue(key .. "#sequence"))
        local sequenceCount = sequence ~= nil and #sequence or 0

        if sequenceCount > 0 then
            light.isRandom = false
            light.sequence = sequence
            light.sequenceCount = sequenceCount
            light.invert = xmlFile:getValue(key .. "#invert", false)
            light.active = light.invert
            light.index = 1
        else
            light.isRandom = true
            light.active = false
            light.minOn = xmlFile:getValue(key .. "#minOn", 100)
            light.maxOn = xmlFile:getValue(key .. "#maxOn", 100)
            light.minOff = xmlFile:getValue(key .. "#minOff", 100)
            light.maxOff = xmlFile:getValue(key .. "#maxOff", 400)
        end
    end
end

function LightExtension:setLightExtensionLightData(xmlFile, key, lightNode, lightShaderNode, realLightNode, light)
    local isValid = false

    if lightNode ~= nil then
        setVisibility(lightNode, false)

        light.lightNode = lightNode
        isValid = true
    end

    if lightShaderNode ~= nil then
        if getHasShaderParameter(lightShaderNode, "lightControl") then
            local _, y, z, w = getShaderParameter(lightShaderNode, "lightControl")

            setShaderParameter(lightShaderNode, "lightControl", 0, y, z, w, false)

            light.lightShaderNode = lightShaderNode
            isValid = true
        else
            Logging.xmlWarning(xmlFile, "Node '%s' in '%s.light#shaderNode' has no shader parameter 'lightControl'. Ignoring node!", getName(lightShaderNode), key)
        end
    end

    if realLightNode ~= nil then
        if getHasClassId(realLightNode, ClassIds.LIGHT_SOURCE) then
            light.defaultColor = {
                getLightColor(realLightNode)
            }

            setVisibility(realLightNode, false)

            light.realLightNode = realLightNode
            light.defaultLightRange = getLightRange(realLightNode)

            setLightRange(realLightNode, light.defaultLightRange * light.realLightRange)
            isValid = true
        else
            Logging.xmlWarning(xmlFile, "Node '%s' is not a real light source in '%s'", getName(realLightNode), key)
        end
    end

    return isValid
end

function LightExtension:onLightExtensionLightI3DLoaded(i3dNode, failedReason, light)
    local spec = self.spec_lightExtension
    local xmlFile = light.xmlFile
    local key = light.key

    if i3dNode ~= 0 then
        local rootNode = xmlFile:getValue(key .. ".rootNode#node", nil, i3dNode)

        if rootNode ~= nil then
            local lightNode = xmlFile:getValue(key .. ".light#node", nil, i3dNode)
            local lightShaderNode = xmlFile:getValue(key .. ".light#shaderNode", nil, i3dNode)
            local realLightNode = xmlFile:getValue(key .. ".realLight#node", nil, i3dNode)

            if light.realLightNode ~= nil then
                if realLightNode ~= nil then
                    setVisibility(realLightNode, false) -- Ignore if it is already part of the vehicle XML.
                end

                realLightNode = light.realLightNode
            end

            if self:setLightExtensionLightData(xmlFile, key, lightNode, lightShaderNode, realLightNode, light) then
                light.rootNode = rootNode

                if light.intensity == nil then
                    light.intensity = xmlFile:getValue(key .. ".light#intensity", 100)
                end

                link(light.linkNode, rootNode)
                setTranslation(rootNode, 0, 0, 0)

                if light.isStrobeLight then
                    table.insert(spec.strobeLights, light)
                else
                    table.insert(spec.runningLights, light)
                end
            end
        end

        delete(i3dNode)
    end

    xmlFile:delete()

    light.xmlFile = nil
    light.key = nil

    spec.xmlLoadingHandles[xmlFile] = nil
end
