dofile(core.get_modpath("schemlib") .. "/api.lua")

local path = core.get_worldpath() .. "/schemlib"
local dir_list = core.get_dir_list(core.get_worldpath(), true)
if not dir_list then
    core.mkdir(path)
end
local exists = false
for i, dir in ipairs(dir_list) do
    if dir == "schemlib" then
        exists = true
        core.log("action", "[schemlib] Found schemlib directory")
        break
    end
end
if not exists then
    core.mkdir(path)
    core.log("action", "[schemlib] Created schemlib directory")
end


core.register_craftitem("schemlib:wand", {
    description = "Schematic Wand",
    inventory_image = "default_stick.png^[colorize:#ff75ffbf",
    wield_image = "default_stick.png^[colorize:#ff75ffbf",
    groups = { not_in_creative_inventory = 1 },
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.under
            schemlib.set_pos1(user, pos)
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref:get_luaentity()
            if entity and entity.name == "schemlib:pos2" then
                local name = user:get_player_name()
                if entity:get_staticdata() == name then
                    schemlib.set_pos1(user, pointed_thing.ref:get_pos())
                end
            end
        end
        return itemstack
    end,
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.under
            schemlib.set_pos2(placer, pos)
        end
    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        if user == nil or (pointed_thing or {}).type ~= "object" then
            return itemstack
        end
        local name = user:get_player_name()
        local entity = pointed_thing.ref:get_luaentity()
        if entity and entity.name == "schemlib:pos1" then
            if entity:get_staticdata() == name then
                schemlib.set_pos2(user, pointed_thing.ref:get_pos())
            end
        end
        return itemstack
    end,
})

core.register_entity("schemlib:pos1", {
    initial_properties = {
        visual = "cube",
        visual_size = { x = 1.1, y = 1.1 },
        textures = { "schemlib_pos1.png", "schemlib_pos1.png",
            "schemlib_pos1.png", "schemlib_pos1.png",
            "schemlib_pos1.png", "schemlib_pos1.png" },
        collisionbox = { -0.55, -0.55, -0.55, 0.55, 0.55, 0.55 },
        physical = false,
        static_save = true,
        glow = 14,
    },
    on_punch = function(self, puncher)
        if puncher == nil then
            return
        end
        local name = puncher:get_player_name()
        if name == nil then
            return
        end
        if self.player == name then
            self.object:remove()
            schemlib.set_pos1(puncher, nil)
        end
    end,
    on_blast = function(self, damage)
        return false, false, {}
    end,
    on_activate = function(self, staticdata)
        if staticdata ~= nil and staticdata ~= "" then
            local data = staticdata:split(';')
            if data and data[1] then
                self.player = data[1]
            end
        end
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
            return
        end
        local extent = schemlib.get_selection(core.get_player_by_name(self.player))
        if not extent or not extent.pos1 then
            self.object:remove()
            return
        end
        if vector.equals(self.object:get_pos(), extent.pos1) == false then
            self.object:remove()
            return
        end
    end,
    on_deactivate = function(self)
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
            return
        end
    end,
    on_step = function(self, dtime)
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
        end
        local extent = schemlib.get_selection(core.get_player_by_name(self.player))
        if not extent or not extent.pos1 then
            self.object:remove()
            return
        end
        if vector.equals(self.object:get_pos(), extent.pos1) == false then
            self.object:remove()
            return
        end
    end,
    get_staticdata = function(self)
        if self.player ~= nil then
            return self.player
        end
        return ""
    end,
})

