-- Variables and UI definitions
local did_fire, did_fire_time = false, 0
local interface = {
    switch = ui.new_checkbox('MISC', 'Miscellaneous', 'Crouch on shot'),
    hotkey = ui.new_hotkey('MISC', 'Miscellaneous', 'Crouch on shot hotkey', true),
    label = ui.new_label('MISC', 'Miscellaneous', 'The number is divided by 100 to make decimals.'),
    delay = ui.new_slider('MISC', 'Miscellaneous', 'Crouch delay', 0, 100, 37, true, '', 1),
}

-- UI set visible function
local set_visible = function(state, ...)
    local items = {...}
    for i=1, #items do
        ui.set_visible(items[i], state)
    end
end

-- UI Visibility handling
client.set_event_callback("paint_ui", function()
    set_visible(ui.get(interface.switch), interface.label)
    set_visible(ui.get(interface.switch), interface.delay)
    set_visible(ui.get(interface.switch), interface.hotkey)
end)

-- Crouch on shot
client.set_event_callback('setup_command', function( cmd )
    if not globals.mapname() then return end
    if not ui.get(interface.hotkey) or not ui.get(interface.switch) then return end
    if did_fire  then
        if globals.curtime() - did_fire_time > ui.get(interface.delay)/100 then
            did_fire = false
        else
            cmd.in_duck = 1
        end
    else
        did_fire_time = 0
    end
end)

-- Register aim_fire event
client.set_event_callback('aim_fire', function( args )
    if not globals.mapname() then return end
    if not ui.get(interface.hotkey) or not ui.get(interface.switch) then return end
    did_fire = true
    did_fire_time = globals.curtime()
end)