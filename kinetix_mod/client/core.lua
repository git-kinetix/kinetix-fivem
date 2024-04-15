TriggerServerEvent("requestAvailableEmotes")

local configuration

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

RegisterCommand('ext', function(source, params)
	SetFrontendActive(false)
end)



local keybindControls = {
	["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["Backspace"] = 177, ["Tab"] = 37, ["q"] = 44, ["w"] = 32, ["e"] = 38, ["r"] = 45, ["t"] = 245, ["y"] = 246, ["u"] = 303, ["p"] = 199, ["["] = 39, ["]"] = 40, ["Enter"] = 18, ["CapsLock"] = 137, ["a"] = 34, ["s"] = 8, ["d"] = 9, ["f"] = 23, ["g"] = 47, ["h"] = 74, ["k"] = 311, ["l"] = 182, ["Shift"] = 21, ["z"] = 20, ["x"] = 73, ["c"] = 26, ["v"] = 0, ["b"] = 29, ["n"] = 249, ["m"] = 244, [","] = 82, ["."] = 81, ["Home"] = 213, ["PageUp"] = 10, ["PageDown"] = 11, ["Delete"] = 178
}

local p = nil
local t = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local creationMenuKey = keybindControls['F5']
        if IsControlPressed(0, creationMenuKey) then
            CreateMainMenu()
		end
    end
end)

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