local configuration

TriggerServerEvent("requestAvailableEmotes")
TriggerServerEvent("requestConfiguration")

CreateEmoteWheel({})
CreateEmoteBagMenu({})

RegisterCommand('kinetix_anim', function(source, params)
	local dictName = params[1] .. '@animation'
    local animName = 'clip'
	local retry = 0

	if not HasAnimDictLoaded(dictName) then
		RequestAnimDict(dictName)
    end

    while not HasAnimDictLoaded(dictName) and retry < 50 do
        Wait(0)
		retry = retry + 1
    end
	retry = 0
	ClearPedTasks(PlayerPedId())
	local animFlag = IsPedInAnyVehicle(PlayerPedId()) == 1 and 16 + 32 or 0
	if IsPedOnAnyBike(PlayerPedId()) then return end
	TaskPlayAnim(PlayerPedId(), dictName, animName, 8.0, -8.0, -1, animFlag, 0.0, false, false, false)
end)

RegisterCommand('create_emote', function()
    CreateMainMenu()
end, false)
RegisterKeyMapping('create_emote', 'Open emote creation menu', 'keyboard', 'F5')

CreateRootMenu()

RegisterNetEvent("user_creation_response")
AddEventHandler("user_creation_response", function(processes)
    CreateEmoteCreatorMenu(processes)
end)

RegisterNetEvent("qr_code_response")
AddEventHandler("qr_code_response", function(url)
    CreateQRCodeAlert(url)
end)

RegisterNetEvent("qr_code_error")
AddEventHandler("qr_code_error", function(statusCode)
    CreateErrorMenu(statusCode)
end)

RegisterNetEvent("paywall_error")
AddEventHandler("paywall_error", function(error)
    CreateErrorMenu(nil, error)
end)

RegisterNetEvent("process_update")
AddEventHandler("process_update", function(data)
    NotifyProcessUpdate(data)
	local openedMenuId = lib.getOpenContextMenu()
	if data.status == 'baking' and isQRCodeAlertOpened == true then
		lib.closeAlertDialog()
		return
	end

	if openedMenuId == 'create_anim_processes' then
		TriggerServerEvent("requestInit")
	end
end)

RegisterNetEvent("emote_ready")
AddEventHandler("emote_ready", function(data)
    TriggerServerEvent("requestAvailableEmotes")
	if data.emote ~= nil then
		RequestAnimDict(data.emote .. "@animation")
	end
end)

RegisterNetEvent("emote_ready_notify")
AddEventHandler("emote_ready_notify", function(data)
	NotifyEmoteReady(data)
end)

RegisterNetEvent("emotes_response")
AddEventHandler("emotes_response", function(data)
    CreateEmoteWheel(data)
	CreateEmoteBagMenu(data)
end)

RegisterNetEvent("reopen_bag")
AddEventHandler("reopen_bag", function(data)
	OpenEmoteBagMenu()
end)

RegisterNetEvent("config")
AddEventHandler("config", function(data)
	local config = json.decode(data)
	local ugcValidation = config.ugcValidation
	configuration = config
end)


RegisterNetEvent("emote_preview")
AddEventHandler("emote_preview", function(data)
	CreateProcessValidationMenu(data)
end)

RegisterNetEvent("retake_process")
AddEventHandler("retake_process", function(data)
	local retakeData = json.decode(data)
	CreateQRCodeAlert(retakeData.url)
end)

exports("getConfiguration", function()
    return configuration
end)