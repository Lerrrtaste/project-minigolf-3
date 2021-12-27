local nk = require("nakama")

local function set_guest_metadata(context, outgoing_payload, incoming_payload)
    -- set metadata on guest accounts for cleanup later

    if incoming_payload.account.vars.guest ~= nil then
        local user_id = context.user_id
        local metadata = { guest = true }

        local status, err = pcall(nk.account_update_id, user_id, metadata)
        if (not status) then
          nk.logger_info((string.format("Account update error: %q",err)))
        end
    end
end

nk.register_req_after(set_guest_metadata, "AuthenticateCustom")


-- TODO delete guest accounts on startup
--nk.run_once(function(context)
--  -- This is to create a system ID that cannot be used via a client.
--  local system_id = context.env["SYSTEM_ID"]
--
--  nk.sql_exec([[
--INSERT INTO users (id, username)
--VALUES ($1, $2)
--ON CONFLICT (id) DO NOTHING
--  ]], { system_id, "system_id" })
--end)
