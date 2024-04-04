local url = 'https://sdk-api.kinetix.tech'
local apiKey = 'PLACE YOUR API KEY HERE !'

local headers = {
    ["Content-Type"] = "application/json",
    ["x-api-key"] = apiKey
}

local userExists = false

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

function GetAvailableEmotes(userId, callback)
    local emotesRoutes = string.format('/v1/users/%s/emotes', tostring(userId))
    PerformHttpRequest(url .. emotesRoutes, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        -- Ensure file is properly loaded, if the webhook call was missed
		local hasToRestart = false
        for _, emote in pairs(responseObject) do
            local fileName = 'stream/' .. emote.data.uuid .. '@animation.ycd'
            if not file_exists(fileName) then
				hasToRestart = true
                DownloadYCD({ emote = emote.data.uuid }, source, true, false)
            end
        end
		if hasToRestart == true then
			ExecuteCommand('refresh')
			ExecuteCommand('restart kinetix_anim')
			TriggerClientEvent("emote_ready", -1, {})
		end
        callback(responseObject)
    end, "GET", "", headers)
end

function GetUserId(source)
    local playerIdentifiers = GetPlayerIdentifiers(source)
    return GetLicense(playerIdentifiers)
end

function RequestQRCode(userId, callback)
    local tokenRoute = '/v1/process/token'

    PerformHttpRequest(url .. tokenRoute .. '?userId=' .. userId, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        callback(statusCode, responseObject?.url)
    end, "GET", "", headers)
end

-- Called before a QR Code request. Add your paywall conditions here
function BeforeQRCode(userId, callback)
    callback()
    -- or something like
    -- TriggerClientEvent("qr_code_error", sourcePlayer, "Paywall limit")
end

-- Called after a QR Code request. Store your paywall state here
function AfterQRCode(userId, statusCode, callback)
    callback()
end

function DownloadYCD(body, playerId, refresh, notify)
    local route = '/v1/emotes/' .. body.emote
    PerformHttpRequest(url .. route, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        local url = ''
        for _, obj in ipairs(responseObject.files) do
            if obj.extension == 'ycd' then
                url = obj.url
            end
        end

        local fileName = 'stream/' .. body.emote .. '@animation.ycd'

        PerformHttpRequest(url, function(fileStatusCode, fileResponse, fileHeaders)
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
            else
                print("Error downloading the file : " .. fileName)
            end
        end, "GET", "", headers)

    end, "GET", "", headers)
end

function DeleteEmote(userId, emoteUuid, callback)
    local deletionRoute = string.format('/v1/users/%s/emotes/%s', tostring(userId), emoteUuid)

    local postData = json.encode({
        reason = 'User deletion request.',
    })

    PerformHttpRequest(url .. deletionRoute, function(statusCode, response, responseHeaders)
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
    BeforeQRCode(userId, function()
        RequestQRCode(userId, function(statusCode, qrCodeUrl)
            AfterQRCode(userId, statusCode, function()
                if statusCode == 403 then
                    return TriggerClientEvent("qr_code_error", _source)
                elseif statusCode == 200 then
                    return TriggerClientEvent("qr_code_response", _source, qrCodeUrl)
				end
            end)
        end)
    end)
end)

RegisterNetEvent("requestAvailableEmotes")
AddEventHandler("requestAvailableEmotes", function()
    local _source = source
    local userId = GetUserId(_source)
    local playerIdentifiers = GetPlayerIdentifiers(_source)
    local userId = GetLicense(playerIdentifiers)
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
    local playerIdentifiers = GetPlayerIdentifiers(_source)
    local userId = GetLicense(playerIdentifiers)
	DeleteEmote(userId, data.uuid, function()
			GetAvailableEmotes(userId, function(emotes)
			TriggerClientEvent("emotes_response", _source, emotes)
			TriggerClientEvent("reopen_bag", _source)
		end)
	end)
end)