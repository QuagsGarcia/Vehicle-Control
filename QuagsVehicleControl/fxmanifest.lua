fx_version 'cerulean'
games      { 'gta5' }
lua54 'yes'

author 'Manvaril'
description 'Vehicle Door/Window/Seat/Engine/Dome Light NUI script'
version '1.1.5'

ui_page "html/vehui.html"

files {
  "html/vehui.html",
  "html/style.css",
  "html/img/*.png"
}

client_scripts {
  'config.lua',
  'client.lua'
}

server_script "server.lua"

export {
  'openExternal'
}
shared_scripts {
  '@ox_lib/init.lua'
}