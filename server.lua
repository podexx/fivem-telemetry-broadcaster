local WebhookUrl = "https://your-render-app.onrender.com/telemetry"
local AuthToken = "secure_token_here"
local CheckInterval = 60000 -- 60 seconds

local function sendTelemetry(endpoint, payload)
    if WebhookUrl == "" then return end
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. AuthToken
    }
    
    PerformHttpRequest(WebhookUrl .. endpoint, function(statusCode, response, responseHeaders)
        if statusCode ~= 200 then
            print(("[Telemetry] Failed to broadcast to %s. Code: %s"):format(endpoint, tostring(statusCode)))
        end
    end, "POST", json.encode(payload), headers)
end

-- Heartbeat to track active player counts
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(CheckInterval)
        
        local playerCount = GetNumPlayerIndices()
        local maxPlayers = GetConvarInt("sv_maxclients", 48)
        local serverName = GetConvar("sv_hostname", "Unknown Server")
        
        local payload = {
            event = "heartbeat",
            playerCount = playerCount,
            maxPlayers = maxPlayers,
            serverName = serverName,
            timestamp = os.time()
        }
        
        sendTelemetry("/heartbeat", payload)
    end
end)

-- Player Join Alert
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local source = source
    local identifiers = GetPlayerIdentifiers(source)
    
    local payload = {
        event = "playerConnecting",
        name = name,
        source = source,
        identifiers = identifiers,
        timestamp = os.time()
    }
    
    sendTelemetry("/connect", payload)
end)

-- Player Leave Alert
AddEventHandler("playerDropped", function(reason)
    local source = source
    local name = GetPlayerName(source)
    local identifiers = GetPlayerIdentifiers(source)
    
    local payload = {
        event = "playerDropped",
        name = name,
        source = source,
        identifiers = identifiers,
        reason = reason,
        timestamp = os.time()
    }
    
    sendTelemetry("/disconnect", payload)
end)

-- Custom Alert Export (Call this from admin logs or crash handlers)
exports("BroadcastAlert", function(title, description, level)
    local payload = {
        event = "alert",
        title = title,
        description = description,
        level = level or "info",
        timestamp = os.time()
    }
    
    sendTelemetry("/alert", payload)
end)
