local nk = require("nakama")

local function matchmaker_matched(context, matched_users)
    -- get and check map_id
    local _map_pool = {} -- [{map_id=, creator_id=},...]


    for _, user in ipairs(matched_users) do
        local presence = user.presence

        -- count maps in pool
        local map_pool_size = 0
        local map_pool_data = {}
        for key, value in pairs(user.properties) do
            if string.sub(key,1,string.len("map_pool_"))=="map_pool_" then
                map_pool_size = map_pool_size +1
                map_pool_data[1+string.sub(key,string.len("map_pool_")+1)] = value
            end
        end
        if map_pool_size == 0 then
                nk.logger_error("At least one user had no maps in map pool. Match wont be created.")
            return nil
        end
        map_pool_size = map_pool_size / 2

        -- add to map_pool
        for i=0,map_pool_size-1,1 do
            local map = {
                map_id = string.sub(map_pool_data[1+(2 * i + 0)],string.len("map_")+1),
                creator_id = string.sub(map_pool_data[1+(2 * i + 1)],string.len("creator_")+1),
            }
            table.insert(_map_pool, map)
        end
    end


    -- choose a random map
    if #_map_pool == 0 then
        nk.logger_error("No maps in map pool. Match wont be created.")
        return nil
    end

    local random_idx = math.random(1, #_map_pool)


    -- create match
    local modulename = "default_match"
    local setupstate = {
        matched_users = matched_users,
        map_id = _map_pool[random_idx].map_id,
        map_owner_id = _map_pool[random_idx].creator_id,
    }
    local matchid = nk.match_create(modulename, setupstate)
    return matchid
end

nk.register_matchmaker_matched(matchmaker_matched)
