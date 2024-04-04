local titleTemplate = [[
#### Emote %s
]]
local contentTemplate = [[You are going to delete the emote "%s".

This action cannot be reverted.]]

function GetTitle(name)
	return string.format(titleTemplate, name)
end

function CreateRootMenu()
    lib.registerContext({
        id = 'create_anim_root',
        title = GetTitle("Menu"),
        options = {
        {
            title = 'Loading ...',
            icon = 'fa-solid fa-circle-notch',
            iconAnimation = 'spin',
        },
        }
    })
end

function CreateMainMenu()
    lib.registerContext({
        id = 'main_menu',
        title = GetTitle("Menu"),
        options = {
			{
			    title = 'Emote Creator',
				icon = 'fa-solid fa-plus',
				onSelect = function()
					lib.showContext('create_anim_root')
					TriggerServerEvent("requestInit")
				  end,
			},
			{
			    title = 'Emote Bag',
				icon = 'fa-solid fa-bag-shopping',
				onSelect = function()
					lib.showContext('emote_bag_menu')
				  end,
			}
		}
      })
      lib.showContext('main_menu')
end

function OpenEmoteBagMenu()
	lib.showContext('emote_bag_menu')
end

local selectedBagEmoteUuid = nil

function CreateEmoteBagMenu(emotes)
	local bagOptions = {}
    for _, emote in pairs(emotes) do
		local icon
		for _, obj in ipairs(emote.data.files) do
            if obj.extension == 'gif' and obj.name == 'thumbnail' then
                icon = obj.url
            end
        end

		table.insert(bagOptions, {
		  title = emote.data.name,
		  icon = icon,
		  arrow = true,
		  description = "Created at : " .. emote.data.createdAt,
		  onSelect = function()
				lib.registerContext({
					id = 'emote_bag_menu_interactions',
					title = GetTitle("Bag"),
					options = {
						{
						  title = 'Delete',
						  icon = 'fa-solid fa-trash',
						  args = emote.data,
						  onSelect = function(data)
							local alert = lib.alertDialog({
								header = 'Confirm deletion',
								content = string.format(contentTemplate, data.name),
								centered = true,
								cancel = true
							})
							if alert == 'confirm' then
								TriggerServerEvent('deleteEmote', { uuid = data.uuid })
								lib.showContext('create_anim_root')
							else
								lib.showContext('emote_bag_menu')
							end

						  end
						},
						{
						  title = 'Rename',
						  icon = 'fa-solid fa-pencil',
						  args = emote.data,
						  onSelect = function(data)
							local input = lib.inputDialog('Rename emote', {
								{type = 'input', label = 'New name', required = true, min = 4, max = 16}
							})
							if not input then
								lib.showContext('emote_bag_menu')
								return
							end
							TriggerServerEvent('renameEmote', { uuid = data.uuid, name = input[1] })
							lib.showContext('create_anim_root')
						  end
						}
					},
					menu = 'emote_bag_menu'
				  })
				lib.showContext('emote_bag_menu_interactions')
		  end,
		})
    end

	lib.registerContext({
		id = 'emote_bag_menu',
		title = GetTitle("Bag"),
		options = bagOptions,
		menu = 'main_menu'
	  })

end

function CreateEmoteCreatorMenu(processes)
    local options = {}
    table.insert(options, {
        title = 'Create a new emote',
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
            colorScheme = 'blue.5',
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
        title = GetTitle('Creator'),
        options = options,
		menu = 'main_menu'
      })
      lib.showContext('create_anim_processes')
end

function CreateQRCodeMenu(url)
    lib.registerContext({
        id = 'create_anim_qr_code',
        title = GetTitle('Creator'),
        menu = 'create_anim_processes',
        options = {
          {
            title = 'Request emote',
            description = 'Read the QR code with your phone and follow the instructions',
            icon = 'fa-solid fa-circle-notch',
            iconAnimation = 'spin',
            arrow = true,
            image = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=' .. url
          },
        }
      })
      lib.showContext('create_anim_qr_code')
end

function CreateErrorMenu()
    lib.registerContext({
        id = 'error_qr_code',
        title = GetTitle('Creator'),
        menu = 'create_anim_processes',
        options = {
          {
            title = 'Plan limit reached',
            description = 'You cannot create any new emote.',
            icon = 'fa-solid fa-circle-xmark',
			iconColor = 'red'
          },
        }
      })
      lib.showContext('error_qr_code')
end

function NotifyProcessUpdate(data)
    lib.notify({
        id = 'process_update',
        title = 'Emote status progression',
        description = data.name .. ' has reached the state ' .. data.status,
        position = 'top',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
              color = '#909296'
            }
        },
        icon = 'fa-info-circle',
        iconColor = '#228be6'
    })
end

function NotifyEmoteReady(data)
    lib.notify({
        title = 'Emote is ready',
        description = data.name .. ' is now available !',
        type = 'success',
        position = 'top',
    })
end
