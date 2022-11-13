if (GetCurrentResourceName() ~= "money") then
    print("[^1DEBUG^0] Please make sure the resource name is ^3money^0 or else exports won't work.")
end

local accounts = {}


RegisterNetEvent('NAT2K15:CHECKSQL')
AddEventHandler('NAT2K15:CHECKSQL', function(steam, discord, first_name, last_name, twt, dept, dob, gender, data) 
    local src = source
    local charid = data.char_id
    local bankbalance = 0
    --[[if(accounts[src]) then
        MySQL.Async.execute("UPDATE money SET bank = @bank, amount = @amount WHERE id = @id", {["@bank"] = accounts[src].bank, ["@amount"] = accounts[src].amount, ["@id"] = charid})
        
    end]]
    --SaveToDatabase(src)
    MySQL.Async.fetchAll("SELECT * FROM money WHERE id = @id", {["@id"] = charid}, function(data) 
        if(data[1] == nil) then
            MySQL.Async.execute("INSERT INTO money (id, first, last, dept, bank) VALUES (@id, @first, @last, @dept, @bank)", {["@id"] = charid, ["@first"] = first_name, ["@last"] = last_name,  ["@dept"] = dept})
            accounts[src] = {id = charid, amount = 0, bank = bankbalance, cycle = config.deptPay[dept], dept = dept, first = first_name, last = last_name}
            exports.pefcl:loadPlayer(src, { 
                identifier = charid, 
                name = accounts[src].first .. ' ' .. accounts[src].last, 
                source = src 
            })
            SetupUI(src)
        else 
            accounts[src] = {id = charid, amount = tonumber(data[1].amount), bank = bankbalance, cycle = config.deptPay[dept], dept = dept, first = first_name, last = last_name}
            exports.pefcl:loadPlayer(src, { 
                identifier = charid, 
                name = accounts[src].first .. ' ' .. accounts[src].last, 
                source = src 
            })
            SetupUI(src)
        end
    end)
    print(src)
    TriggerClientEvent('table', src, bankbalance)
end)

function SetupUI(src)
    local bankbalance = exports.pefcl:getDefaultAccountBalance(src)
    accounts[src].bank = bankbalance.data
    TriggerClientEvent('NAT2K15:UPDATECLIENTMONEY', src, accounts[src])
end

-- if(config.enable_change_your_own_cycle) then
--     RegisterCommand('setsalary', function(source, args, message) 
--         local length = args[1];
--         if(length == nil) then return TriggerClientEvent('chatMessage', source, "[^3SYSTEM^0] Please ensure to have a valid amount.") end
--         length = tonumber(length)
--         if(length == nil) then return TriggerClientEvent('chatMessage', source, "[^3SYSTEM^0] Please ensure to have a valid amount.") end
--         if(length > 99999) then length = 99999 end
--         if(length < 0) then length = config.deptPay[accounts[source].dept] end
--         TriggerClientEvent('chatMessage', source, "[^3BANK^0] Your daily salary has been changed to ^2" .. length)
--         if(accounts[source]) then
--             accounts[source].cycle = length
--             TriggerClientEvent('NAT2K15:UPDATECLIENTMONEY', source, accounts[source])
--         end
--     end)
-- end
RegisterNetEvent("NAT2K15:GETCHARCTERS")
AddEventHandler("NAT2K15:GETCHARCTERS", function(loc, id)
    local src = source
    SaveToDatabase(src)
end)

AddEventHandler('playerDropped', function(reason) 
    local src = source
    --[[if(accounts[src]) then 
        MySQL.Async.fetchAll("SELECT * FROM money WHERE id = @id", {["@id"] = accounts[src].id}, function(data) 
            if(data[1] ~= nil) then
                MySQL.Async.execute("UPDATE money SET amount = @amount, bank = @bank WHERE id = @id", {["@id"] = accounts[src].id, ["@amount"] = tonumber(accounts[src].amount), ["@bank"] = tonumber(accounts[src].bank)})
                print("^3[Money Saving Account]^0 Saving " .. accounts[src].id .. " Name: " .. accounts[src].first .. " " .. accounts[src].last .. "Bank: " .. accounts[src].bank .. " Cash: " .. accounts[src].amount)
            end
        end)
    end]]
    SaveToDatabase(src)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        for _, players in pairs(GetPlayers()) do
                SaveToDatabase(player)
        end
    end
end)

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(config.cycle_length * 1000 * 60) -- config.cycle_length * 1000 * 60
        for _, player in ipairs(GetPlayers()) do
            player = tonumber(player)
            local src = player
            if(accounts[player]) then
                if(accounts[player].dept) then
                    pay = config.deptPay[accounts[player].dept]-- + tonumber(accounts[player].bank)
                    TriggerClientEvent('NAT2K15:UPDATEPAYCHECK', player, player, accounts[player])
                    exports.pefcl:addBankBalance(player, {
                        amount = pay,
                        message = 'Job Paycheck'
                    })

                end
            end
        end
    end
