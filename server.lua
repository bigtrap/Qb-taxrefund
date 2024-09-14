local QBCore = exports['qb-core']:GetCoreObject()
local Config = Config or {}

local function logTaxRefund(playerId, playerName, amount)
    local time = os.date('%Y-%m-%d %H:%M:%S')
    local logMessage = string.format("[%s] Player %s (ID: %d) received a tax refund of $%d\n", time, playerName, playerId, amount)
    
    -- Log to console if debugging is enabled
    if Config.Debug then
        print(logMessage)
    end

    -- Append the log message to the log file
    local file = io.open("tax_refund_log.txt", "a")
    if file then
        file:write(logMessage)
        file:close()
    else
        print("Error: Unable to open log file.")
    end

    -- Send log to Discord
    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Tax Refund Logger",
        embeds = {
            {
                title = "Tax Refund Issued",
                description = logMessage,
                color = 3066993,
                footer = {
                    text = "Tax Refund System",
                    icon_url = Config.DiscordServerLogo
                },
                timestamp = time
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end

local function giveTaxRefund()
    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
        local xPlayer = QBCore.Functions.GetPlayer(playerId)
        if xPlayer then
            xPlayer.Functions.AddMoney('cash', Config.TaxRefundAmount, "tax-refund")
            TriggerClientEvent('QBCore:Notify', playerId, Config.RefundMessage, "success")
            logTaxRefund(playerId, xPlayer.PlayerData.name, Config.TaxRefundAmount) -- Log the refund
        end
    end
end

Citizen.CreateThread(function()
    giveTaxRefund() -- Give refund immediately when the script starts
    while true do
        Citizen.Wait(Config.TaxRefundInterval * 1000) -- Wait for 48 hours in milliseconds
        giveTaxRefund()
    end
end)
