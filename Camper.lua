JSON = require 'json'
file = require 'files'

currentbid = nil
--display = texts.new(display_bidlist(), settings.camper.display)
--display:hide()

bidlist = {
    {item='rhodium ore', stack='single', minimum=10, maximum=30, price_inc=10, quantity=nil}, -- unlimited quantity -- [2026-11-22 Fix] Was: ,quantity}
    {item='ifritite', stack='single', minimum=1, maximum=2, price_inc=1, quantity=10},

}
default.camper = {
    min_cycle_delay = 60,
    max_cycle_delay = 180,
    min_bid_delay = 9,
    max_bid_delay = 12,
    open_on_load = 'example.json',
    display = {text = {size = 10,font = 'Consolas'},pos = {x = 50,y = 390}}
}

function nextBid()
    actions.tempEntry = nil
	currentbid = nil-- reset new variable
    if bidlist[actions.Ind+1] then
        actions.Ind = actions.Ind + 1
        resumeCycle(settings.camper.min_bid_delay,settings.camper.max_bid_delay)
    else
        actions.Ind = 1--added line to restart the list after you get to end.
		resumeCycle(settings.camper.min_cycle_delay,settings.camper.max_cycle_delay)
    end
end

function autoBid()
    if bidlist[actions.Ind] and not bidding then
        if not bidlist[actions.Ind].quantity or tonumber(bidlist[actions.Ind].quantity) > 0 then
            if not actions.tempEntry or actions.tempEntry.item ~= bidlist[actions.Ind].item or actions.tempEntry.stack ~= bidlist[actions.Ind].stack then actions.tempEntry = bidlist[actions.Ind] end
			if not currentbid then currentbid =  bidlist[actions.Ind].minimum + 0 end-- initiating new variable
            if ah_proposal('buy', actions.tempEntry.item, actions.tempEntry.stack, tostring(currentbid)) then  --adding my new variable
                bidding = true
                print('bid pending results %s %s':format(bidlist[actions.Ind].item,currentbid))-- added the current bid variable
            else
                table.remove(bidlist, actions.Ind) -- [2026-11-22 Fix] Was: table.remove(bidlist[actions.Ind])
                actions.Ind = actions.Ind - 1
                nextBid()
            end
            return
        else
            return nextBid()
        end
    end
    killCycle()
end

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if id == 0x04C then
        local pType = original:byte(5)
        if pType == 0x03 and actions then
            killCycle()
        elseif pType == 0x0E and actions and type(actions) == 'table' and bidding then
            if original:byte(7) == 1 then
                bidding = false
                if bidlist[actions.Ind].quantity then
                    bidlist[actions.Ind].quantity = bidlist[actions.Ind].quantity - 1
					if tonumber(bidlist[actions.Ind].quantity) == 0 then
						table.remove(bidlist, actions.Ind) -- [2026-11-22 Fix] Was: table.remove(bidlist[actions.Ind])
						actions.Ind = actions.Ind - 1
						if display then
							display:text(display_bidlist())
						end
						nextBid()
					end
					if display then
						display:text(display_bidlist())
					end
                end
                resumeCycle(settings.camper.min_bid_delay,settings.camper.max_bid_delay)
            elseif original:byte(7) == 0xC5 then
                bidding = false
                if currentbid+bidlist[actions.Ind].price_inc <= bidlist[actions.Ind].maximum then
                    currentbid = currentbid+bidlist[actions.Ind].price_inc-- changed to new variable
                    resumeCycle(settings.camper.min_bid_delay,settings.camper.max_bid_delay)
                else
                    nextBid()
                end
            end
        end
    end
end)

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
    if id == 0x04E and record then
        if original:byte(5) == 0x0E then
            local packet = packets.parse('outgoing',original)
            local stack = math.abs(tonumber(original:byte(17))-1)
            local item = res_items[packet.Item].en
            local entry = foundEntry(item:lower(),stack)
            if not entry then
                bidlist[#bidlist+1] = {item=item,minimum=packet.Price,maximum=packet.Price,stack=stack,price_inc=1,quantity=nil} -- [2026-11-22 Fix] Was: ,quantity}
                print('Added "%s" %s [%s]':format(item, comma_value(packet.Price), (stack == 1 and 'STACK' or stack == 0 and 'SINGLE' or stack:upper())))
           elseif packet.Price > bidlist[entry].maximum then
                bidlist[entry].price_inc = packet.Price - bidlist[entry].maximum
                bidlist[entry].maximum = packet.Price
            end
            if display then
                display:text(display_bidlist())
            end
        end
    end
end)

function foundEntry(item,stack)
    
    local str = stack
    if tonumber(str) then
        if str == 1 then
            str = 'stack'
        elseif str == 0 then
            str = 'single'
        end
    else
        if str == 'single' then
            stack = 0
        elseif str == 'stack' then
            stack = 1
        end
    end
    
    for k,v in ipairs(bidlist) do
        if v.item:lower() == item and (v.stack == stack or v.stack == str) then
            return k
        end
    end
    return false
end

function resumeCycle(min,max)
    if not actions.bidCycle or coroutine.status(actions.bidCycle) == 'dead' then
        actions.bidCycle = coroutine.schedule(autoBid,math.random(min,max)+math.random())
    end
end

function killCycle()
    if actions and actions.bidCycle then coroutine.close(actions.bidCycle) end
    actions = nil
end

