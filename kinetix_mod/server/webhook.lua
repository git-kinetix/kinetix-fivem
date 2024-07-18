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

SetHttpHandler(function(req, res)
	local path = req.path
	local method = req.method
	if (path ~= "/webhook/updates") then
		res.send("Not Found: " .. method .. " " .. path, 404)
	else
		req.setDataHandler(function(data)
			req.rawBody = data
			req.body = json.decode(data)
			local statusCode, responseBody = webhookHandler(req, res)
			res.writeHead(statusCode, {
				["Access-Control-Allow-Origin"] = "*",
				["Access-Control-Allow-Headers"] = "*",
				["Content-Type"] = "application/json"
			})
			res.send(json.encode(responseBody), statusCode)
		end)
	end
end)
		
		
function webhookHandler(req, res)
    local body = req.body
	local hmac = hmac_sha256(apiKey, req.rawBody)
	local hmacHeader = req.headers['x-signature']

	if checkWebhookHMAC and hmac ~= hmacHeader then
		print("Webhook : Invalid hmac signature")
		return 403, { error = "Invalid hmac signature" }
	end
	
	local playerId = GetServerIdFromIdentifier(body.user)
    if body.status == "gta_done" then
		local configuration = exports.kinetix_mod:getConfiguration()
		if configuration.ugcValidation ~= nil and configuration.ugcValidation ~= false then
			DownloadYCD(body, playerId, true, true)
		end
    else
        if playerId ~= nil then
            if (body.status == 'baking') then
                PaywallAfter(playerId, body)
                TriggerClientEvent("process_creation", playerId, body)
            end
            TriggerClientEvent("process_update", playerId, body)
        end
    end
    return 200, {}
end