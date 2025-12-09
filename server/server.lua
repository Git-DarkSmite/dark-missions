local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}

AddEventHandler('onResourceStart', function()
    if GetCurrentResourceName() == "dark-missions" then
        LoadCooldowns()
    end
end)

function LoadCooldowns()
    MySQL.Async.fetchAll('SELECT * FROM dark_missions', {}, function(results)
        for _, result in pairs(results) do
            cooldowns[result.citizenid] = cooldowns[result.citizenid] or {}
            cooldowns[result.citizenid][result.missionName] = {
                cooldownTime = result.cooldownTime,
                done = result.done
            }
        end
    end)
end

function SaveCooldown(citizenid, missionName, cooldownTime, done)
    MySQL.Async.execute('REPLACE INTO dark_missions (citizenid, missionName, cooldownTime, done) VALUES (@citizenid, @missionName, @cooldownTime, @done)', {
        ['@citizenid'] = citizenid,
        ['@missionName'] = missionName,
        ['@cooldownTime'] = cooldownTime,
        ['@done'] = done or 0
    })
end

RegisterNetEvent('dark-missions:load:missions', function(mission)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    MySQL.Async.execute("INSERT IGNORE INTO dark_missions (citizenid, missionName, cooldownTime, done) VALUES (@citizenid, @missionName, @cooldownTime, @done)", {
        ['@citizenid'] = citizenid,
        ['@missionName'] = mission.name,
        ['@cooldownTime'] = 0,
        ['@done'] = 0
    })
end)

