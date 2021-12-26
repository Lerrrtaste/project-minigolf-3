local nk = require("nakama")

local function matchmaker_matched(context, matched_users)
    -- get and check map_id
    local _map_id
    local _map_owner_id
    for _, user in ipairs(matched_users) do
        local presence = user.presence
        _map_id = user.properties.map_id
        _map_owner_id = user.properties.owner_id
    end

    local modulename = "default_match"
    local setupstate = {
        matched_users = matched_users,
        map_id = _map_id,
        map_owner_id = _map_owner_id,
    }
    local matchid = nk.match_create(modulename, setupstate)
    return matchid
end

nk.register_matchmaker_matched(matchmaker_matched)
