local url = 'https://sdk-api.dev.kinetix.tech'
local apiKey = 'a05ed51861c73f41cf321a061b518bc1'

function GetFiveMId(identifiers)
    local fivemId
    for _, identifier in pairs(identifiers) do
        local match = string.match(identifier, "^license:(%w+)$")
        if match then
            fivemId = match
            break
        end
    end
    return fivemId
end

function DownloadYCD(body, playerId)
    print('emote', body.emote)
    local route = '/v1/emotes/' .. body.emote
    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey 
    }
    PerformHttpRequest(url .. route, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        print(responseObject.name)
        local url = ''
        for _, obj in ipairs(responseObject.files) do
            if obj.extension == 'ycd' then
                url = obj.url
            end
        end

        print('download ' .. url)
        local fileName = 'stream/' .. body.emote .. '@animation.ycd'

        PerformHttpRequest(url, function(fileStatusCode, fileResponse, fileHeaders)
            print(fileStatusCode)
            if fileStatusCode == 200 then
                print('download to ', fileName)
                print('file size ', string.len(fileResponse))
                SaveResourceFile('kinetix_anim', fileName, fileResponse, string.len(fileResponse))
                ExecuteCommand('refresh')
                ExecuteCommand('restart kinetix_anim')
                if playerId ~= nil then
                    TriggerClientEvent("emote_ready", -1, body)
                    TriggerClientEvent("emote_ready_notify", playerId, body)
                end
            else
                print("Erreur lors du téléchargement du fichier : " .. fileName)
            end
        end, "GET", "", headers)

    end, "GET", "", headers)
end

RegisterNetEvent("requestInit")
AddEventHandler("requestInit", function()
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local userId = GetFiveMId(playerIdentifiers)
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

    print('requesting user creation' .. url .. userRoute)
    print(postData)
    PerformHttpRequest(url .. userRoute, function(statusCode, response, responseHeaders)
        print('status : ', statusCode)
        print('fetch processes')
        PerformHttpRequest(url .. completeRoute .. '?ongoingOnly=false', function(processStatusCode, processResponse, responseHeaders)
            print('status : ', processStatusCode)
            TriggerClientEvent("user_creation_response", sourcePlayer, processResponse)
        end, "GET", "", headers)
    end, "POST", postData, headers)
end)

RegisterNetEvent("requestQRCode")
AddEventHandler("requestQRCode", function()
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local userId = GetFiveMId(playerIdentifiers)
    local sourcePlayer = source
    local tokenRoute = '/v1/process/token'

    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey 
    }

    print('request qr code')
    PerformHttpRequest(url .. tokenRoute .. '?userId=' .. userId, function(statusCode, response, responseHeaders)
        print(statusCode)
        print(response)
        local responseObject = json.decode(response)
        TriggerClientEvent("qr_code_response", sourcePlayer, responseObject.url)
    end, "GET", "", headers)
end)

RegisterNetEvent("requestAvailableEmotes")
AddEventHandler("requestAvailableEmotes", function()
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local userId = GetFiveMId(playerIdentifiers)
    local sourcePlayer = source
    local processesRoute = '/v1/users/%s/emotes'
    local completeRoute = string.format(processesRoute, tostring(userId))

    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = apiKey 
    }
    print('fetch emotes')
    PerformHttpRequest(url .. completeRoute, function(statusCode, response, responseHeaders)
        local responseObject = json.decode(response)
        TriggerClientEvent("emotes_response", sourcePlayer, responseObject)
    end, "GET", "", headers)
end)

RegisterNetEvent("requestPlayAnim")
AddEventHandler("requestPlayAnim", function(uuid)
    print('load anim request fro ' .. uuid)
    TriggerClientEvent("play_anim", -1, uuid)
end)
