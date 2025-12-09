QBCore = exports["qb-core"]:GetCoreObject()
local spawnedVehicle
local blip
local currentText = ""
local isDrawingText = false
local activeMarkers = {}
local activePedMarkers = {}
local missionStatuses = {}
local interactKey = 38 -- E key
local texton = false
local blipon = false
CurrentMission = nil
local spawnedPeds = {}

-- Resource Events
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LaddaUppdrag()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deleteVehicle()
        RemoveAllPeds()
        RemoveAllPedMarkers()
    end
end)

-- Player Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    LaddaUppdrag()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveAllPeds()
    RemoveAllPedMarkers()
end)

function LaddaUppdrag()
    if not Config or not Config.Missions or #Config.Missions == 0 then
        print("[dark-missions] ERROR: Config.Missions är nil eller tom. Kontrollera missions/*.lua och fxmanifest.lua.")
        return
    end

    for i, mission in ipairs(Config.Missions) do
        QBCore.Functions.TriggerCallback('dark-missions:sql:data', function(info)
            local found = false
            for _, data in ipairs(info or {}) do
                if data.missionName == mission.name then
                    found = true
                    break
                end
            end
            if not found then
                TriggerServerEvent("dark-missions:load:missions", mission)
            end
        end)

        QBCore.Functions.TriggerCallback('dark-missions:checkMissionStatus', function(status)
            missionStatuses[mission.name] = status or {}
        end, mission.name)

        local ped = exports['dark-missions']:CreateNPC({
            name = mission.name,
            model = mission.pedModel,
            coords = vector3(mission.pedCoords.x, mission.pedCoords.y, mission.pedCoords.z - 1),
            heading = mission.pedCoords.w,
            isFrozen = true
        }, {
            title = mission.pedtitle,
            speech = mission.pedSpeech,
            menuID = mission.name,
            sound = mission.pedGreetingSound,
            mission = mission,
            BannedJobsAndGangs = mission.BannedJobsAndGangs,
            position = 'right',
            focusCam = true,
            options = {
                {
                    key = 'E',
                    label = mission.pedLabelAccept,
                    reaction = mission.pedAcceptReaction,
                    selected = function(data)
                        TriggerServerEvent('missions:attemptStart', mission.name)
                        exports['dark-missions']:CloseMenu(data.menuID)
                    end
                },
                {
                    key = 'Q',
                    label = mission.pedLabelDeny,
                    reaction = mission.pedDenyReaction,
                    selected = function(data)
                        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, "jail", 0)
                        if mission.pedDenySound then
                            PlaySound(mission.pedDenySoundDistance, mission.pedDenySound, mission.pedDenySoundVolume)
                        end
                        exports['dark-missions']:CloseMenu(data.menuID)
                    end
                }
            }
        })

        if ped then
            table.insert(spawnedPeds, ped)
            CreatePedMarker(i, mission)
        else
            print("[dark-missions] ERROR: Misslyckades att skapa ped för uppdrag: " .. (mission.name or "unknown"))
        end
        Wait(500)
    end
end

function RemoveAllPeds()
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawnedPeds = {}
end

function RemoveAllPedMarkers()
    for id in pairs(activePedMarkers) do
        activePedMarkers[id] = nil
    end
end

RegisterNetEvent('missions:startMission', function(missionName)
    for _, mission in ipairs(Config.Missions) do
        if mission.name:lower() == missionName:lower() then
            CurrentMission = mission
            StartTask(1)
            UpdateAllMissionStatuses()
            return
        end
    end
end)

RegisterNetEvent('missions:completeMission', function(missionName)
    UpdateAllMissionStatuses()
end)

function UpdateAllMissionStatuses()
    for _, m in ipairs(Config.Missions) do
        QBCore.Functions.TriggerCallback('dark-missions:checkMissionStatus', function(status)
            missionStatuses[m.name] = status or {}
            print("[dark-missions] Status uppdaterad för " .. m.name .. ": " .. json.encode(status))
        end, m.name)
    end
end

function StartTask(taskIndex)
    if not CurrentMission or not CurrentMission.tasks[taskIndex] then return end
    
    local task = CurrentMission.tasks[taskIndex]
    SetNewWaypoint(task.coords.x, task.coords.y)
    
    if not texton then
        CreateDrawMissionText(CurrentMission.description)
        texton = true
    end
    activeMarkers[taskIndex] = true
    CreateMarker(taskIndex, task)
end

