apiKey = 'PLACE YOUR API KEY HERE !'
checkWebhookHMAC = true

local url = 'https://sdk-api.kinetix.tech'
local configuration = {}

local headers = {
    ["Content-Type"] = "application/json",
    ["x-api-key"] = apiKey
}

local userExists = false

GetConfig()

function GetLicense(identifiers)
    local license
    for _, identifier in pairs(identifiers) do
        local match = string.match(identifier, "^license:(%w+)$")
        if match then
            license = match
            break
        end
    end
    return license
end

function GetUserId(source)
    local playerIdentifiers = GetPlayerIdentifiers(source)
    return GetLicense(playerIdentifiers)
end

function file_exists(name)
   local dir = GetResourcePath('kinetix_anim')
   local correctedDir = string.gsub(dir, "//", "/")
   local f = io.open(correctedDir .. '/' .. name, "r")
   return f ~= nil and io.close(f)
end

function CreateUser(userId, callback)
    if userExists == true then
        return callback()
    end

    local userRoute = '/v1/virtual-world/users'
    local postData = json.encode({
        id = userId,
    })

    PerformHttpRequest(url .. userRoute, function(statusCode, response, responseHeaders)
        return callback()
    end, "POST", postData, headers)
end

function GetProcesses(userId, callback)
    local processesRoute = string.format('/v2/users/%s/processes', tostring(userId))

	local today = os.date("*t")
	today.day = today.day - 1
    local yesterday = os.time(today)
	local since = os.date("%Y-%m-%dT%H:%M:%SZ", yesterday)

    local postData = json.encode({
        id = userId,
    })

    PerformHttpRequest(url .. processesRoute .. '?since=' .. since, function(processStatusCode, processResponse, responseHeaders)
        callback(processResponse)
    end, "GET", "", headers)
end

function GetConfig(callback)
    local configRoute = string.format('/v1/virtual-world/config', tostring(userId))

    PerformHttpRequest(url .. configRoute, function(statusCode, response, responseHeaders)
        if statusCode == 403 then
            print("^1Could not authenticate to Kinetix API. Make sure your API Key is properly set.^0")
        end
        callback(response)
    end, "GET", "", headers)
end

function GetAvailableEmotes(userId, callback)
    local emotesRoutes = string.format('/v1/users/%s/emotes', tostring(userId))
    PerformHttpRequest(url .. emotesRoutes, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        -- Ensure file is properly loaded, if the webhook call was missed
		local hasToRestart = false
		local missing = 0
		local processed = 0
		for _, emote in pairs(responseObject) do
			local fileName = 'stream/' .. emote.data.uuid .. '@animation.ycd'
			if not file_exists(fileName) then
				missing = missing + 1
			end
		end
        for _, emote in pairs(responseObject) do
            local fileName = 'stream/' .. emote.data.uuid .. '@animation.ycd'
            if not file_exists(fileName) then
                DownloadYCD({ emote = emote.data.uuid }, source, false, false, function(response)
					processed = processed + 1
					if response == true then
						hasToRestart = true
					end
					if missing == processed and hasToRestart == true then
						ExecuteCommand('refresh')
						ExecuteCommand('restart kinetix_anim')
						TriggerClientEvent("emote_ready", -1, {})
					end
				end)
            end
        end
        callback(responseObject)
    end, "GET", "", headers)
end

function RequestQRCode(userId, callback)
    local tokenRoute = '/v1/process/token'
    PerformHttpRequest(url .. tokenRoute .. '?userId=' .. userId, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        callback(statusCode, responseObject?.url)
    end, "GET", "", headers)
end

function DownloadYCD(body, playerId, refresh, notify, cb)
    local route = '/v1/emotes/' .. body.emote
    PerformHttpRequest(url .. route, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        local fileUrl = ''
        for _, obj in ipairs(responseObject.files) do
            if obj.extension == 'ycd' then
                fileUrl = obj.url
            end
        end

        local fileName = 'stream/' .. body.emote .. '@animation.ycd'
		if fileUrl == '' then
			if cb ~= nil then
				cb(false)
			end
			return
		end

        PerformHttpRequest(fileUrl, function(fileStatusCode, fileResponse, fileHeaders)
            if fileStatusCode == 200 then
				SaveResourceFile('kinetix_anim', fileName, fileResponse, string.len(fileResponse))
				if refresh == true then
					ExecuteCommand('refresh')
					ExecuteCommand('restart kinetix_anim')
				end
                if playerId ~= nil and notify == true then
					TriggerClientEvent("emote_ready", -1, body)
                    TriggerClientEvent("emote_ready_notify", playerId, body)
                end
				if cb ~= nil then
					cb(true)
				end
            else
				if cb ~= nil then
					cb(false)
				end
                print("Error downloading the file : " .. fileName)
            end
        end, "GET", "", headers)

    end, "GET", "", headers)
end

function ShareEmoteWithUsers(userIds, emoteUuid)
    for userId in userIds do
        ShareEmoteWithUser(userId, emoteUuid)
    end
end

function ShareEmoteWithUser(userId, emoteUuid, cb)
    local addEmoteRoute = string.format('/v1/users/%s/emotes/%s', tostring(userId), emoteUuid)

    PerformHttpRequest(url .. addEmoteRoute, function(statusCode, response)
        cb(response)
    end, "POST", "", headers)
