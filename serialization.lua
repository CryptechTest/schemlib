schemlib.LATEST_SERIALIZATION_VERSION = 7

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


--- Converts the region defined by positions `pos1` and `pos2`
-- into a single string.
-- @return The serialized data.
-- @return The number of nodes serialized.
function schemlib.serialize(pos1, pos2)
    pos1, pos2 = schemlib.sort_pos(pos1, pos2)
    schemlib.keep_loaded(pos1, pos2)

    local get_node, get_meta, hash_node_position = minetest.get_node, minetest.get_meta, minetest.hash_node_position

    -- Find the positions which have metadata
    local has_meta = {}
    local meta_positions = minetest.find_nodes_with_meta(pos1, pos2)
    for i = 1, #meta_positions do
        has_meta[hash_node_position(meta_positions[i])] = true
    end

    local pos = {
        x = pos1.x,
        y = 0,
        z = 0
    }
    local count = 0
    local result = {}
    while pos.x <= pos2.x do
        pos.y = pos1.y
        while pos.y <= pos2.y do
            pos.z = pos1.z
            while pos.z <= pos2.z do
                local node = get_node(pos)
                if minetest.registered_nodes[node.name] == nil then
                    -- ignore
                elseif node.name ~= "ignore" and node.name ~= "vacuum:vacuum" and node.name ~= "asteroid:atmos" then
                    count = count + 1

                    local meta
                    if has_meta[hash_node_position(pos)] then
                        meta = get_meta(pos):to_table()

                        -- Convert metadata item stacks to item strings
                        for _, invlist in pairs(meta.inventory) do
                            for index = 1, #invlist do
                                local itemstack = invlist[index]
                                if itemstack.to_string then
                                    invlist[index] = itemstack:to_string()
                                end
                            end
                        end
                    end

                    result[count] = {
                        x = pos.x - pos1.x,
                        y = pos.y - pos1.y,
                        z = pos.z - pos1.z,
                        name = node.name,
                        param1 = node.param1 ~= 0 and node.param1 or nil,
                        param2 = node.param2 ~= 0 and node.param2 or nil,
                        meta = meta
                    }
                end
                pos.z = pos.z + 1
            end
            pos.y = pos.y + 1
        end
        pos.x = pos.x + 1
    end
    return deepcopy(result), count
end

function schemlib.serialize_table(head, flags, pos1, pos2)
    local result, count = schemlib.serialize(pos1, pos2)
    head.size = schemlib.size(pos1, pos2)
    head.volume = schemlib.volume(pos1, pos2)
    -- Serialize entries
    local json_header = schemlib.get_serialized_header(head, count)
    local json_flags = schemlib.get_serialized_flags(flags)
    local table = {}
    local header = minetest.parse_json("{" .. json_header .. "}")
    table.meta = header.meta
    table.flags = minetest.parse_json(json_flags)
    table.cuboid = result
    return table, count
end

function schemlib.serialize_json(head, flags, pos1, pos2)
    local result, count = schemlib.serialize(pos1, pos2)
    -- Serialize entries
    local json_result = minetest.write_json(result)
    local json_header = schemlib.get_serialized_header(head, count)
    local json_flags = schemlib.get_serialized_flags(flags)
    local json_str = schemlib.format_result_json(json_header, json_flags, json_result)
    return json_str, count
end

