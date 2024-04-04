local webhookRouter = Router.new()

function GetServerIdFromIdentifier(identifier)
    local wanted_id = nil

    for k, v in pairs(GetPlayers()) do
        local userId = GetUserId(v)

        local id = tonumber(v)
        if userId == identifier then
                wanted_id = id
        end
     end

     return wanted_id;
end

webhookRouter:Post("/:param", function(req, res)
    local body = req._Body
    local playerId = GetServerIdFromIdentifier(body.user)

    if body.status == "gta_done" then
        DownloadYCD(body, playerId, true, true)
    else
        if playerId ~= nil then
            TriggerClientEvent("process_update", playerId, body)
        end
    end
    return 200, {}
end)

Server.use("/webhook", webhookRouter)
Server.listen()