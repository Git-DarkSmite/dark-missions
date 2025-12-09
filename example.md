# Example Mission for dark-missions

This is an example mission file showcasing all the features and options available in the dark_missions resource. Each property is explained with comments to help you understand what it does and how to use it effectively.

If you don't want to use a certain feature, you can simply comment out or remove the corresponding line. However, keep in mind that not all functions can be removed freely—some have logical dependencies that must be maintained.

If you are using "missionsRequire," you must mark the mission it points to as "done" before proceeding.

```lua
local mission = {
    -- Basic mission information
    name = "Example",                    -- The unique name of the mission (used internally and in the database)
    pedInteractLabel = "E",              -- The key displayed to interact with the ped (e.g., "Press [E]")
    done = true,                         -- If true, the mission can only be completed once per player
    cooldownTime = 5,                    -- Cooldown time in minutes before the mission can be repeated
    missionsRequire = "Marcus",          -- Requires the mission "Marcus" to be completed before this mission becomes available.   

    -- Ped configuration
    pedModel = "a_m_m_business_01",      -- The model of the NPC (find more at: https://docs.fivem.net/docs/game-references/ped-models/)
    pedCoords = vector4(100.0, 200.0, 30.0, 90.0), -- Coordinates (x, y, z) and heading (w) where the ped spawns
    icon = "fas fa-briefcase",           -- Icon for qb-target interaction (Font Awesome icons: https://fontawesome.com/icons)
    label = "Talk to Businessman",       -- Label shown in qb-target when near the ped

    -- Ped dialogue and interaction
    pedSpeech = "I need your help with a special task!", -- What the ped says when you interact with them
    pedtitle = "Business Opportunity",   -- Title of the interaction menu
    pedLabelAccept = "Sure, I’ll help!", -- Text for the "accept" option in the menu
    pedLabelDeny = "No thanks!",         -- Text for the "deny" option in the menu
    pedAcceptReaction = "GENERIC_THANKS",-- Ped’s reaction animation when accepting (e.g., "GENERIC_THANKS", "GENERIC_CURSE")
    pedDenyReaction = "GENERIC_CURSE",   -- Ped’s reaction animation when denying
    description = "Start by talking to the businessman.", -- Initial mission description shown to the player

    -- Sound effects (optional)
    pedAcceptSound = "yes",              -- Sound played when accepting (requires InteractSound resource)
    pedAcceptSoundDistance = 5,          -- Distance the accept sound can be heard
    pedAcceptSoundVolume = 1.0,          -- Volume of the accept sound (0.0 to 1.0)
    pedDenySound = "no",                 -- Sound played when denying
    pedDenySoundDistance = 5,            -- Distance the deny sound can be heard
    pedDenySoundVolume = 1.0,            -- Volume of the deny sound
    pedGreetingSound = "hello",          -- Sound played when approaching the ped

    -- Restrictions (optional)
    BannedJobsAndGangs = {               -- Jobs and gangs that cannot start this mission
        jobs = {"police", "ambulance"},  -- List of banned job names
        gangs = {"ballas", "vagos"}      -- List of banned gang names
    },

    -- Tasks: A list of steps the player must complete
    tasks = {
        {   -- Task 1: Travel to a location and interact
            description = "~b~Go to the drop-off point", -- Description shown to the player (~b~ makes it blue)
            coords = vector3(150.0, 250.0, 30.0), -- Coordinates the player must reach
            waitTime = 2,                    -- Time (in seconds) to wait after completing this task before moving to the next
            playSound = "dropoff",           -- Sound played when reaching the location
            distance = 1.0,                  -- Distance at which the sound is audible
            volume = 0.8,                    -- Volume of the sound
            ExecuteCommand = "e salute",     -- Command executed when interacting (e.g., an emote)

            -- Marker settings for this task
            MarkerTitel = "~w~[~b~E~w~] Drop Off", -- Text shown above the marker
            markerRadius = 5.0,              -- Radius where the marker is visible
            interactKeyRadius = 1.5,         -- Radius where the player can press E to interact
            MarkertType = 2,                 -- Marker type (see: https://docs.fivem.net/natives/?_0x28477EC23D892089)
            MarkertBob = true,               -- If true, the marker bobs up and down
            MarkertRotate = false,           -- If true, the marker rotates
            MarkertR = 255,                  -- Red color value (0-255)
            MarkertG = 0,                    -- Green color value (0-255)
            MarkertB = 0,                    -- Blue color value (0-255)
            MarkertSize = vector3(1.0, 1.0, 1.0), -- Size of the marker (x, y, z)
            rotX = 0.0,                      -- Rotation X for the marker
            rotY = 0.0,                      -- Rotation Y for the marker
            rotZ = 0.0                       -- Rotation Z for the marker
        },
        {   -- Task 2: Spawn a vehicle and deliver it
            description = "~b~Pick up the delivery vehicle", -- Next step description
            coords = vector3(160.0, 260.0, 30.0), -- Location to pick up the vehicle
            waitTime = 0,                    -- No wait time after this task
            ExecuteCommand = "e mechanic",   -- Emote when interacting
            spawnVehicle = "adder",          -- Vehicle model to spawn (e.g., "adder", "t20")
            scpawnVehileCoords = vector4(165.0, 265.0, 30.0, 180.0), -- Spawn location and heading for the vehicle

            -- Marker settings
            MarkerTitel = "~w~[~b~E~w~] Pick Up Vehicle",
            markerRadius = 5.0,
            interactKeyRadius = 2.0,
            MarkertType = 27,
            MarkertBob = true,
            MarkertRotate = true,
            MarkertR = 0,
            MarkertG = 255,
            MarkertB = 0,
            MarkertSize = vector3(2.0, 2.0, 1.0),
            rotX = -90.0,
            rotY = 0.0,
            rotZ = 0.0
            customtrigger = "setfire"               -- Trigger a client event in client/customtrigger.lua called 'setfire'. Then, check which trigger is holding the event.
        },
        {   -- Task 3: Complete the mission with rewards
            description = "~b~Deliver the vehicle and finish", -- Final step description
            coords = vector3(170.0, 270.0, 30.0), -- Delivery location
            waitTime = 1,                    -- Wait 1 second before completing
            playSound = "complete",          -- Sound when finishing
            distance = 2.0,                  -- Sound distance
            volume = 1.0,                    -- Sound volume
            deleteVehicle = true,            -- Deletes the spawned vehicle when this task is done

            -- Marker settings
            MarkerTitel = "~w~[~b~E~w~] Deliver Here",
            markerRadius = 5.0,
            interactKeyRadius = 2.0,
            MarkertType = 1,
            MarkertBob = false,
            MarkertRotate = false,
            MarkertR = 0,
            MarkertG = 0,
            MarkertB = 255,
            MarkertSize = vector3(1.5, 1.5, 1.0),
            rotX = 0.0,
            rotY = 0.0,
            rotZ = 0.0,
            accessToblackmarket = true,      -- Give acces to Blackmarket script ak4y-blackmarket.

            -- Rewards for completing the mission
            addItem = "water",               -- Item to give the player (must exist in QB inventory)
            addItemAmount = 2,               -- Amount of the item to give
            addCash = 500,                   -- Cash reward
            addBank = 1000,                  -- Bank money reward
            rewards = "1"                    -- Custom reward ID (if using a reward system like "dark-reward")
        }
    }
}

-- Add this mission to the Config.Missions table so it’s loaded by the resource
table.insert(Config.Missions, mission)