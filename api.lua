schemlib = {}

local extension = ".mtx"
local storage_dir = "schemlib"
local world_path = core.get_worldpath()


dofile(core.get_modpath("schemlib") .. "/util.lua")
dofile(core.get_modpath("schemlib") .. "/serialization.lua")
dofile(core.get_modpath("schemlib") .. "/mtx.lua")

local extents = {}


local function load_json_schematic(value)
    local obj = {}
    if value then
        obj = core.parse_json(value)
        return obj
    end
    return obj
end

local function load_to_map(origin_pos, obj)
    local nodes = obj.cuboid
    local o = obj.meta.offset
    local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
    local add_node, get_meta, get_node_timer = core.add_node, core.get_meta, core.get_node_timer
    -- local data = manip:get_data()
    for i, entry in ipairs(nodes) do
        entry.x, entry.y, entry.z = origin_x + (entry.x - o.x), origin_y + (entry.y - o.y), origin_z + (entry.z - o.z)
        -- Entry acts as both position and node
        add_node(entry, entry)

        if entry.meta then
            get_meta(entry):from_table(entry.meta)
        end

        if entry.timer then
            get_node_timer(entry):set(entry.timer.timeout, entry.timer.elapsed)
            if not entry.timer.started then
                get_node_timer(entry):stop()
            end
        end
    end
end


local function allocate_with_nodes(origin_pos, nodes)
    local huge = math.huge
    local pos1x, pos1y, pos1z = huge, huge, huge
    local pos2x, pos2y, pos2z = -huge, -huge, -huge
    local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
    for i, entry in ipairs(nodes) do
        local x, y, z = origin_x + entry.x, origin_y + entry.y, origin_z + entry.z
        if x < pos1x then
            pos1x = x
        end
        if y < pos1y then
            pos1y = y
        end
        if z < pos1z then
            pos1z = z
        end
        if x > pos2x then
            pos2x = x
        end
        if y > pos2y then
            pos2y = y
        end
        if z > pos2z then
            pos2z = z
        end
    end
    local pos1 = {
        x = pos1x,
        y = pos1y,
        z = pos1z
    }
    local pos2 = {
        x = pos2x,
        y = pos2y,
        z = pos2z
    }
    return pos1, pos2, #nodes
end

function schemlib.get_selection(player)
    local name = player:get_player_name()
    return extents[name]
end

function schemlib.set_pos1(player, pos)
    local name = player:get_player_name()
    local tmp = extents[name]
    if not tmp then
        tmp = {}
    end
    if tmp.pos1 then
        for obj in core.objects_inside_radius(tmp.pos1, 1) do

            if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:pos1" then
                if obj:get_luaentity():get_staticdata() == name then
                    obj:remove()
                end
            end
        end
        if tmp.pos2 then
            -- get the min and max of the two positions
            local min = vector.new(
                math.min(tmp.pos1.x, tmp.pos2.x),
                math.min(tmp.pos1.y, tmp.pos2.y),
                math.min(tmp.pos1.z, tmp.pos2.z)
            )
            local max = vector.new(
                math.max(tmp.pos1.x, tmp.pos2.x),
                math.max(tmp.pos1.y, tmp.pos2.y),
                math.max(tmp.pos1.z, tmp.pos2.z)
            )
            for obj in core.objects_in_area(min, max) do
                if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:cuboid" then
                    local data = obj:get_luaentity():get_staticdata()
                    if data:split(";")[1] == name then
                        obj:remove()
                    end
                end
            end
        end
    end
    tmp.pos1 = pos
    extents[name] = tmp
    if pos ~= nil then
        core.add_entity(pos, "schemlib:pos1", player:get_player_name())
        core.chat_send_player(name, "Position 1 set to " .. core.pos_to_string(pos))
        if tmp.pos2 then
            local middle = vector.divide(vector.add(tmp.pos1, tmp.pos2), 2)
            core.add_entity(middle, "schemlib:cuboid", player:get_player_name() .. ";" .. core.pos_to_string(tmp.pos1) .. ";" .. core.pos_to_string(tmp.pos2))
            local volume = schemlib.volume(tmp.pos1, tmp.pos2)
            core.chat_send_player(name, "Region selected from " .. core.pos_to_string(tmp.pos1) .. " to " .. core.pos_to_string(tmp.pos2) .. " with volume " .. volume)
        end
    else
        core.chat_send_player(name, "Position 1 cleared")
    end
    
