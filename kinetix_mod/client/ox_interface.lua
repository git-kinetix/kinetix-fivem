local title = [[### Animation Creator
###### (powered by Kinetix)]]

function CreateRootMenu()
    lib.registerContext({
        id = 'create_anim_root',
        title = title,
        options = {
        {
            title = 'Initializing ...',
            icon = 'fa-solid fa-circle-notch',
            iconAnimation = 'spin',
        },
        }
    })
end

function CreateMainMenu(processes)
    local options = {}
    table.insert(options, {
        title = 'Create a new animation !',
        icon = 'fa-solid fa-plus',
        onSelect = function()
            local userId = GetPlayerServerId(PlayerId())
            TriggerServerEvent("requestQRCode")
          end,
      })
    local iconMap = {
        ["pending"] = {
            icon = 'fa-solid fa-hourglass-half',
            color = 'white'
        }, 
        ["processing"] = {
            icon = 'fa-solid fa-gear',
            color = 'yellow'
        }, 
        ["done"] = {
            icon = 'fa-solid fa-circle-check',
            color = 'green'
        }, 
        ["validated"] = {
            icon = 'fa-solid fa-circle-check',
            color = 'green'
        },
    }
    for _, process in pairs(json.decode(processes)) do
        table.insert(options, {
            title = process.name,
            progress = process.progression,
            colorScheme = 'blue',
            icon = iconMap[process.status].icon,
            iconColor = iconMap[process.status].color,
            arraow = true,
            metadata = {
                {label = 'Status', value = process.status},
                {label = 'Date', value = process.createdAt},
                {label = 'Uuid', value = process.emote}
              },
        })
    end

    lib.registerContext({
        id = 'create_anim_processes',
        title = title,
        options = options
      })
      lib.showContext('create_anim_processes')
end

function CreateQRCodeMenu(url)
    lib.registerContext({
        id = 'create_anim_qr_code',
        title = title,
        menu = 'create_anim_processes',
        options = {
          {
            title = 'Request animation',
            description = 'Read the QRCode with your phone and follow the instructions',
            icon = 'fa-solid fa-circle-notch',
            iconAnimation = 'spin',
            arrow = true,
            image = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=' .. url
          },
        }
      })
      lib.showContext('create_anim_qr_code')
end

function NotifyProcessUpdate(data)
    lib.notify({
        id = 'process_update',
        title = 'Emote status progression',
        description = data.emote .. ' has reached the state ' .. data.status,
        position = 'top',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
              color = '#909296'
            }
        },
        icon = 'fa-info-circle',
        iconColor = 'blue'
    })
end

function NotifyEmoteReady(data)
    lib.notify({
        title = 'Emote is ready',
        description = data.uuid .. ' is now available !',
        type = 'success',
        position = 'top',
    })
end
