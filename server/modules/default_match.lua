local nk = require("nakama")
local match_handler = {}

OpCodes = {
   ANNOUNCE_MATCH_CONFIG = 101,
   MATCH_START = 102
}

function match_handler.match_init(context, setupstate)
    local gamestate = {
      map_id = setupstate.map_id,
      expected_players = setupstate.invited,
      started = false,
    }
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
    for _, user in ipairs(state.expected_players) do
        _turn_order[key_idx] = user.presence.user_id
        key_idx = key_idx +1
    end
    local op_code = OpCodes.ANNOUNCE_MATCH_CONFIG
    local data = nk.json_encode({map_id= state.map_id, turn_order= _turn_order})
    local reciever = context.presence
    dispatcher.broadcast_message(op_code, data, reciever)
    return state
    end

function match_handler.match_leave(context, dispatcher, tick, state, presences)
    return state
end

function match_handler.match_loop(context, dispatcher, tick, state, messages)
    if state.started ~= true then
        for _, user in ipairs(state.expected_players) do
            if context.presences[user.presence] == nil then
                return state
            end
        end
        state.started = true
        dispatcher.broadcast_message(OpCodes.MATCH_START, "", nil) -- send match start to all presences
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