function display_bidlist()
    local str = ''
    for k,v in ipairs(bidlist) do
        local stack = v.stack == 1 and 'stack' or v.stack == 0 and 'single' or v.stack
        str = str..'\n "%s" %s %s-%s [+%s]':format(v.item,stack,comma_value(v.minimum),comma_value(v.maximum),comma_value(v.price_inc)) 
        if v.quantity then str = str..' x%d':format(v.quantity) end
   end
    return str
end

function profile(item,stack,max,min,inc,qty) 
    local item_res = get_item_res(item) -- [2026-11-22 Fix] Was: item = get_item_res(table.concat(commands,' ',3,#commands-3))
    max = format_price(max)
    min = format_price(min)
    inc = format_price(inc)
    if item_res and stack and max and min and inc and qty then
        -- [2026-11-22 Fix] Was: print('Added Quantity %s. "%s" %s [%s]':format(commands[#commands], item.en, comma_value(price), (vol == 1 and 'STACK' or vol == 0 and 'SINGLE' or vol:upper())))
        print('Added Quantity %s. "%s" %s [%s]':format(tostring(qty), item_res.en, comma_value(max), (stack == 1 and 'STACK' or stack == 0 and 'SINGLE' or tostring(stack):upper())))
        bidlist[#bidlist+1] = {item=item_res.en,minimum=min,maximum=max,stack=stack,price_inc=inc,quantity=tonumber(qty)}            
    else
        return false
    end
    if display then
        display:text(display_bidlist())
    end
    return true
end

windower.register_event('unhandled command', function(...)
    local commands = {...}
    if not commands[1] or commands[1]:lower() ~= 'camp' then return end
    commands[2] = commands[2] and commands[2]:lower() -- [2026-11-22 Fix] Was: commands[2] = commands[2]:lower()
    if not commands[2] then
        
    elseif commands[2] == 'on' then
        if not actions and zones.ah:contains(res_zones[windower.ffxi.get_info().zone].name) then
            record = false
            if not commands[3] then
                actions = {Ind=1}
            elseif tonumber(commands[3]) then
                actions = {Ind=tonumber(commands[3])}
            end
			currentbid = nil
            autoBid()
        end
    elseif commands[2] == 'off' then
        record = false
        killCycle()
    elseif commands[2] == 'add' then
        if #commands < 5 then return end
        local qty
        if commands[#commands]:startswith('#') then 
            qty = commands[#commands]:gsub('#', '')
            commands[#commands] = nil
        end
        local price = format_price(commands[#commands])
        local vol = commands[#commands-1]
        local item = get_item_res(table.concat(commands,' ',3,#commands-2))

        if not item or not vol or not price then return end
        local entry = foundEntry(item.en:lower(),vol)
        local ind = entry or #bidlist+1
        print('Added Quantity %s. "%s" %s [%s]':format(commands[#commands], item.en, comma_value(price), (vol == 1 and 'STACK' or vol == 0 and 'SINGLE' or vol:upper())))
        bidlist[ind] = {item=item.en,minimum=price,maximum=price,stack=vol,price_inc=1,quantity=qty}
        if display then
            display:text(display_bidlist())
        end
    elseif commands[2] == 'remove' then
    elseif commands[2] == 'clear' then
        bidlist = {}
        if display then display:text(display_bidlist()) end -- [2026-11-22 Fix] Was: display:text(display_bidlist())
    elseif commands[2] == 'rec' and commands[3] and not actions then
        if commands[3] == 'on' then
            record = true
        elseif commands[3] == 'off' then
            record = false
        end
    elseif commands[2] == 'qty' and tonumber(commands[3]) then
        bidlist[#bidlist].quantity = tonumber(commands[3])
        if display then display:text(display_bidlist()) end -- [2026-11-22 Fix] Was: display:text(display_bidlist())
    elseif commands[2] == 'inc' and tonumber(commands[3]) then
        bidlist[#bidlist].price_inc = tonumber(commands[3])
        if display then display:text(display_bidlist()) end -- [2026-11-22 Fix] Was: display:text(display_bidlist())
    elseif commands[2] == 'import' then
        if commands[3] then
            local import = file.read('/data/'..table.concat(commands,' ',3)..'.json')
            if not import then return end 
            bidlist = JSON:decode(import)
            for k,v in ipairs(bidlist) do
                local item = get_item_res(v.item)
                if item then
                    bidlist[k].item = item.en
                else
                    print('Camper Error: %s is not a valid item name':format(v))
                end
            end
			if display then
				display:text(display_bidlist())
			end
        end
    elseif commands[2] == 'export' then
        if commands[3] then
            local export = file.new('/data/'..table.concat(commands,' ',3)..'.json',true)
            if not export:exists() then
                export:create()
            end
            export:write(JSON:encode_pretty(bidlist))
        end
    
    elseif commands[2] == 'exp' then
        if commands[3] then
            export = io.open(windower.addon_path .. 'data/'..table.concat(commands,' ',3)..'.json', 'w')
            export:write('[\n')
            for k,v in ipairs(bidlist) do
                if k ~= #bidlist then
                    export:write('\t%s,\n':format(JSON:encode(bidlist[k])))
                else
                    export:write('\t%s\n':format(JSON:encode(bidlist[k])))
                end
            end
            export:write(']')
            export:close()
        end
    elseif commands[2] == 'display' then
        if commands[3] and commands[3]:lower() == 'off' then
            display:hide()
        else
            if not display then
            display = texts.new(display_bidlist(), settings.camper.display)
            end
            display:text(display_bidlist())
            display:show()
        end
    end
end)

windower.register_event('outgoing text', function(original,modified,blocked)
    if original == '/logout' and actions then
		killCycle()
	end
end)

windower.register_event('zone change','logout', killCycle)