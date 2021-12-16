local nk = require("nakama")
local match_handler = {}

OpCodes = {
   ANNOUNCE_MATCH_CONFIG = 101,
   MATCH_START = 102,
   BALL_IMPACT = 201,
}

function match_handler.match_init(context, setupstate)
    local gamestate = {
        map_id = setupstate.map_id,
        expected_players = {},
        joined_players = {},
        started = false,
    }

    for _, user in ipairs(setupstate.invited) do
        -- nk.logger_info(string.format("Trying to add %s to expected players.",nk.json_encode(user.presence)))
        gamestate.expected_players[user.presence.user_id] = user.presence
    end

    local tickrate = 10
    local label = ""
    return gamestate, tickrate, label
end

function match_handler.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
    local acceptuser = true
    return state, acceptuser
end

function match_handler.match_join(context, dispatcher, tick, state, presences)
    local _turn_order = {}
    local key_idx = 0

    for _, user in ipairs(presences) do
        state.joined_players[user.user_id] = user
        --nk.logger_info(string.format("------ Joined: %s",user.user_id))
    end

    local op_code = OpCodes.ANNOUNCE_MATCH_CONFIG
    local data = nk.json_encode({map_id= state.map_id, turn_order= state.expected_players})
    local reciever = presences
    nk.logger_info(string.format(" -> Sending MATCH_SETUP to %s", presences))
    dispatcher.broadcast_message(op_code, data, reciever)
    return state
end

function match_handler.match_leave(context, dispatcher, tick, state, presences)
    return state
end

function match_handler.match_loop(context, dispatcher, tick, state, messages)
        -- Messages format:
    -- {
    --   {
    --     sender = {
    --       user_id = "user unique ID",
    --       session_id = "session ID of the user's current connection",
    --       username = "user's unique username",
    --       node = "name of the Nakama node the user is connected to"
    --     },
    --     op_code = 1, -- numeric op code set by the sender.
    --     data = "any string data set by the sender" -- may be nil.
    --   },
    --   ...
    -- }
    -- match loading
    if state.started ~= true then
        for _, user in pairs(state.expected_players) do
            nk.logger_info(string.format("Joined: %s | checking for %s",nk.json_encode(state.joined_players),nk.json_encode(user)))
            -- nk.logger_info(string.format("Joined: %s | Expected %s",nk.json_encode(state.joined_players),nk.json_encode(state.expected_players)))
            if state.joined_players[user.user_id] == nil then
                --nk.logger_info(string.format("Missing user id: %s. joined_players[user_id] = %s",user.user_id, state.joined_players[user.user_id]))
                return state
            end
        end
        state.started = true
        local data = nk.json_encode({ joined_players = state.joined_players })
        dispatcher.broadcast_message(OpCodes.MATCH_START, data, nil) -- send match start to all presences
    end

    -- match started
    if messages ~= nil then
        for _, msg in ipairs(messages) do
            -- forward ball impacts to everyone
            if msg.op_code == OpCodes.BALL_IMPACT then
                dispatcher.broadcast_message(OpCodes.BALL_IMPACT, msg.data, nil, msg.sender)
            end
        end
    end
    return state
end

function match_handler.match_terminate(context, dispatcher, tick, state, grace_seconds)
  return state
end

function match_handler.match_signal(context, dispatcher, tick, state, data)
  return state, data
end

return match_handler
