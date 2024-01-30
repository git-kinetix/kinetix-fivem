local url = 'https://sdk-api.kinetix.tech'
local apiKey = ''

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

function DownloadYCD(body, playerId)
    local route = '/v1/emotes/' .. body.emote
    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey 
    }
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
                ExecuteCommand('refresh')
                ExecuteCommand('restart kinetix_anim')
                if playerId ~= nil then
                    TriggerClientEvent("emote_ready", -1, body)
                    TriggerClientEvent("emote_ready_notify", playerId, body)
                end
            else
                print("Error downloading the file : " .. fileName)
            end
        end, "GET", "", headers)

    end, "GET", "", headers)
end

RegisterNetEvent("requestInit")
AddEventHandler("requestInit", function()
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local userId = GetLicense(playerIdentifiers)
    local sourcePlayer = source
    local userRoute = '/v1/virtual-world/users'
    local processesRoute = '/v1/users/%s/processes'
    local completeRoute = string.format(processesRoute, tostring(userId))
    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey 
    }

    local postData = json.encode({
        id = userId,
    })

    PerformHttpRequest(url .. userRoute, function(statusCode, response, responseHeaders)
        PerformHttpRequest(url .. completeRoute .. '?ongoingOnly=false', function(processStatusCode, processResponse, responseHeaders)
            TriggerClientEvent("user_creation_response", sourcePlayer, processResponse)
        end, "GET", "", headers)
    end, "POST", postData, headers)
end)

RegisterNetEvent("requestQRCode")
AddEventHandler("requestQRCode", function()
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local userId = GetLicense(playerIdentifiers)
    local sourcePlayer = source
    local tokenRoute = '/v1/process/token'

    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey 
    }

    PerformHttpRequest(url .. tokenRoute .. '?userId=' .. userId, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        TriggerClientEvent("qr_code_response", sourcePlayer, responseObject.url)
    end, "GET", "", headers)
end)

RegisterNetEvent("requestAvailableEmotes")
AddEventHandler("requestAvailableEmotes", function()
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local userId = GetLicense(playerIdentifiers)
    local sourcePlayer = source
    local processesRoute = '/v1/users/%s/emotes'
    local completeRoute = string.format(processesRoute, tostring(userId))

    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey 
    }
    PerformHttpRequest(url .. completeRoute, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        TriggerClientEvent("emotes_response", sourcePlayer, responseObject)
    end, "GET", "", headers)
end)