core.register_entity("schemlib:pos2", {
    initial_properties = {
        visual = "cube",
        visual_size = { x = 1.1, y = 1.1 },
        textures = {
            "schemlib_pos2.png", "schemlib_pos2.png",
            "schemlib_pos2.png", "schemlib_pos2.png",
            "schemlib_pos2.png", "schemlib_pos2.png"
        },
        collisionbox = { -0.55, -0.55, -0.55, 0.55, 0.55, 0.55 },
        physical = false,
        static_save = true,
        glow = 14,
    },
    on_punch = function(self, puncher)
        if puncher == nil then
            return
        end
        local name = puncher:get_player_name()
        if name == nil then
            return
        end
        if self.player == name then
            self.object:remove()
            schemlib.set_pos2(puncher, nil)
        end
    end,
    on_blast = function(self, damage)
        return false, false, {}
    end,
    on_activate = function(self, staticdata)
        if staticdata ~= nil and staticdata ~= "" then
            local data = staticdata:split(';')
            if data and data[1] then
                self.player = data[1]
            end
        end
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
        end
        local extent = schemlib.get_selection(core.get_player_by_name(self.player))
        if not extent or not extent.pos2 then
            self.object:remove()
        end
        if vector.equals(self.object:get_pos(), extent.pos2) == false then
            self.object:remove()
        end
    end,
    on_deactivate = function(self)
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
            return
        end
    end,
    on_step = function(self, dtime)
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
            return
        end
        local extent = schemlib.get_selection(core.get_player_by_name(self.player))
        if not extent or not extent.pos2 then
            self.object:remove()
            return
        end
        if vector.equals(self.object:get_pos(), extent.pos2) == false then
            self.object:remove()
            return
        end
    end,
    get_staticdata = function(self)
        if self.player ~= nil then
            return self.player
        end
        return ""
    end,
})

core.register_entity("schemlib:cuboid", {
    initial_properties = {
        visual = "cube",
        backface_culling = false,
        visual_size = { x = 1, y = 1 },
        textures = {
            "schemlib_cuboid.png", "schemlib_cuboid.png",
            "schemlib_cuboid.png", "schemlib_cuboid.png",
            "schemlib_cuboid.png", "schemlib_cuboid.png"
        },
        collisionbox = { 0, 0, 0, 0, 0, 0 },
        physical = false,
        static_save = true,
        use_texture_alpha = true,
        glow = 14,
    },
    on_punch = function(self, puncher)
        return
    end,
    on_blast = function(self, damage)
        return false, false, {}
    end,
    on_activate = function(self, staticdata)
        if staticdata ~= nil and staticdata ~= "" then
            local data = staticdata:split(';')
            if data and data[1] and data[2] and data[3] then
                self.player = data[1]
                self.pos1 = core.string_to_pos(data[2])
                self.pos2 = core.string_to_pos(data[3])
            end
        end
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online or self.pos1 == nil or self.pos2 == nil then
            self.object:remove()
            return
        end
        local extent = schemlib.get_selection(core.get_player_by_name(self.player))
        if not extent or not extent.pos1 or not extent.pos2 then
            self.object:remove()
            return
        end
        if vector.equals(self.pos1, extent.pos1) == false or vector.equals(self.pos2, extent.pos2) == false then
            self.object:remove()
            return
        end
        -- calculate the size of the cuboid based on the two positions
        local size = vector.add(vector.new(
            math.abs(self.pos1.x - self.pos2.x),
            math.abs(self.pos1.y - self.pos2.y),
            math.abs(self.pos1.z - self.pos2.z)
        ), 1.1)
        self.object:set_properties({
            visual_size = size,
        })
    end,
    on_deactivate = function(self)
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
        end
    end,
    on_step = function(self, dtime)
        local player_online = false
        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() == self.player then
                player_online = true
                break
            end
        end
        if self.player == nil or not player_online then
            self.object:remove()
            return
        end
        local extent = schemlib.get_selection(core.get_player_by_name(self.player))
        if not extent or not extent.pos1 or not extent.pos2 then
            self.object:remove()
            return
        end
        if vector.equals(self.pos1, extent.pos1) == false or vector.equals(self.pos2, extent.pos2) == false then
            self.object:remove()
            return
        end
    end,
    get_staticdata = function(self)
        if self.player ~= nil and self.pos1 ~= nil and self.pos2 ~= nil then
            return self.player .. ";" .. core.pos_to_string(self.pos1) .. ";" .. core.pos_to_string(self.pos2)
        end
        return ""
    end,
})

core.register_privilege("schemlib", {
    description = "Allow player to use schemlib",
    give_to_singleplayer = false,
    give_to_admin = true,
})

