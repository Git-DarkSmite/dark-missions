QBCore = exports["qb-core"]:GetCoreObject()

-- Standard notify-funktion om ingen typ är specificerad
local function showNotify(title, description, type)
    if Config and Config.NotifyType then
        if Config.NotifyType == "okok" and exports['okokNotify'] then
            exports['okokNotify']:Alert(title, description, 5000, type)
        elseif Config.NotifyType == "ox_lib" and lib then
            lib.notify({
                title = title,
                description = description,
                type = type,
            })
        elseif Config.NotifyType == "qbcore" then
            QBCore.Functions.Notify(description, type, 5000)
        else
            -- Fallback till QBCore om inget annat fungerar
            QBCore.Functions.Notify(description, type, 5000)
        end
    else
        -- Fallback om Config.NotifyType inte är satt
        QBCore.Functions.Notify(description, type, 5000)
    end
end

RegisterNetEvent("dark-missions:client:notify:success", function(title, description)
    showNotify(title or "Success", description or "", "success")
end)

RegisterNetEvent("dark-missions:client:notify:error", function(title, description)
    showNotify(title or "Error", description or "", "error")
end)