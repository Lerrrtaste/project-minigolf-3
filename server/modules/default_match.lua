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

    -- load map object
    --local user_id = "4ec4f126-3f9d-11e7-84ef-b7c182b36521" -- some user ID.
    --local object_ids = {
    --{collection = "maps", key = "1640202596", user_id = setupstate.map_owner_id} --a5e9f13a-3a2c-4dbf-a490-bc02412fb4f9"} --.map_id}
    --}
    --local objects = nk.storage_read(object_ids)
    --nk.logger_info("Should read now: ")
    --for _, r in ipairs(objects) do
    --    local message = string.format("read: %q, write: %q, value: %q", r.permission_read, r.permission_write, r.value.metadata.name)
    --    nk.logger_info(message)
    --end

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
        nk.logger_info(nk.json_encode(user))
        nk.logger_info(nk.json_encode(state.players[user.user_id]))
        state.players[user.user_id].joined = true
    end

    local op_code = OpCodes.MATCH_CONFIG
    local data = nk.json_encode({map_id= state.map_id, map_owner_id= state.map_owner_id})
    local reciever = presences

    dispatcher.broadcast_message(op_code, data, reciever)
    return state
end


function match_handler.match_leave(context, dispatcher, tick, state, presences)
    -- set players joined to false
    -- broadcasts PLAYER_LEFT to all

    for _, user in ipairs(presences) do
        state.players[user.user_id].joined = false
    end

    local op_code = OpCodes.PLAYER_LEFT
    local data = nk.json_encode({
        left_players = presences,
    })
    dispatcher.broadcast_message(op_code, data, nil)
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
            if user.joined == false then
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
                    for k, v in ipairs(state.turn_order)do
                        state.next_player_idx = ((state.next_player_idx) % #state.turn_order) +1 -- increment next player idx (indices start at 1)
                        if state.players[state.turn_order[state.next_player_idx]].finished == false then -- skip finished players TODO skip left players too
                            break
                        end
                    end


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
                        -- table.remove(state.turn_order,k)
                        -- state.next_player_idx = state.next_player_idx -1 -- hack because it gets incremented again below
                        state.players[msg.sender.user_id].finished = true
                        break
                    end
                end

                -- end match if no players left
                for k, player in pairs(state.players) do
                    if player.finished == false then
                        break -- not all finished
                    end

                    -- end match
                    local _turn_count = {}
                    for _, v in ipairs(state.turn_order) do
                        _turn_count[v] = state.players[v].turn_count
                    end
                    local data = nk.json_encode({turn_count = _turn_count})
                    dispatcher.broadcast_message(OpCodes.MATCH_END, data)
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

return match_handler