core.register_chatcommand("pos1", {
    description = "Set position 1 to the current position",
    privs = { schemlib = true },
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if player == nil then
            return true, "This command can only be used by a player"
        end
        local pos = vector.round(player:get_pos())
        pos.y = pos.y - 1
        schemlib.set_pos1(player, pos)
        return true
    end,
})

core.register_chatcommand("pos2", {
    description = "Set position 2 to the current position",
    privs = { schemlib = true },
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if player == nil then
            return true, "This command can only be used by a player"
        end
        local pos = vector.round(player:get_pos())
        pos.y = pos.y - 1
        schemlib.set_pos2(player, pos)
        return true
    end,
})

core.register_chatcommand("clear_selection", {
    description = "Clear the current selection",
    privs = { schemlib = true },
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if player == nil then
            return true, "This command can only be used by a player"
        end
        schemlib.clear_selection(player)
        return true
    end,
})

core.register_chatcommand("schematic_wand", {
    description = "Give the player a schematic wand",
    privs = { schemlib = true },
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if player == nil then
            return true, "This command can only be used by a player"
        end
        local has_wand = false
        local inv = player:get_inventory()
        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if stack:get_name() == "schemlib:wand" then
                has_wand = true
                break
            end
        end
        if not has_wand then
            inv:add_item("main", "schemlib:wand")
        end
        return true, "You have been given a schematic wand"
    end,
})

core.register_chatcommand("save_schematic", {
    params = "<name> (force)",
    description = "Save the current selection as a schematic",
    privs = { schemlib = true },
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if player == nil then
            return true, "This command can only be used by a player"
        end
        local selection = schemlib.get_selection(player)
        if selection == nil then
            return true, "No selection found"
        end
        if selection.pos1 == nil or selection.pos2 == nil then
            return true, "Invalid selection"
        end
        local schem_name, force = string.match(param, "^(%S+)%s*(%S*)$")
        if schem_name == nil then
            return true, "Invalid arguments"
        end

        local schem_path = path .. "/" .. schem_name
        if force == "force" then
            force = true
        else
            force = false
        end
        core.chat_send_player(name, "Force: " .. tostring(force))
        local file = io.open(schem_path .. ".mtx", "r")
        if not force and file then
            file:close()
            return true, "Schematic already exists. Use 'force' to overwrite"
        end
        local min = vector.new(
            math.min(selection.pos1.x, selection.pos2.x),
            math.min(selection.pos1.y, selection.pos2.y),
            math.min(selection.pos1.z, selection.pos2.z)
        )
        local max = vector.new(
            math.max(selection.pos1.x, selection.pos2.x),
            math.max(selection.pos1.y, selection.pos2.y),
            math.max(selection.pos1.z, selection.pos2.z)
        )
        local pos = vector.round(player:get_pos())
        pos.y = pos.y - 1
        -- get the offset of the players postion from the min position
        local offset = vector.subtract(pos, min)
        local data = {
            filename = schem_name,
            min = min,
            max = max,
            origin = min,
            offset = offset,
            ttl = 0,
        }
        local flags = {
            file_cache = true,
            keep_inv = true,
            keep_meta = true,
            origin_clear = false,
            keep_timers = true,
            stop_timers = false
        }
        schemlib.emit(data, flags)
        return true, "Schematic saved as " .. schem_name .. ".mtx"
    end,
})

core.register_chatcommand("load_schematic", {
    params = "<name>",
    description = "Load a schematic into the world at the current position",
    privs = { schemlib = true },
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if player == nil then
            return true, "This command can only be used by a player"
        end
        local schem_name = param
        local origin = vector.round(player:get_pos())
        origin.y = origin.y - 1
        local meta = schemlib.load_emitted({
            filename = schem_name,
            origin = origin,
            emerge = true, -- false = disables write to world
        })
        if meta == nil then
            return true, "Schematic " .. schem_name .. ".mtx not found"
        end
        return true, "Schematic " .. schem_name .. ".mtx loaded"
    end,
})



core.register_on_leaveplayer(function(ObjectRef, timed_out)
    schemlib.clear_selection(ObjectRef)
end)


core.register_on_shutdown(function()
    schemlib.clear_selections()
end)
