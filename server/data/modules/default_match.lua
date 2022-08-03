local nk = require("nakama")
local match_handler = {}

OpCodes = {
   MATCH_CONFIG = 110,
   MATCH_CLIENT_READY = 111,
   MATCH_START = 112,
   MATCH_END = 115,

   NEXT_TURN = 120,
   TURN_COMPLETED = 125,

   REACHED_FINISH = 130,

   PLAYER_LEFT = 150,

   BALL_IMPACT = 201,
   BALL_SYNC = 202,
}

function match_handler.match_init(context, setupstate)
    -- setup inital state
    local gamestate = {
        map_id = setupstate.map_id,
        map_owner_id = setupstate.map_owner_id,

        players = {}, -- key=user_id val=presence
        turn_order = {}, -- numbered user ids of not finished players (shrinks)
        next_player_idx = 1,

        started = false,
    }

    for _, user in ipairs(setupstate.matched_users) do
        gamestate.players[user.presence.user_id] = {
            presence = user.presence,
            properties = user.properties,
            joined = false,
            left = false, -- TODO use to end match if all left
            ready = false,
            finished = false,
            ball_pos = nil,
            turn_count = 0
        }
    end

    local tickrate = 5
    local label = ""
    return gamestate, tickrate, label
end

function match_handler.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
    -- accept all

    local acceptuser = true
    return state, acceptuser
end

function match_handler.match_join(context, dispatcher, tick, state, presences)
    -- Sets players.joined
    -- Sends MATCH_CONFIG

    for _, user in ipairs(presences) do
        --nk.logger_info(nk.json_encode(user))
        --nk.logger_info(nk.json_encode(state.players[user.user_id]))
        state.players[user.user_id].joined = true
    end

    local op_code = OpCodes.MATCH_CONFIG
    local user_ids = {}
    for k, v in pairs(state.players) do
        table.insert(user_ids, v.presence.user_id)
    end
    nk.logger_info(nk.json_encode(user_ids))
    local data = {
        map_id = state.map_id,
        map_owner_id = state.map_owner_id,
        expected_user_ids = user_ids,
    }
    data = nk.json_encode(data)
    local reciever = presences

    dispatcher.broadcast_message(op_code, data, reciever)
    return state
end


function match_handler.match_leave(context, dispatcher, tick, state, presences)
    -- set players joined to false
    -- broadcasts PLAYER_LEFT to all
    -- end match if no one left

    for _, user in ipairs(presences) do
        state.players[user.user_id].joined = false
        state.players[user.user_id].left = true
    end

    local op_code = OpCodes.PLAYER_LEFT
    local data = nk.json_encode({
        left_players = presences,
    })
    dispatcher.broadcast_message(op_code, data, nil)


    if is_match_finished(state) then
        end_match(state, dispatcher)
        return nil
    end

    -- if leaving player was current_player
    local current_player = state.turn_order[state.next_player_idx]
    if state.players[current_player].left then
        -- next_player
        increment_next_player_idx(state)
        -- broadcast NEXT_TURN
        local data = nk.json_encode({next_player = state.turn_order[state.next_player_idx]})
        dispatcher.broadcast_message(OpCodes.NEXT_TURN, data, nil)
    end

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
    if state.started == false then
        for _, msg in ipairs(messages) do
            if msg.op_code == OpCodes.MATCH_CLIENT_READY then
                state.players[msg.sender.user_id].ready = true
                nk.logger_info(string.format("%s is now ready",msg.sender.user_id))
            end
        end

        -- wait for all players to join
        for _, user in pairs(state.players) do
            if user.joined == false or user.ready == false then
                return state --abort
            end
        end

        -- start match
        -- generate turn order
        local data = {presences = {}}

        for _, player in pairs(state.players) do
            data.presences[player.presence.user_id] = player.presence -- collect for MATCH_START msg

            local pos = math.random(1, #state.turn_order+1)
            table.insert(state.turn_order, pos, player.presence.user_id)
        end

        data.turn_order = state.turn_order

        -- broadcast match start and turn order
        state.started = true
        data = nk.json_encode(data)
        dispatcher.broadcast_message(OpCodes.MATCH_START, data, nil) -- send match start to all presences
    end

    -- match running
    if messages ~= nil then

        -- process messages
        for _, msg in ipairs(messages) do

            -- BALL_IMPACT
            if  msg.op_code == OpCodes.BALL_IMPACT then
                -- forward to all (if its players turn)
                if state.turn_order[state.next_player_idx] == msg.sender.user_id then
                    dispatcher.broadcast_message(OpCodes.BALL_IMPACT, msg.data, nil, msg.sender)
                    -- TODO verify max impact_vec length of 1 (not possible yet because BALL_SYNC cant be confirmed yet)
                end


                -- BALL_SYNC
            elseif msg.op_code == OpCodes.BALL_SYNC then
                -- broadcast to all
                -- update players.ball_pos
                dispatcher.broadcast_message(OpCodes.BALL_SYNC, msg.data, nil, msg.sender)
                state.players[msg.sender.user_id].ball_pos = nk.json_decode(msg.data)["synced_pos"]


                -- TURN_COMPLETED
            elseif msg.op_code == OpCodes.TURN_COMPLETED then
                -- verify its the senders turn
                if msg.sender.user_id == state.turn_order[state.next_player_idx] then
                    -- increment turn_count
                    state.players[msg.sender.user_id].turn_count = state.players[msg.sender.user_id].turn_count + 1

                    -- increment next_player_idx
                    increment_next_player_idx(state)

                    -- broadcast NEXT_TURN
                    local data = nk.json_encode({next_player = state.turn_order[state.next_player_idx]})
                    dispatcher.broadcast_message(OpCodes.NEXT_TURN, data, nil)
                else
                    nk.logger_error("Recieved TURN_COMPLETED from wrong player, ignoring.")
                end


                -- REACHED_FINISH
            elseif msg.op_code == OpCodes.REACHED_FINISH then
                -- remove from turn_order
                for k, user_id in ipairs(state.turn_order) do
                    if user_id == msg.sender.user_id then
                        state.players[msg.sender.user_id].finished = true
                        break
                    end
                end

                if is_match_finished(state) then
                    state.players[msg.sender.user_id].turn_count = 1 + state.players[msg.sender.user_id].turn_count -- because last players TURN_COMPLETED wont be recognized
                    end_match(state, dispatcher)
                    return nil
                end

                -- forward TURN_COMPLETED
                dispatcher.broadcast_message(OpCodes.TURN_COMPLETED, nil, nil, msg.sender)-- broadcast FINISHED_TURN
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

function is_match_finished(state)
    local all_finished = true
    for k, player in pairs(state.players) do
        if player.finished == false and player.left == false then
            all_finished = false
            break -- not all finished
        end
    end
    return all_finished
end

function end_match(state, dispatcher)
    local _turn_count = {}
    for _, v in ipairs(state.turn_order) do
        if state.players[v].left == false then
            _turn_count[v] = state.players[v].turn_count
        end
    end
    local data = nk.json_encode({turn_count = _turn_count})
    dispatcher.broadcast_message(OpCodes.MATCH_END, data)
end

function increment_next_player_idx(state)
   for k, v in ipairs(state.turn_order)do
        state.next_player_idx = ((state.next_player_idx) % #state.turn_order) +1 -- increment next player idx (indices start at 1)
        if state.players[state.turn_order[state.next_player_idx]].left == false then -- skip left players
            if state.players[state.turn_order[state.next_player_idx]].finished == false then -- skip finished players
                break -- meaning this one is next (not left and not finished)
            end
        end
    end
end

return match_handler