RegisterNetEvent('missions:checkAndStart', function(missionName, menuID, isOnMission)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    for _, mission in ipairs(Config.Missions) do
        if mission.name:lower() == missionName:lower() then
            -- Kontrollera om spelaren redan gör ett uppdrag
            if isOnMission then
                TriggerClientEvent("dark-missions:client:notify:error", src, "Du gör redan ett uppdrag!", "")
                return
            end

            -- Kontrollera bannade jobb och gäng
            if mission.BannedJobsAndGangs then
                local job = Player.PlayerData.job.name
                local gang = Player.PlayerData.gang.name
                for _, bannedJob in ipairs(mission.BannedJobsAndGangs.jobs or {}) do
                    if job == bannedJob then
                        TriggerClientEvent("dark-missions:client:notify:error", src, "Du får inte göra detta på grund av ditt jobb!", "")
                        return
                    end
                end
                for _, bannedGang in ipairs(mission.BannedJobsAndGangs.gangs or {}) do
                    if gang == bannedGang then
                        TriggerClientEvent("dark-missions:client:notify:error", src, "Du får inte göra detta på grund av ditt gäng!", "")
                        return
                    end
                end
            end

            -- Kontrollera cooldown och completed status
            local currentTime = os.time()
            local result = MySQL.query.await("SELECT cooldownTime, done FROM dark_missions WHERE citizenid = ? AND missionName = ?", {citizenid, missionName})
            local cooldownTime = result[1] and result[1].cooldownTime or 0
            local done = result[1] and result[1].done or 0

            if currentTime < cooldownTime then
                local remainingSeconds = cooldownTime - currentTime
                local remainingMinutes = math.ceil(remainingSeconds / 60)
                TriggerClientEvent("dark-missions:client:notify:error", src, "Kom tillbaka om " .. remainingMinutes .. " minut(er)!", "")
                return
            end

            if done == 1 and mission.done then
                TriggerClientEvent("dark-missions:client:notify:error", src, "Du har redan slutfört detta uppdrag!", "")
                return
            end

            -- Kontrollera krav på tidigare uppdrag
            if mission.missionsRequire then
                local requiredMission = mission.missionsRequire
                local reqResult = MySQL.query.await("SELECT done FROM dark_missions WHERE citizenid = ? AND missionName = ?", {citizenid, requiredMission})
                local reqDone = reqResult and reqResult[1] and reqResult[1].done or 0
                if reqDone ~= 1 then
                    TriggerClientEvent("dark-missions:client:notify:error", src, "Du måste slutföra ett tidigare uppdrag först!", "")
                    return
                end
            end

            -- Om vi kommer hit är allt OK - öppna menyn
            TriggerClientEvent('dark-missions:client:openMenu', src, {
                title = mission.pedtitle,
                speech = mission.pedSpeech,
                menuID = menuID,
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
            break
        end
    end
end)

RegisterNetEvent('missions:attemptStart', function(missionName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    for _, mission in ipairs(Config.Missions) do
        if mission.name:lower() == missionName:lower() then
            local missionCooldown = mission.cooldownTime or 0
            local currentTime = os.time()
            local newCooldown = currentTime + (missionCooldown * 60)
            SaveCooldown(citizenid, missionName, newCooldown, 0)
            TriggerClientEvent('missions:startMission', src, missionName)
            if mission.pedAcceptSound then
                TriggerClientEvent("missions:playpsound", src, mission.pedAcceptSoundDistance, mission.pedAcceptSound, mission.pedAcceptSoundVolume)
            end
            break
        end
    end
end)

RegisterNetEvent('missions:completeMission', function(missionName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    for _, mission in ipairs(Config.Missions) do
        if mission.name:lower() == missionName:lower() then
            local cooldownTime = mission.cooldownTime or 0
            local currentTime = os.time()
            local newCooldown = currentTime + (cooldownTime * 60)
            cooldowns[citizenid] = cooldowns[citizenid] or {}
            cooldowns[citizenid][missionName] = { cooldownTime = newCooldown, done = 0 }
            SaveCooldown(citizenid, missionName, newCooldown, 0)
            TriggerClientEvent('missions:completeMission', src, missionName)
            break
        end
    end
end)

RegisterNetEvent('dark-missions:additem', function(item, amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    xPlayer.Functions.AddItem(item, amount)
end)

RegisterNetEvent('dark-missions:addcash', function(amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    xPlayer.Functions.AddMoney("cash", amount, "dark-missions")
end)

RegisterNetEvent('dark-missions:addbank', function(amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    xPlayer.Functions.AddMoney("bank", amount, "dark-missions")
end)

RegisterNetEvent('dark-missions:completeMission:set:done', function(missionName)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    local citizenid = xPlayer.PlayerData.citizenid
    MySQL.query("UPDATE dark_missions SET done = 1 WHERE citizenid = ? AND missionName = ?", {citizenid, missionName})
    if cooldowns[citizenid] and cooldowns[citizenid][missionName] then
        cooldowns[citizenid][missionName].done = 1
    end
end)

QBCore.Functions.CreateCallback('dark-missions:data', function(source, cb)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return cb({}) end
    local citizenid = xPlayer.PlayerData.citizenid
    local result = MySQL.query.await("SELECT missionName, cooldownTime, done FROM dark_missions WHERE citizenid = ?", {citizenid})
    cb(result or {})
end)

QBCore.Functions.CreateCallback('dark-missions:player:data', function(source, cb)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    cb({
        playerId = source,
        PlayerJob = xPlayer.PlayerData.job.name,
        PlayerGang = xPlayer.PlayerData.gang.name,
        playerCitizenid = xPlayer.PlayerData.citizenid,
        PlayerFirstName = xPlayer.PlayerData.charinfo.firstname,
        playerLastName = xPlayer.PlayerData.charinfo.lastname
    })
end)

QBCore.Functions.CreateCallback('dark-missions:sql:data', function(source, cb)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return cb({}) end
    local citizenid = xPlayer.PlayerData.citizenid
    local result = MySQL.query.await("SELECT missionName, cooldownTime, done FROM dark_missions WHERE citizenid = ?", {citizenid})
    cb(result or {})
end)

QBCore.Functions.CreateCallback('dark-missions:checkPlayerJobAndGang', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local job = Player.PlayerData.job.name
    local gang = Player.PlayerData.gang.name
    local callbackData = {}

    callbackData = {
        job = job,
        gang = gang,
    }
    cb(callbackData)
end)

QBCore.Functions.CreateCallback('dark-missions:checkMissionStatus', function(source, cb, missionName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        return cb({canInteract = false, blocked = false, completed = false, onCooldown = false, banned = false})
    end
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.query.await("SELECT cooldownTime, done FROM dark_missions WHERE citizenid = ? AND missionName = ?", {citizenid, missionName})
    
    local currentTime = os.time()
    local done = result and result[1] and result[1].done or 0
    local cooldownTime = result and result[1] and result[1].cooldownTime or 0

    local mission = nil
    for _, m in ipairs(Config.Missions) do
        if m.name:lower() == missionName:lower() then
            mission = m
            break
        end
    end

    if not mission then
        return cb({canInteract = false, blocked = false, completed = false, onCooldown = false, banned = false})
    end

    local status = {
        canInteract = true,
        onCooldown = currentTime < cooldownTime,
        completed = done == 1 and mission.done,
        blocked = false,
        banned = false,
        message = ""
    }

    -- Kontrollera bannade jobb och gäng
    if mission.BannedJobsAndGangs then
        local job = Player.PlayerData.job.name
        local gang = Player.PlayerData.gang.name
        for _, bannedJob in ipairs(mission.BannedJobsAndGangs.jobs or {}) do
            if job == bannedJob then
                status.banned = true
                status.canInteract = false
                status.message = "Du får inte göra detta på grund av ditt jobb!"
                break
            end
        end
        if not status.banned then
            for _, bannedGang in ipairs(mission.BannedJobsAndGangs.gangs or {}) do
                if gang == bannedGang then
                    status.banned = true
                    status.canInteract = false
                    status.message = "Du får inte göra detta på grund av ditt gäng!"
                    break
                end
            end
        end
    end

    if mission.missionsRequire then
        local requiredMission = mission.missionsRequire
        local reqResult = MySQL.query.await("SELECT done FROM dark_missions WHERE citizenid = ? AND missionName = ?", {citizenid, requiredMission})
        local reqDone = reqResult and reqResult[1] and reqResult[1].done or 0
        if reqDone ~= 1 then
            status.blocked = true
            status.canInteract = false
            status.message = "Du måste slutföra ett tidigare uppdrag först!"
        end
    end

    if status.completed then
        status.message = "Du har redan slutfört detta uppdrag!"
    elseif status.onCooldown then
        local remainingSeconds = cooldownTime - currentTime
        local remainingMinutes = math.ceil(remainingSeconds / 60)
        status.message = "Kom tillbaka om " .. remainingMinutes .. " minut(er)!"
    end

    cb(status)
end)