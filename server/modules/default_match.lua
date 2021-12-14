local nk = require("nakama")
local match_handler = {}

function match_handler.match_init(context, setupstate)
  local gamestate = {}
  local tickrate = 10
  local label = ""
  return gamestate, tickrate, label
end

function match_handler.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
  local acceptuser = true
  return state, acceptuser
end

function match_handler.match_join(context, dispatcher, tick, state, presences)
  return state
end

function match_handler.match_leave(context, dispatcher, tick, state, presences)
  return state
end

function match_handler.match_loop(context, dispatcher, tick, state, messages)
  return state
end

function match_handler.match_terminate(context, dispatcher, tick, state, grace_seconds)
  return state
end

function match_handler.match_signal(context, dispatcher, tick, state, data)
  return state, data
end

return match_handler
