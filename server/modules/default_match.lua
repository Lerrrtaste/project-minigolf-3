local nk = require("nakama")
local match_handler = {}

OpCodes = {
   MATCH_CONFIG = 101,
   MATCH_START = 102,
   NEXT_TURN = 103,
   FINISHED_TURN = 104,
   BALL_IMPACT = 201,
   BALL_SYNC = 202,
}

function match_handler.match_init(context, setupstate)
    local gamestate = {
        map_id = setupstate.map_id,
        expected_players = {}, -- numbered presences
        joined_players = {}, -- key=user_id val=presence
        turn_order = {}, -- numbered user_ids

        player_positions = {}, -- key=user_id val=var2str string
        next_player_idx = 1,

        started = false,
    }

    for _, user in ipairs(setupstate.invited) do
        -- nk.logger_info(string.format("Trying to add %s to expected players.",nk.json_encode(user.presence)))
        gamestate.expected_players[user.presence.user_id] = user.presence
    end

    local tickrate = 5
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

    local op_code = OpCodes.MATCH_CONFIG
    local data = nk.json_encode({map_id= state.map_id}) --, turn_order= state.expected_players})
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

        -- generate turn order
        for _, v in pairs(state.joined_players) do
            local pos = math.random(1, #state.turn_order+1)
            table.insert(state.turn_order, pos, v.user_id)
        end

        -- announce match start
        state.started = true
        local data = nk.json_encode({ joined_players = state.joined_players, turn_order = state.turn_order})
        dispatcher.broadcast_message(OpCodes.MATCH_START, data, nil) -- send match start to all presences
    end

    -- match is started from here
    if messages ~= nil then
        for _, msg in ipairs(messages) do

            if msg.op_code == OpCodes.BALL_IMPACT then -- forward ball impacts to everyone
                if state.turn_order[state.next_player_idx] == msg.sender.user_id then -- only broadcast if player is at turn FIXME sync will still happen
                    dispatcher.broadcast_message(OpCodes.BALL_IMPACT, msg.data, nil, msg.sender)
                end

            elseif msg.op_code == OpCodes.BALL_SYNC then -- after local ball finished this is sent to sync
                dispatcher.broadcast_message(OpCodes.BALL_SYNC, msg.data, nil, msg.sender)
                state.player_positions[msg.sender] = nk.json_decode(msg.data)["synced_pos"]

            elseif msg.op_code == OpCodes.FINISHED_TURN then
                state.next_player_idx = ((state.next_player_idx) % #state.turn_order) +1 -- indices start at 1
                local data = nk.json_encode({next_player = state.turn_order[state.next_player_idx]})
                dispatcher.broadcast_message(OpCodes.NEXT_TURN, data, nil)
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

