local menuState = {}
local interactionPoints = {}
local interactionPeds = {}
local spawnedPeds = {}
local wait = 1250
local currentLabel = 'UNDEFINED'
local callbackFunctions = {}
local scrollCooldown = 250
local scrollCooldownTimer = 0
local currentPointData = {}
QBCore = exports["qb-core"]:GetCoreObject()

function OpenChoiceMenu(data)
    menuState[data.menuID] = true
    local serializableOptions = {}
    for i, option in ipairs(data.options) do
        serializableOptions[i] = {
            key = option.key,
            label = option.label,
            closeAll = option.closeAll,
            speech = option.speech,
            reaction = option.reaction
        }
        callbackFunctions[data.menuID] = callbackFunctions[data.menuID] or {}
        callbackFunctions[data.menuID][option.key] = option.selected
    end
    SendNUIMessage({
        action = 'openChoiceMenu',
        speech = data.speech,
        title = data.title,
        menuID = data.menuID,
        position = data.position,
        duration = data.speechOptions and data.speechOptions.duration or Config.DefaultTypeDelay,
        options = serializableOptions
    })
    SetNuiFocus(true, true)
    return 'done'
end

function CreateNPC(pedData, interactionData)
    RequestModel(pedData.model)
    while not HasModelLoaded(pedData.model) do Wait(100) end

    local ped = CreatePed(4, pedData.model, pedData.coords.x, pedData.coords.y, pedData.coords.z, pedData.heading, false, false)
    while not DoesEntityExist(ped) do Wait(100) end

    table.insert(spawnedPeds, ped)
    interactionPeds[interactionData.menuID] = ped

    if pedData.isFrozen then
        Wait(950)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, true)
    end

    InteractionEntity(ped, {{
        name = interactionData.menuID,
        distance = interactionData.distance or 2.0,
        margin = interactionData.margin or 0.2,
        options = {{
            label = interactionData.mission.pedInteractLabel,
            selected = function(data)
                TriggerServerEvent('missions:checkAndStart', interactionData.mission.name, data.name, CurrentMission ~= nil)
            end
        }}
    }})
    Wait(100)
    return ped
end

function PlaySound(distance, sound, volume)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', distance or 1.0, sound, volume or 1.0)
end

function PedInteraction(entity, data)
    menuState[data.menuID] = true
    local cam
    if data.focusCam then
        local coords = GetEntityCoords(PlayerPedId())
        local entCoords = GetEntityCoords(entity)
        local screenCoords = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.9, 0.55)
        if #(coords - entCoords) < 8.0 then
            cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            SetCamCoord(cam, screenCoords.x, screenCoords.y, screenCoords.z)
            PointCamAtCoord(cam, entCoords.x, entCoords.y, entCoords.z + 0.4)
            RenderScriptCams(true, true, 1000, 1, 1)
            Wait(500)
        end
    end

    if data.sound then
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, data.sound, 2)
    end

    local serializableOptions = {}
    for i, option in ipairs(data.options) do
        serializableOptions[i] = {
            key = option.key,
            label = option.label,
            speech = option.speech,
            reaction = option.reaction
        }
        callbackFunctions[data.menuID] = callbackFunctions[data.menuID] or {}
        -- Gör callbacken självständig genom att baka in all data
        if option.key == 'E' then
            callbackFunctions[data.menuID][option.key] = function(callbackData)
                TriggerServerEvent('missions:attemptStart', data.mission.name)
                exports['dark-missions']:CloseMenu(callbackData.menuID)
            end
        elseif option.key == 'Q' then
            callbackFunctions[data.menuID][option.key] = function(callbackData)
                TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, "jail", 0)
                if data.mission.pedDenySound then
                    PlaySound(data.mission.pedDenySoundDistance, data.mission.pedDenySound, data.mission.pedDenySoundVolume)
                end
                exports['dark-missions']:CloseMenu(callbackData.menuID)
            end
        end
    end

    SendNUIMessage({
        action = 'openPedMenu',
        title = data.title,
        menuID = data.menuID,
        position = data.position,
        speech = data.speech,
        duration = Config.DefaultTypeDelay,
        options = serializableOptions
    })
    SetNuiFocus(true, true)
    print("[DEBUG] Menu opened with ID: " .. data.menuID .. " - Options: " .. json.encode(serializableOptions))

    while menuState[data.menuID] do
        local coords = GetEntityCoords(PlayerPedId())
        if #(coords - GetEntityCoords(entity)) > 5.0 then
            CloseMenu(data.menuID)
            break
        end
        Wait(10)
    end

    if cam then
        RenderScriptCams(false, true, 1000, 1, 1)
        DestroyCam(cam, true)
    end
end

function InteractionEntity(entity, data)
    if data and data[1].name then
        interactionPoints[data[1].name] = {
            name = data[1].name,
            options = data[1].options,
            distance = data[1].distance,
            margin = data[1].margin,
            currentOption = 1,
            entity = entity
        }
    end
