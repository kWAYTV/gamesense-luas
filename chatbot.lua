-- Multicolor log
local function multicolor_log(...)
    args = {...}
    len = #args
    for i=1, len do
        arg = args[i]
        r, g, b = unpack(arg)

        msg = {}

        if #arg == 3 then
            table.insert(msg, " ")
        else
            for i=4, #arg do
                table.insert(msg, arg[i])
            end
        end
        msg = table.concat(msg)

        if len > i then
            msg = msg .. "\0"
        end

        client.color_log(r, g, b, msg)
    end
end

-- Check for installed libs
local requires = {
    ['http'] = "https://gamesense.pub/forums/viewtopic.php?id=19253",
    ['chat'] = 'https://gamesense.pub/forums/viewtopic.php?id=30625',
}

for name, url in pairs(requires) do
    if not pcall(require, ('gamesense/%s'):format(name)) then
        multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'Missing dependencies found, opening them in your browser.'})
        multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, ('Link for %s library: %s'):format(name, url)})
        panorama.SteamOverlayAPI.OpenExternalBrowserURL(url)
        multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'Subscribe to the dependencies, reinject for the script to work.'})
    end
end

-- Lib imports
local panorama = panorama.open()
local http = require ("gamesense/http")
local chat = require ("gamesense/chat")

-- Contains function
local contains = function(b,c)for d=1,#b do if b[d]==c then return true end end;return false end

-- Set visible function
local function set_visible(state, ...)
    local items = {...}
    for i=1, #items do
        ui.set_visible(items[i], state)
    end
end

-- UI Interface
local interface = {
    aiChatbotCheck = ui.new_checkbox("MISC", "MISCELLANEOUS", "\aFFCCE6FFAI C\aD6BDFDFFhat\aC9C2F9FFbot"), function()
    end,
    aiChatbotCombo = ui.new_multiselect("MISC", "MISCELLANEOUS", "\aFFCCE6FFAI Chatbot \aD6BDFDFFType", {"Team", "Enemy", "Self"}),
}

-- Console start
client.exec("clear")
multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'Welcome!'})
multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'Go to misc tab to use the script.'})
multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'Available commands:'})
multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, '/apikey <key>'})

-- AI Chatbot function
chatbot = function(e)

    if not ui.get(interface.aiChatbotCheck) then return end

    local me = entity.get_local_player()
    local sent_by = valveServer and e.entity or client.userid_to_entindex(e.userid)

    local comboBox = ui.get(interface.aiChatbotCombo)
    if (contains(comboBox, "Enemy") and entity.is_enemy(sent_by)) or (contains(comboBox, "Self") and sent_by == me or (contains(comboBox, "Team") and not entity.is_enemy(sent_by))) then
        local text = e.text
        if not text or text == '' then return end
        local api_key = readfile('chatbot_api.txt')
        if api_key == "" or api_key == None then chat.print("{purple}[AI Chatbot] {white}No API Key detected! Please add one.") multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'No API Key detected! Please add one.'}) return end
        local browser_text = text:gsub(" ", "%%20")
        http.get(("https://pluto.kwayservices.top/chat?key="..api_key.."&msg=%s"):format(browser_text), function(success, response)
            if not success or response.status ~= 200 then multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 204, 153, 'Failed getting answer from chatbot api'}) return end
            local data = json.parse(response.body)
            if not data then multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 204, 153, 'Failed getting answer from chatbot api'}) return end
            local output = data.message
            if not output or output == '' or output == nil then multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 204, 153, 'Failed getting answer from chatbot api'}) return end
            if chat.is_open() then multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, "Close the chat while you use the chatbot!"}) return end
            if contains(comboBox, "Self") then client.delay_call(1.5, function() client.exec(('say "%s"'):format(output)) end) else client.exec(('say "%s"'):format(output)) end
        end)
    end

end

-- Chatbot callback function
local chatbotFunc = { ["player_chat"] = false , ["player_say"] = false}
local chatbot_callback = function()

    if not globals.mapname() then multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, "You're not in a game."}) ui.set(interface.aiChatbotCheck, false) return end

    local MatchStatsAPI = panorama.MatchStatsAPI
    valveServer = MatchStatsAPI.IsServerWhitelistedValveOfficial()

    local current_callback = valveServer and "player_chat" or "player_say"

    if not ui.get(interface.aiChatbotCheck) then
        if chatbotFunc[current_callback] then
            client.unset_event_callback(current_callback, chatbot)
            multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, "Chatbot disabled."})
            return
        else
            return
        end
    else 
        if not chatbotFunc[current_callback] then
            client.set_event_callback(current_callback, chatbot)
            multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, "Set event: " .. current_callback})
            chatbotFunc[current_callback] = true

        end

        if current_callback == "player_chat" and chatbotFunc["player_say"] then
            client.unset_event_callback("player_say", chatbot)

        elseif current_callback == "player_say" and chatbotFunc["player_chat"] then
            client.unset_event_callback("player_chat", chatbot)
        end

    end    

end

-- Save apikey
client.set_event_callback("console_input", function(cmd)
	if cmd:sub(1, 7) == "/apikey" then
		if cmd:len() > 8 then
            local apikey = cmd:sub(8, 60)
            local newapi = apikey:gsub("%s+", "")
            writefile('chatbot_api.txt', newapi)
            multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'API Key saved successfully: ' .. newapi})
		else
			multicolor_log({195, 177, 204, '[AI Chatbot] '}, {255, 255, 255, 'Save your API key with "/apikey <key>" in the console. (without the <>).'})
		end
		return true
	end
end)

-- Checkbox callback
ui.set_callback(interface.aiChatbotCheck, chatbot_callback)

-- On connect callback
client.set_event_callback("player_connect_full", function()
    local entindex = client.userid_to_entindex(e.userid)
    if entindex == entity.get_local_player() then
        return
    end
    if ui.get(interface.aiChatbotCheck) then
        chatbot_callback()
    end
end)

-- UI Handling
client.set_event_callback("paint_ui", function()
    set_visible(ui.get(interface.aiChatbotCheck), interface.aiChatbotCombo)
end)