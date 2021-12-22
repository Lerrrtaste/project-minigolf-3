local nk = require("nakama")

local function matchmaker_matched(context, matched_users)
    -- get and check map_id
    local _map_id
    local _map_owner_id
    for _, user in ipairs(matched_users) do
        local presence = user.presence
        _map_id = user.properties.map_id
        _map_owner_id = user.properties.owner_id
        --nk.logger_info("MapID recieved --------------: ")
        --nk.logger_info(_map_id)
        --nk.logger_info(("Matched user '%s' named '%s'"):format(presence.user_id, presence.username))
        --for k, v in pairs(user.properties) do
            --nk.logger_info(("Matched on '%s' value '%s'"):format(k, v))
            --if k ~= "map_id" and _map_id ~= nil then
            --_map_id = v
            --else
            --    error("Players in the same match had different map_id property values!!!")
            --end
        --end
    end

    local modulename = "default_match"
    local setupstate = {
        invited = matched_users,
        map_id = _map_id,
        map_owner_id = _map_owner_id
    }
    local matchid = nk.match_create(modulename, setupstate)
    return matchid
end

nk.register_matchmaker_matched(matchmaker_matched)
