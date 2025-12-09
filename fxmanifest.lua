fx_version 'cerulean'

author 'DarkSmite'
description 'Dark Missions'
version '1.2'

game 'gta5'
lua54 'yes'

client_scripts {
    'client/ped.lua',
    'client/main.lua',
    'client/notifys.lua',
    'client/customtriggers.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
    'missions/*.lua'
}

files {
    'ui/**'
}

ui_page 'ui/index.html'

dependencies {
    'qb-core',
    'ox_lib',
    'qb-target',
    'oxmysql'
}


escrow_ignore {
    'config.lua',
    'client/notifys.lua',
    'client/customtrigger.lua',
    'missions/*.lua'
}