end

function schemlib.set_pos2(player, pos)
    local name = player:get_player_name()
    local tmp = extents[name]
    if not tmp then
        tmp = {}
    end
    if tmp.pos2 then
        for obj in core.objects_inside_radius(tmp.pos2, 1) do
            if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:pos2" then
                if obj:get_luaentity():get_staticdata() == name then
                    obj:remove()
                end
            end
        end
        if tmp.pos1 then
            local min = vector.new(
                math.min(tmp.pos1.x, tmp.pos2.x),
                math.min(tmp.pos1.y, tmp.pos2.y),
                math.min(tmp.pos1.z, tmp.pos2.z)
            )
            local max = vector.new(
                math.max(tmp.pos1.x, tmp.pos2.x),
                math.max(tmp.pos1.y, tmp.pos2.y),
                math.max(tmp.pos1.z, tmp.pos2.z)
            )
            for obj in core.objects_in_area(min, max) do
                if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:cuboid" then
                    local data = obj:get_luaentity():get_staticdata()
                    if data:split(";")[1] == name then
                        obj:remove()
                    end
                end
            end
        end
    end
    tmp.pos2 = pos
    extents[name] = tmp
    if pos ~= nil then
        core.add_entity(pos, "schemlib:pos2", player:get_player_name())
        core.chat_send_player(name, "Position 2 set to " .. core.pos_to_string(pos))
        if tmp.pos1 then
            local middle = vector.divide(vector.add(tmp.pos1, tmp.pos2), 2)
            core.add_entity(middle, "schemlib:cuboid", player:get_player_name() .. ";" .. core.pos_to_string(tmp.pos1) .. ";" .. core.pos_to_string(tmp.pos2))
            local volume = schemlib.volume(tmp.pos1, tmp.pos2)
            core.chat_send_player(name, "Region selected from " .. core.pos_to_string(tmp.pos1) .. " to " .. core.pos_to_string(tmp.pos2) .. " with volume " .. volume)
        end

    else
        core.chat_send_player(name, "Position 2 cleared")
    end

end

function schemlib.clear_selection(player)
    local name = player:get_player_name()
    local tmp = extents[name]
    if not tmp then
        tmp = {}
    end
    if tmp.pos1 then
        for obj in core.objects_inside_radius(tmp.pos1, 1) do
            if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:pos1" then
                if obj:get_luaentity():get_staticdata() == name then
                    obj:remove()
                end
            end
        end
    end
    if tmp.pos2 then
        for obj in core.objects_inside_radius(tmp.pos2, 1) do
            if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:pos2" then
                if obj:get_luaentity():get_staticdata() == name then
                    obj:remove()
                end
            end
        end
    end
    if tmp.pos1 and tmp.pos2 then
        local min = vector.new(
            math.min(tmp.pos1.x, tmp.pos2.x),
            math.min(tmp.pos1.y, tmp.pos2.y),
            math.min(tmp.pos1.z, tmp.pos2.z)
        )
        local max = vector.new(
            math.max(tmp.pos1.x, tmp.pos2.x),
            math.max(tmp.pos1.y, tmp.pos2.y),
            math.max(tmp.pos1.z, tmp.pos2.z)
        )
        for obj in core.objects_in_area(min, max) do
            if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:cuboid" then
                local data = obj:get_luaentity():get_staticdata()
                if data:split(";")[1] == name then
                    obj:remove()
                end
            end
        end
    end
    extents[name] = nil
    core.chat_send_player(name, "Selection cleared")
end

