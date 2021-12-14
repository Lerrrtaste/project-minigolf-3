--[[
local nk = require("nakama")
nk.logger_error("Hello")

local function matchmaker_matched(context, matched_users)
    -- print matched users
    nk.logger_error("Hello from inside")
    for _, user in ipairs(matched_users) do
        local presence = user.presence
        nk.logger_info(("Matched user '%s' named '%s'"):format(presence.user_id, presence.username))
        for k, v in pairs(user.properties) do
            nk.logger_info(("Matched on '%s' value '%s'"):format(k, v))
        end
    end

    local modulename = "default_match"
    local setupstate = { invited = matched_users }
    local matchid = nk.match_create("modules.default_match", setupstate)
    return matchid
end

nk.register_matchmaker_matched(matchmaker_matched)
nk.logger_error("ELLOOOO?")]]


local nk = require("nakama")

local function matchmaker_matched(context, matched_users)
    nk.logger_info("--------------MatchMakerMatched----------------")
    nk.logger_info(("Context: %q"):format(nk.json_encode(context)))
    nk.logger_info(("Matched users: %q"):format(nk.json_encode(matched_users)))

    if #matched_users ~= 2 then
        return nil
    end

    local possible_spawn_pos = {
        {x = -15, y = 0, z = 17},
        {x = 13, y = 0, z = 17}
    }
    -- possible_spawn_pos[#possible_spawn_pos + 1] = {x = -15, y = 0, z = 17}
    -- possible_spawn_pos[#possible_spawn_pos + 1] = {x = 13, y = 0, z = 17}

    --local i = 1
    --local spawnpos = {}
    --for _, m in ipairs(matched_users) do
    --    -- spawnpos[m.presence["user_id"]] = possible_spawn_pos[i]
    --    spawnpos[i] = {
    --        UserId = m.presence["user_id"],
    --        spawnpos = possible_spawn_pos[i]
    --    }
    --    i = i+1
    --end
    --for _, m in ipairs(matched_users) do
    --    local stored_object = {
    --        collection = "match_metadata",
    --        key = m.presence["user_id"],
    --        user_id = m.presence["user_id"],
    --        value = {spawnpos = spawnpos}
    --    }
    --    nk.storage_write({stored_object})
    --end

    -- local matchid = nk.match_create("default_match", {debug = true, expected_users = matched_users})

    --   if matched_users[1].properties["mode"] ~= "authoritative" then
    --     return nil
    --   end
    --   if matched_users[2].properties["mode"] ~= "authoritative" then
    --     return nil
    --   end
     nk.logger_info("-----------------------------------------------")
    -- return matchid

end
nk.register_matchmaker_matched(matchmaker_matched)
nk.logger_info("Hellooooooooooo")



local nk = require("nakama")

local function custom_rpc_func(context, payload)
  nk.logger_info(string.format("Payload: %q", payload))

  -- "payload" is bytes sent by the client we'll JSON decode it.
  local json = nk.json_decode(payload)

  return nk.json_encode(json)
end

nk.register_rpc(custom_rpc_func, "rpc_test")