fx_version 'cerulean'
game 'gta5'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
}

client_script {
	'client/ox_wheel.lua',
    'client/ox_interface.lua',
    'client/core.lua',
}

server_script {
    '@fivem-webbed/server/server.lua',
    'server/version.lua',
	'server/sha256.lua',
	'server/paywall.lua',
    'server/core.lua',
    'server/webhook.lua'
}
