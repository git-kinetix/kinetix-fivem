-- Called before a QR Code request. Add your paywall conditions here
function PaywallBefore(userId, sourceId, callback)
	-- Check palyer's balance and call callback()
    callback()
	-- Or send error message
    -- TriggerClientEvent("paywall_error", sourceId, { title = "Paywall limit", description = "Unsuficient funds" })
end

-- Called after a process has been launched. Store your paywall state here
function PaywallAfter(userId, payload)
    -- Deduce player's balance
end