end

local RotationToDirection = function(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local RayCastGamePlayCamera = function(distance)
    local currentRenderingCam = nil
    if not IsGameplayCamRendering() then
        currentRenderingCam = GetRenderingCam()
    end
    local cameraRotation = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
    local cameraCoord = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, b, c, _, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

CreateThread(function()
    local lastPointData
    while true do
        local ped = PlayerPedId()
        local closestPoint
        local minDistance = math.huge
        local hit, hitPosition, hitEntity = RayCastGamePlayCamera(200)

        if hitEntity then
            local coords = GetEntityCoords(ped)
            for _, point in pairs(interactionPoints) do
                local distance = #(coords - GetEntityCoords(point.entity))
                if point.entity == hitEntity and distance < point.distance and distance < minDistance then
                    minDistance = distance
                    closestPoint = point
                end
            end
        end

        if closestPoint then
            if lastPointData ~= closestPoint then
                lastPointData = closestPoint
                currentPointData = closestPoint
                currentLabel = closestPoint.options[closestPoint.currentOption].label
                ShowText(currentLabel, true, currentPointData.options)
            end
        else
            if lastPointData then
                ShowText(currentLabel, false, nil)
                lastPointData = nil
                currentPointData = nil
            end
        end
        Wait(wait)
    end
end)

function CloseMenu(menuID)
    if menuState[menuID] then
        SendNUIMessage({ action = 'closeMenu', menuID = menuID })
        menuState[menuID] = nil
        SetNuiFocus(false, false)
        print("[DEBUG] Menu closed with ID: " .. menuID)
    end
end

RegisterCommand('+interact', function()
    if currentPointData and currentPointData.options then
        currentPointData.options[currentPointData.currentOption].selected(currentPointData)
    end
end, false)

RegisterCommand('+scrollDown', function()
    if not currentPointData or not currentPointData.options then return end
    local currentTime = GetGameTimer()
    if currentTime - scrollCooldownTimer < scrollCooldown then return end
    scrollCooldownTimer = currentTime
    currentPointData.currentOption = math.min(currentPointData.currentOption + 1, #currentPointData.options)
    currentLabel = currentPointData.options[currentPointData.currentOption].label
    ShowText(currentLabel, true, currentPointData.options)
end, false)

RegisterCommand('+scrollUp', function()
    if not currentPointData or not currentPointData.options then return end
    local currentTime = GetGameTimer()
    if currentTime - scrollCooldownTimer < scrollCooldown then return end
    scrollCooldownTimer = currentTime
    currentPointData.currentOption = math.max(currentPointData.currentOption - 1, 1)
    currentLabel = currentPointData.options[currentPointData.currentOption].label
    ShowText(currentLabel, true, currentPointData.options)
end, false)

RegisterKeyMapping('+interact', 'dark-missions - Interact', 'keyboard', 'E')
RegisterKeyMapping('+scrollDown', 'dark-missions - Scroll Down', 'MOUSE_WHEEL', 'IOM_WHEEL_DOWN')
RegisterKeyMapping('+scrollUp', 'dark-missions - Scroll Up', 'MOUSE_WHEEL', 'IOM_WHEEL_UP')

RegisterNuiCallback('selectOption', function(data, cb)
    local menuID = data.menuID
    local key = data.key
    print("[DEBUG] NUI selectOption triggered - menuID: " .. menuID .. ", key: " .. key)
    if callbackFunctions[menuID] and callbackFunctions[menuID][key] then
        local success, error = pcall(function()
            callbackFunctions[menuID][key](data)
        end)
        if success then
            cb(1)
        else
            print("[ERROR] Callback failed for menuID: " .. menuID .. ", key: " .. key .. " - Error: " .. error)
            CloseMenu(menuID)
            cb(0)
        end
    else
        print("[DEBUG] No callback found for menuID: " .. menuID .. ", key: " .. key)
        CloseMenu(menuID)
        cb(0)
    end
end)

RegisterNetEvent('dark-missions:client:openMenu', function(interactionData)
    local ped = interactionPeds[interactionData.menuID]
    if ped then
        PedInteraction(ped, interactionData)
    else
        print("[dark-missions] ERROR: Ped not found for menuID: " .. interactionData.menuID)
    end
end)

-- Saknas ShowText-funktion - lägger till en enkel implementation
-- function ShowText(text, show, options)
--     if show then
--         BeginTextCommandDisplayText("STRING")
--         AddTextComponentSubstringPlayerName(text)
--         EndTextCommandDisplayText(0.5, 0.5)
--     end
-- end

exports('OpenChoiceMenu', OpenChoiceMenu)
exports('CreateNPC', CreateNPC)
exports('PedInteraction', PedInteraction)
exports('CloseMenu', CloseMenu)
exports('InteractionEntity', InteractionEntity)