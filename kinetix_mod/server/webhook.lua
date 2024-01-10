local webhookRouter = Router.new()

function GetServerIdFromIdentifier(identifier)
    print('fetch user with fivem id ' .. identifier)
    local wanted_id = nil

    for k, v in pairs(GetPlayers()) do
        local playerIdentifiers = GetPlayerIdentifiers(v)
        local userId = GetFiveMId(playerIdentifiers)
        print(v, userId)

        local id = tonumber(v)
        if userId == identifier then
                wanted_id = id
        end
     end

     return wanted_id;
end

webhookRouter:Post("/:param", function(req, res)
    local body = json.decode(req._RawBody)
    print(body)
    local playerId = GetServerIdFromIdentifier(body.user)

    if body.status == "gta_done" then
        DownloadYCD(body, playerId)
    else
        print('check before send')
        if playerId ~= nil then
            print('send')
            TriggerClientEvent("process_update", playerId, body)
        end
    end
    return 200, {}
end)

Server.use("/webhook", webhookRouter)
Server.listen()