end)

function SaveToDatabase(src)
    if(accounts[src]) then
        MySQL.Async.fetchAll("SELECT * FROM money WHERE id = @id", {["@id"] = accounts[src].id}, function(data) 
            if(data[1] ~= nil) then
                MySQL.Async.execute("UPDATE money SET amount = @amount WHERE id = @id", {["@id"] = accounts[src].id, ["@amount"] = tonumber(accounts[src].amount)})
                print("^3[Money Saving Account]^0 Saving " .. accounts[src].id .. " Name: " .. accounts[src].first .. " " .. accounts[src].last .. " Cash: " .. accounts[src].amount)
                --Unload(src)
            end
        end)
        exports.pefcl:unloadPlayer(src)
        
    else
        print('No player account loaded')
    end
end

function Unload(src)
    accounts[src] = nil
end

AddEventHandler("pefcl:newAccountBalance", function(account)
    charid = account.ownerIdentifier
    bal = account.balance
    --print('Updating balance for ' .. source)
    UpdateBank(charid, bal)
end)

function UpdateBank(bankid, val)
    for i, v in pairs(accounts) do
        local acct = tostring(accounts[i].id)
        local bid = tostring(bankid)
        --print('Checking Character: ' .. acct .. ' against account update for ' .. bid)
        if acct == bid then
            --print('updating balance for ' .. bid .. ' Server id: ' .. i)
            accounts[i].bank = val
            TriggerClientEvent('NAT2K15:UPDATEPAY', i, i, accounts[i])
        end
    end
end



exports('getaccount', function(id) 
    if(accounts[id]) then
        return accounts[id]
    else
        return nil
    end
end)

exports('updateaccount', function(id, array) 
    if(accounts[id]) then
        accounts[id].amount = array.cash
        accounts[id].bank = array.bank
        TriggerClientEvent('NAT2K15:UPDATEPAY', id, id, accounts[id])
        return true
    else 
        return nil
    end
end)

exports('sendmoney', function(id, sendid, idarray, sendidarray) 
    if(accounts[id]) then
        accounts[id].amount = idarray.cash
        accounts[id].bank = idarray.bank
        TriggerClientEvent('NAT2K15:UPDATEPAY', id, id, accounts[id])
    end

    if(accounts[sendid]) then
        accounts[sendid].amount = sendidarray.cash
        accounts[sendid].bank = sendidarray.bank
        TriggerClientEvent('NAT2K15:UPDATEPAY', sendid, id, accounts[sendid])
    end
end)


exports('bankNotify', function(id, message) 
    TriggerClientEvent('NAT2K15:BANKNOTIFY', id, message)
end)

function getCash(id)
    print('getCash triggered')
    if(accounts[id]) then
        print('passed id check')
        return accounts[id].amount
    else
        print('Could not get cash, No player id found')
    end
end

function getBank(id)
    local fw = exports.framwork:GetServerFunctions()
    local charid = fw[id].charid
    print('getBank triggered')
    MySQL.Async.fetchAll("SELECT * FROM money WHERE id = @id", {["@id"] = charid}, function(data)
        return data.bank
    end)
end

function addCash(id, amount)
    if(accounts[id]) then
    newamount = accounts[id].amount + amount
    accounts[id].amount = newamount
    TriggerClientEvent('NAT2K15:UPDATEPAY', id, id, accounts[id])
    else
        print('Could not add cash, unkown error')
    end
end

function removeCash(id, amount)
    if(accounts[id]) then
        newamount = accounts[id].amount - amount
        accounts[id].amount = newamount
        TriggerClientEvent('NAT2K15:UPDATEPAY', id, id, accounts[id])
    else
        print('Could not remove cash, unkown error')
    end
end


exports('getCash', getCash)
exports('getBank', getBank)
exports('addCash', addCash)
exports('removeCash', removeCash)