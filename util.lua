--- Copies and modifies positions `pos1` and `pos2` so that each component of
-- `pos1` is less than or equal to the corresponding component of `pos2`.
-- Returns the new positions.
function schemlib.sort_pos(pos1, pos2)
    pos1 = {
        x = pos1.x,
        y = pos1.y,
        z = pos1.z
    }
    pos2 = {
        x = pos2.x,
        y = pos2.y,
        z = pos2.z
    }
    if pos1.x > pos2.x then
        pos2.x, pos1.x = pos1.x, pos2.x
    end
    if pos1.y > pos2.y then
        pos2.y, pos1.y = pos1.y, pos2.y
    end
    if pos1.z > pos2.z then
        pos2.z, pos1.z = pos1.z, pos2.z
    end
    return pos1, pos2
end

--- Determines the volume of the region defined by positions `pos1` and `pos2`.
-- @return The volume.
function schemlib.volume(pos1, pos2)
    pos1, pos2 = schemlib.sort_pos(pos1, pos2)
    return (pos2.x - pos1.x + 1) * (pos2.y - pos1.y + 1) * (pos2.z - pos1.z + 1)
end

function schemlib.size(pos1, pos2)
    pos1, pos2 = schemlib.sort_pos(pos1, pos2)
    local w = (pos2.x - pos1.x + 1)
    local h = (pos2.y - pos1.y + 1)
    local l = (pos2.z - pos1.z + 1)
    return { width = w, length = l, height = h }
end

function schemlib.keep_loaded(pos1, pos2)
    -- Create a vmanip and read the area from map, this
    -- causes all MapBlocks to be loaded into memory.
    -- This doesn't actually *keep* them loaded, unlike the name implies.
    -- local manip = core.get_voxel_manip()
    local manip = VoxelManip(pos1, pos2)
    local e1, e2 = manip:read_from_map(pos1, pos2)
    local area = VoxelArea:new({
        MinEdge = e1,
        MaxEdge = e2
    })
    return manip, area
end