function CreateMarker(id, data)
    Citizen.CreateThread(function()
        while activeMarkers[id] do
            Wait(0)
            if not CurrentMission then return end
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - data.coords)

            if distance <= data.markerRadius then
                QBCore.Functions.DrawText3D(data.coords.x, data.coords.y, data.coords.z, data.MarkerTitel)
                DrawMarker(data.MarkertType, data.coords.x, data.coords.y, data.coords.z - 0.92, 0.0, 0.0, 0.0,
                    data.rotX, data.rotY, data.rotZ, data.MarkertSize.x, data.MarkertSize.y, data.MarkertSize.z,
                    data.MarkertR, data.MarkertG, data.MarkertB, 100, data.MarkertBob, true, 2, data.MarkertRotate)

                if distance <= data.interactKeyRadius and IsControlJustReleased(0, interactKey) then
                    TriggerServerEvent('missions:completeMission', CurrentMission.name)
                    activeMarkers[id] = nil

                    if data.description then CreateDrawMissionText(data.description) end
                    if data.playSound then PlaySound(data.distance, data.playSound, data.volume) end
                    if data.ExecuteCommand then ExecuteCommand(data.ExecuteCommand) end
                    if data.addItem then TriggerServerEvent("dark-missions:additem", data.addItem, data.addItemAmount) end
                    if data.addCash then TriggerServerEvent("dark-missions:addcash", data.addCash) end
                    if data.addBank then TriggerServerEvent("dark-missions:addbank", data.addBank) end
                    if blipon then RemoveBlipPoint() blipon = false end
                    if data.spawnVehicle then spawnVehicle(data.spawnVehicle, data.spawnVehicleCoords) end
                    if data.deleteVehicle then deleteVehicle() end
                    if data.accessToblackmarket then TriggerServerEvent("ak4y:setDoneToOne") end
                    if data.customtrigger then TriggerEvent("dark-missions:client:customtrigger", data) end

                    Wait((data.waitTime or 0) * 1000)
                    local nextIndex = id + 1
                    if CurrentMission.tasks[nextIndex] then
                        StartTask(nextIndex)
                    else
                        if CurrentMission.done then
                            TriggerServerEvent("dark-missions:completeMission:set:done", CurrentMission.name)
                        end
                        CurrentMission = nil
                        CreateDrawMissionText("")
                        deleteVehicle()
                        texton = false
                        if data.rewards then TriggerServerEvent("dark-reward:run:rewards", data.rewards) end
                    end
                end
            end
        end
    end)
end



function CreatePedMarker(id, mission)
if Config.UsePedMarker then
    if not id or not mission or not mission.pedCoords then
        print("Error: Ogiltiga parametrar i CreatePedMarker")
        return
    end

    activePedMarkers[id] = true

        Citizen.CreateThread(function()
            local lastStatusUpdate = 0
            local currentStatus = nil
            local updateInterval = 2000
            local markerCoords = vector3(mission.pedCoords.x, mission.pedCoords.y, mission.pedCoords.z)

            while activePedMarkers[id] do
                local waitTime = 1000
                local playerPed = PlayerPedId()

                if DoesEntityExist(playerPed) then
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = #(playerCoords - markerCoords)

                    if distance <= 2.0 then
                        waitTime = 0
                        local r, g, b = 0, 255, 0

                        local currentTime = GetGameTimer()
                        if currentTime - lastStatusUpdate >= updateInterval or not currentStatus then
                            QBCore.Functions.TriggerCallback('dark-missions:checkMissionStatus', function(status)
                                currentStatus = status or {}
                                lastStatusUpdate = GetGameTimer()
                            end, mission.name)
                            Wait(0)
                        end

                        if currentStatus then
                            if currentStatus.banned then
                                r, g, b = 255, 0, 0
                            elseif currentStatus.blocked then
                                r, g, b = 255, 0, 0
                            elseif currentStatus.completed then
                                r, g, b = 255, 0, 0
                            elseif CurrentMission and CurrentMission.name == mission.name then
                                r, g, b = 255, 255, 255
                            elseif currentStatus.onCooldown then
                                r, g, b = 255, 255, 0
                            elseif currentStatus.canInteract then
                                r, g, b = 0, 255, 0
                            end
                        end

                        pcall(function()
                            DrawMarker(32, markerCoords.x, markerCoords.y, markerCoords.z + 0.9,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2,
                                r, g, b, 200, false, true, 2, false)
                        end)
                    end
                else
                    Wait(500)
                end
                Wait(waitTime)
            end
        end)
    end
end

RegisterNetEvent("QBCore:Client:OnJobUpdate", function()
    RemoveAllPedMarkers()
    Wait(500)
    for i, mission in ipairs(Config.Missions) do
        CreatePedMarker(i, mission)
    end
end)

RegisterNetEvent("QBCore:Client:OnGangUpdate", function()
    RemoveAllPedMarkers()
    Wait(500)
    for i, mission in ipairs(Config.Missions) do
        CreatePedMarker(i, mission)
    end
end)

function CreateDrawMissionText(text)
    if isDrawingText then
        isDrawingText = false
        Wait(100)
    end
    currentText = text or ""
    isDrawingText = true
    Citizen.CreateThread(function()
        while isDrawingText do
            Wait(0)
            DrawMissionText(currentText)
        end
    end)
end

function DrawMissionText(text)
    local scale = 0.4
    SetTextFont(0)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString("~w~" .. text)
    DrawText(0.5 - GetTextWidth(text, 0, scale) / 2, 0.96)
end

function GetTextWidth(text, font, scale)
    SetTextEntryForWidth("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetTextFont(font)
    SetTextScale(scale, scale)
    return EndTextCommandGetWidth(true)
end

function PlaySound(distance, sound, volume)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', distance or 1.0, sound, volume or 1.0)
end

function CreateBlipPoint(title, coords)
    blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 1)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(title)
    EndTextCommandSetBlipName(blip)
    blipon = true
end

function RemoveBlipPoint()
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
        blip = nil
    end
end

function spawnVehicle(vehicle, coords)
    if not vehicle or not coords then return end
    
    local model = GetHashKey(vehicle)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(500) end
    
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
    end
    
    spawnedVehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    SetModelAsNoLongerNeeded(model)
    return spawnedVehicle
end

function deleteVehicle()
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
        spawnedVehicle = nil
    end
end

RegisterCommand(Config.LeaveMissionCommand or "leavemission", function()
    if CurrentMission then
        CurrentMission = nil
        CreateDrawMissionText("")
        texton = false
        deleteVehicle()
        RemoveBlipPoint()
        for k in pairs(activeMarkers) do
            activeMarkers[k] = nil
        end
        UpdateAllMissionStatuses()
    end
end, false)