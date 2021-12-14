local nk = require("nakama")
nk.logger_error("Hello")

local function matchmaker_matched(context, matched_users)
     nk.logger_info("--------------MatchMakerMatched----------------")

    local modulename = "default_match"
    local setupstate = { invited = matched_users }
    local matchid = nk.match_create(modulename, setupstate)
    return matchid
end

nk.register_matchmaker_matched(matchmaker_matched)
