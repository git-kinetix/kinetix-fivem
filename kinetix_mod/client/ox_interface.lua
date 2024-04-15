local title = [[
#### Emote Creator
]]

local titleTemplate = [[
#### Emote %s
]]
local contentTemplate = [[You are going to delete the emote "%s".

This action cannot be reverted.]]

local QRCodeTemplate = [[Scan this QR and follow the instructions.

![QRCode](https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=%s)]]


local EmoteValidationTemplate = [[This is your emote preview.

Do you validate the output or do you want to retry the process.

![QRCode](%s)
You have %s retry left.]]

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

function CreateQRCodeAlert(url)
	isQRCodeAlertOpened = true
	local alert = lib.alertDialog({
		header = 'Create Emote',
		content = string.format(QRCodeTemplate, url),
		centered = true,
		size = 'sm',
		labels = {
			confirm = 'cancel',
			cancel = true,
		}
	})
	if alert ~= nil then
		isQRCodeAlertOpened = false
	end
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

function CreateProcessValidationMenu(process)
	local configuration = exports.kinetix_mod:getConfiguration()
    local retryCount = 0
	if configuration.ugcValidation.maxRetry ~= nil then
		retryCount = configuration.ugcValidation.maxRetry - process.hierarchy.parents;
	end
	if retryCount < 0 then retryCount = 0 end
	local canCancel = retryCount > 0
	local alert = lib.alertDialog({
		header = 'Validate Emote',
		content = string.format(EmoteValidationTemplate, process.thumbnail, retryCount ),
		centered = true,
		cancel = canCancel,
		size = 'md',
		labels = {
			confirm = 'Validate',
			cancel = 'Retake',
		}
	})

	if alert ~= 'confirm' then
		if canCancel == false then
			lib.showContext('create_anim_root')
			TriggerServerEvent("requestInit")
			return
		end
		local confirmAlert = lib.alertDialog({
			header = 'Retake Emote',
			content = 'Are you sure you want to retry the process ?',
			centered = true,
			cancel = true,
			size = 'md',
		})
		if confirmAlert ~= 'confirm' then
			lib.showContext('create_anim_root')
			TriggerServerEvent("requestInit")
		else
			TriggerServerEvent('requestRetake', process.uuid)
		end
	else
		TriggerServerEvent('requestValidate', process.uuid)
	end

end

function RequestEmotePreview(process)
	TriggerServerEvent('requestEmotePreview', process)
end

local processesCache = {}

function CreateEmoteCreatorMenu(processes)
    local options = {}
	processesCache = processes
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
            color = 'white',
			description = 'Servers are warming up ...'
        },
        ["processing"] = {
            icon = 'fa-solid fa-gear',
            color = 'yellow',
			description = "Servers are processing ...",
			progress = true,
        },
        ["done"] = {
            icon = 'fa-solid fa-circle-check',
            color = 'green',
			onSelect = RequestEmotePreview,
			arrow = true,
			description = "Waiting for validation ..."
        },
        ["validated"] = {
            icon = 'fa-solid fa-circle-check',
            color = 'green',
			description = "Ready to use !"
        },
		["failed"] = {
            icon = 'fa-solid fa-circle-xmark',
            color = 'red',
			description = "An error occured !"
        },
		["rejected"] = {
            icon = 'fa-solid fa-circle-xmark',
            color = 'red',
			onSelect = function(process)
				TriggerServerEvent('requestRetake', process.uuid)
			end,
			arrow = true,
			description = "Waiting for a new video ..."
        },
    }

    for _, process in pairs(json.decode(processes)) do
		local arrow = process.status == 'done'
		local icon
		local description

		local hasChildren = false
		if process.hierarchy ~= nil then
			if process.hierarchy.children > 0 then
				hasChildren = true
			end
		end

		print(process.status)
		if hasChildren == true then icon = 'fa-solid fa-arrows-rotate' else icon = iconMap[process.status].icon end
		if hasChildren == true then description = 'Process has been retaken' else description = iconMap[process.status].description end
		if hasChildren == false then
			table.insert(options, {
				title = process.name,
				progress = iconMap[process.status].progress and process.progression,
				description = description,
				colorScheme = 'blue.5',
				disabled = disabled,
				icon = icon,
				iconColor = iconMap[process.status].color,
				arrow = iconMap[process.status].arrow,
				args = process,
				onSelect = iconMap[process.status].onSelect,
				metadata = {
					{label = 'Status', value = process.status},
					{label = 'Date', value = process.createdAt},
					{label = 'Uuid', value = process.emote}
				  },
			})
		end
    end

    lib.registerContext({
        id = 'create_anim_processes',
        title = title,
        options = options,
		menu = 'main_menu'
      })
      lib.showContext('create_anim_processes')
end

local isQRCodeAlertOpened = false

function CreateQRCodeMenu(url)
    lib.registerContext({
        id = 'create_anim_qr_code',
        title = title,
        menu = 'create_anim_processes',
        options = {
          {
            title = 'Request emote',
            description = 'Read the QR code with your phone and follow the instructions',
            icon = 'fa-solid fa-circle-notch',
            iconAnimation = 'spin',
            arrow = true,
            image = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=' .. url,
			onSelect = function()
				CreateQRCodeAlert()
			end
          },
        }
      })
      lib.showContext('create_anim_qr_code')
end

function CreateErrorMenu(statusCode)
	local errorMap = {
		[403] = {
			title = "Plan limit reached",
			description = "You cannot create any new emote."
		},
		[429] = {
			title = "Rate limiting reached",
			description = "You cannot do new request for the moment."
		}
	}
	local currentError = errorMap[statusCode]
    lib.registerContext({
        id = 'error_qr_code',
        title = title,
        menu = 'create_anim_processes',
        options = {
          {
            title = currentError.title,
            description = currentError.description,
            icon = 'fa-solid fa-circle-xmark',
			iconColor = 'red'
          },
        }
      })
      lib.showContext('error_qr_code')
end

function NotifyProcessUpdate(data)
	if data.status == 'validated' then return end
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
