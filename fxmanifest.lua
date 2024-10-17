fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'HRStorages'
author 'HRScripts Development'
description 'Storage system'
version '1.0.0'

shared_script '@HRLib/import.lua'

client_script 'client/*.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'config.lua',
    'client/bridge.lua',
    'translation.lua'
}

dependencies {
    'HRLib',
    'object_gizmo',
    'ox_inventory'
}