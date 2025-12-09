RegisterNetEvent('dark-missions:client:customtrigger', function(data)
    -- Exempel set fire.
    if data.customtrigger == "setfire" then
        print("Set Fire!")
    elseif data.customtrigger == "name" then
        -- Add more here
    end
end)