--- Loads the nodes represented by string `json_obj` at position `origin_pos`.
-- @return The number of nodes deserialized.
function schemlib.process_emitted(origin_pos, obj_json, obj_table, emerge_cb)
    if obj_json == nil and obj_table == nil then
        return nil
    end
    -- core.log(">>> Loading Emitted...")
    if obj_table == nil then
        obj_table = load_json_schematic(obj_json)
    end
    local nodes = obj_table.cuboid
    if not nodes then
        return nil
    end
    if #nodes == 0 then
        return #nodes
    end

    if not origin_pos or origin_pos == nil then
        origin_pos = obj_table.meta.dest
    end

    if emerge_cb then
        -- core.log(">>> Emerging Emitted...")
        local pos1, pos2 = allocate_with_nodes(origin_pos, nodes)

        -- emerge complete callback
        local function emerge_area_callback_complete(blockpos, action, calls_remaining, param)
            if calls_remaining == 0 then
                -- preload area
                local manip, area = schemlib.keep_loaded(pos1, pos2)
                -- set nodes and meta
                load_to_map(origin_pos, obj_table)

                -- emerge completed callback
                if emerge_cb ~= nil and type(emerge_cb) == 'function' then
                    emerge_cb(obj_table.meta, obj_table.flags)
                end
            end
        end
        
        -- load area to world
        core.emerge_area(pos1, pos2, emerge_area_callback_complete)
    end

    return #nodes, obj_table.version, obj_table.meta
end

-- Save to file
function schemlib.emit(data, flags)
    local min = data.min or data.pos1
    local max = data.max or data.pos2

    local serial_data, count = {}, 0
    if flags.file_cache then
        serial_data, count = schemlib.serialize_json(data, flags, min, max)
    else
        serial_data, count = schemlib.serialize_table(data, flags, min, max)
    end

    if flags.file_cache and flags.file_cache == true then
        local path = world_path .. "/" .. storage_dir
        core.mkdir(path)
        local filename = path .. "/" .. data.filename
        local file = io.open(filename .. extension, "w")
        if file then
            file:write(serial_data)
            file:close()
        end
    end

    return serial_data, count
end

-- Load from file in schemlib local storage
function schemlib.load_emitted(data)
    local path = world_path .. "/" .. storage_dir
    local filename = path .. "/" .. data.filename
    local file = io.open(filename .. extension, "r")
    if file then
        local count, ver, meta = schemlib.process_emitted(data.origin, file:read("*all"), nil, data.emerge)
        file:close()
        return meta
    end
    return nil
end

-- Load from file from any path
function schemlib.load_emitted_file(data)
    core.log(">>>> loading " .. data.filename)
    local file = io.open(data.filepath .. "/" .. data.filename .. extension, "r")
    local content = ""
    local chunksize = 32768
    if file then
        local c = 0
        while true do
            local chunk = file:read(chunksize)
            if not chunk then
                break
            end
            core.log(">> Loaded chunk " .. c)
            c = c + 1
            content = content .. chunk
        end
        file:close()
    end
    -- local content = file:read("*all")
    core.log(">>>> File Loaded " .. data.filename)
    local count, ver, meta = schemlib.process_emitted(data.origin, content, nil, data.emerge)

    core.log(">>> Emitted Load " .. data.filename)
    return meta
end

function schemlib.get_dimensions(schem_name)
    local origin = { x = 0, y = 0, z = 0 }
    local meta = schemlib.load_emitted({
        filename = schem_name,
        origin = origin,
        emerge = false,
    })
    if meta ~= nil then
        return meta.size
    end
    return nil
end

function schemlib.clear_selections()
   for name, extent in pairs(extents) do
        if not extent then
            return
        end
        if extent.pos1 then
            for obj in core.objects_inside_radius(extent.pos1, 1) do
                if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:pos1" then
                    if obj:get_luaentity():get_staticdata() == name then
                        obj:remove()
                    end
                end
            end
        end
        if extent.pos2 then
            for obj in core.objects_inside_radius(extent.pos2, 1) do
                if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:pos2" then
                    if obj:get_luaentity():get_staticdata() == name then
                        obj:remove()
                    end
                end
            end
        end
        if extent.pos1 and extent.pos2 then
            local min = vector.new(
                math.min(extent.pos1.x, extent.pos2.x),
                math.min(extent.pos1.y, extent.pos2.y),
                math.min(extent.pos1.z, extent.pos2.z)
            )
            local max = vector.new(
                math.max(extent.pos1.x, extent.pos2.x),
                math.max(extent.pos1.y, extent.pos2.y),
                math.max(extent.pos1.z, extent.pos2.z)
            )
            for obj in core.objects_in_area(min, max) do
                if obj:get_luaentity() ~= nil and obj:get_luaentity().name == "schemlib:cuboid" then
                    local data = obj:get_luaentity():get_staticdata()
                    if data:split(";")[1] == name then
                        obj:remove()
                    end
                end
            end
        end
    end
    extents = {}
end