end

function DeleteEmote(userId, emoteUuid, callback)
    local deletionRoute = string.format('/v1/users/%s/emotes/%s', tostring(userId), emoteUuid)

    local postData = json.encode({
        reason = 'User deletion request.',
    })

    PerformHttpRequest(url .. deletionRoute, function(statusCode, response, responseHeaders)
		if statusCode == 200 then

		end
        callback(response)
    end, "DELETE", postData, headers)
end

function RenameEmote(userId, emoteUuid, name, callback)
    local updateRoute = string.format('/v1/users/%s/emotes/%s', tostring(userId), emoteUuid)

    local postData = json.encode({
        name = name,
    })

    PerformHttpRequest(url .. updateRoute, function(statusCode, response, responseHeaders)
        callback(response)
    end, "PUT", postData, headers)
end

function GetEmotePreview(emoteUuid, callback)
    local updateRoute = string.format('/v1/emotes/%s', emoteUuid)

    PerformHttpRequest(url .. updateRoute, function(statusCode, response, responseHeaders)
        callback(response)
    end, "GET", "", headers)
end

function RetakeProcess(processUuid, callback)
    local retakeRoute = string.format('/v1/process/%s/retake', processUuid)

    PerformHttpRequest(url .. retakeRoute, function(statusCode, response, responseHeaders)
        callback(response)
    end, "POST", "", headers)
end

function ValidateProcess(processUuid, callback)
    local validateRoute = string.format('/v1/process/%s/validate', processUuid)

    PerformHttpRequest(url .. validateRoute, function(statusCode, response, responseHeaders)
        callback(response)
    end, "POST", "", headers)
end

RegisterNetEvent("requestInit")
AddEventHandler("requestInit", function()
    local _source = source
    local userId = GetUserId(_source)

    CreateUser(userId, function()
        userExists = True
        GetProcesses(userId, function(processes)
            TriggerClientEvent("user_creation_response", _source, processes)
        end)
    end)
end)

RegisterNetEvent("requestQRCode")
AddEventHandler("requestQRCode", function()
    local _source = source
    local userId = GetUserId(_source)
    PaywallBefore(userId, function()
        RequestQRCode(userId, function(statusCode, qrCodeUrl)
            if statusCode >= 400 then
                return TriggerClientEvent("qr_code_error", _source, statusCode)
            elseif statusCode == 200 then
                return TriggerClientEvent("qr_code_response", _source, qrCodeUrl)
            end
        end)
    end)
end)

RegisterNetEvent("requestAvailableEmotes")
AddEventHandler("requestAvailableEmotes", function()
    local _source = source
    local userId = GetUserId(_source)

    GetAvailableEmotes(userId, function(emotes)
        TriggerClientEvent("emotes_response", _source, emotes)
    end)
end)

RegisterNetEvent("renameEmote")
AddEventHandler("renameEmote", function(data)
    local _source = source
    local userId = GetUserId(_source)
    local playerIdentifiers = GetPlayerIdentifiers(_source)
    local userId = GetLicense(playerIdentifiers)
    RenameEmote(userId, data.uuid, data.name, function()
			GetAvailableEmotes(userId, function(emotes)
			TriggerClientEvent("emotes_response", _source, emotes)
			TriggerClientEvent("reopen_bag", _source)
		end)
	end)
end)

RegisterNetEvent("deleteEmote")
AddEventHandler("deleteEmote", function(data)
    local _source = source
    local userId = GetUserId(_source)

	DeleteEmote(userId, data.uuid, function()
			GetAvailableEmotes(userId, function(emotes)
			TriggerClientEvent("emotes_response", _source, emotes)
			TriggerClientEvent("reopen_bag", _source)
		end)
	end)
end)

AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
		return
	end
	GetConfig(function(config)
		Wait(1000) -- Ensure the client has time to restart as well
		TriggerClientEvent("config", -1, config)
		configuration = config
	end)
end)

RegisterNetEvent("requestEmotePreview")
AddEventHandler('requestEmotePreview', function(process)
	local _source = source
	GetEmotePreview(process.emote, function(response)
		local emote = json.decode(response)
		local icon
		for _, obj in ipairs(emote.files) do
            if obj.extension == 'gif' and obj.name == 'thumbnail' then
                icon = obj.url
            end
        end
		TriggerClientEvent("emote_preview", _source, {uuid = process.uuid, emote = process.emote, thumbnail = icon, hierarchy = process.hierarchy})
	end)
end)


RegisterNetEvent("requestRetake")
AddEventHandler('requestRetake', function(processUuid)
	local _source = source
	RetakeProcess(processUuid, function(response)
		TriggerClientEvent("retake_process", _source, response)
	end)
end)

RegisterNetEvent("requestValidate")
AddEventHandler('requestValidate', function(processUuid)
	local _source = source
	ValidateProcess(processUuid, function(response)
		DownloadYCD(json.decode(response), _source, true, true)
	end)
end)

RegisterNetEvent("requestConfiguration")
AddEventHandler("requestConfiguration", function(processUuid)
	local _source = source
	GetConfig(function(config)
		TriggerClientEvent("config", _source, config)
		configuration = config
	end)
end)

exports("getConfiguration", function()
    return configuration
end)