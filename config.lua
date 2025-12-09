Config = {
    TextState = false,
    CurrentLabel = nil,
    DefaultTypeDelay = 3000, -- Duration in milliseconds for text display
    NotifyType = "ox_lib",   -- Notification system: "ox_lib", "okok", or "qbcore"
    Missions = {},            -- Tom tabell som fylls av missions/*.lua
    LeaveMissionCommand = "leave_mission",
    UsePedMarker = true
}

Notify = {}
ShownNoti = false


function ShowText(label, state, options)
    if state == Config.TextState and label == Config.CurrentLabel then return end
    Config.TextState = state
    Config.CurrentLabel = label

    if state then
        lib.showTextUI(label)
        if not ShownNoti and options and #options > 1 then
            lib.notify({
                id = 'interaction',
                title = 'dark-missions',
                description = 'USE SCROLL-WHEEL FOR MORE OPTIONS',
                position = 'top-right',
                duration = 4000,
                style = {
                    backgroundColor = '#141517',
                    color = '#C1C2C5',
                    ['.description'] = { color = '#909296' }
                },
                icon = 'arrow-down',
                iconColor = '#A020F0'
            })
            ShownNoti = true
        end
    else
        lib.hideTextUI()
        ShownNoti = false
        Config.CurrentLabel = nil
    end
end