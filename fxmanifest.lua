fx_version 'cerulean'
game 'gta5'

author 'Petris <github.com/PetrisGR>'
description 'Advanced Thief Script'
version '1.0.5'

lua54 'yes'

shared_script '@ox_lib/init.lua'

shared_script('config/main.lua')

server_scripts {
    'config/framework_sv.lua',
    'server/main.lua'
}

client_script('client/main.lua')

depedency 'ox_lib'
