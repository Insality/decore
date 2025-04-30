local defold = require("nakama.engine.defold")
local nakama = require("nakama.nakama")
local nakama_session = require("nakama.session")
local log = require("log.log")
local uuid = require("libs.uuid")

local logger = log.get_logger("nakama")

local M = {}

local SESSION_FILE_PATH = sys.get_save_file(sys.get_config_string("project.title", "nakama"), "nakama_session")

---@class nakama.client

---@class nakama.session
---@field expires number
---@field token string

---@class nakama.socket_result.match
---@field match nakama.match
---@field error string|nil

---@class nakama.socket
---@field create fun(client)
---@field connect fun(callback)
---@field send fun(message, callback)
---@field on_disconnect fun(fn)
---@field channel_join fun(target, type, persistence, hidden, callback)
---@field channel_leave fun(channel_id, callback)
---@field channel_message_send fun(channel_id, content, callback)
---@field channel_message_remove fun(channel_id, message_id, callback)
---@field channel_message_update fun(channel_id, message_id, content, callback)
---@field match_data_send fun(match_id, op_code, data, presences, reliable, callback)
---@field match_create fun(name, callback): nakama.socket_result.match
---@field match_join fun(match_id, token, metadata, callback)
---@field match_leave fun(match_id, callback)
---@field matchmaker_add fun(min_count, max_count, query, string_properties, numeric_properties, count_multiple, callback)
---@field matchmaker_remove fun(ticket, callback)
---@field party_create fun(open, max_size, callback)
---@field party_join fun(party_id, callback)
---@field party_leave fun(party_id, callback)
---@field party_promote fun(party_id, presence, callback)
---@field party_accept fun(party_id, presence, callback)
---@field party_remove fun(party_id, presence, callback)
---@field party_close fun(party_id, callback)
---@field party_join_request_list fun(party_id, callback)
---@field party_matchmaker_add fun(party_id, min_count, max_count, query, string_properties, numeric_properties, count_multiple, callback)
---@field party_matchmaker_remove fun(party_id, ticket, callback)
---@field party_data_send fun(party_id, op_code, data, callback)
---@field status_follow fun(user_ids, usernames, callback)
---@field status_unfollow fun(user_ids, callback)
---@field status_update fun(status, callback)
---@field on_channel_presence_event fun(fn)
---@field on_match_presence_event fun(callback: fun(message: nakama.socket_result.on_match_presence.event))
---@field on_match_data fun(callback: fun(message: nakama.socket_result.match_data.event))
---@field on_match fun(fn)
---@field on_matchmaker_matched fun(fn)
---@field on_notifications fun(fn)
---@field on_party_presence_event fun(fn)
---@field on_party fun(fn)
---@field on_party_data fun(fn)
---@field on_party_join_request fun(fn)
---@field on_party_leader fun(fn)
---@field on_status_presence_event fun(fn)
---@field on_status fun(fn)
---@field on_stream_data fun(fn)
---@field on_error fun(fn)
---@field on_channel_message fun(fn)

---@class nakama.socket_result.on_match_presence.event
---@field match_presence_event nakama.socket_result.on_match_presence

---@class nakama.socket_result.on_match_presence
---@field match_id string
---@field joins nakama.presence[]
---@field leaves nakama.presence[]

---@class nakama.socket_result.match_data.event
---@field match_data nakama.socket_result.match_data

---@class nakama.socket_result.match_data
---@field match_id string
---@field op_code number
---@field data string
---@field presence nakama.presence

---@class nakama.presence
---@field username string
---@field session_id string
---@field user_id string

---@class nakama.match
---@field match_id string
---@field self nakama.presence
---@field presences nakama.presence[]
---@field size number

---@class nakama.session_file
---@field token string|nil
---@field player_id string|nil
local SESSION = sys.load(SESSION_FILE_PATH) or {
	token = nil,
	player_id = nil
}


---@param str string
---@param ending string
local function string_ends(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end


---@param entity entity.nakama
---@param callback function|nil
function M.connect(entity, callback)
	local token = SESSION.token
	local n = entity.nakama
	n.client = n.client or M.create_nakama_client(n.server_key, n.server_host, n.server_port, n.use_ssl)
	n.socket = n.socket or M.create_nakama_socket(n.client)

	if n.is_connected then
		logger:error("Call server connect while already connected")
		return
	end

	n.is_connecting = true
	nakama.sync(function()
		token = M.check_new_user(entity, token)

		if M.is_token_empty(token) then
			logger:warn("Can't auth on server")
			n.is_connecting = false
			return nil
		end

		token = M.check_session(entity, token)

		if M.is_token_empty(token) then
			logger:warn("Can't auth on server, drop the connection flow")
			n.is_connecting = false
			return nil
		end

		M.socket_connect(entity, callback)
	end)
end

---Return nakama client config
---@param server_key string
---@param host string
---@param port number
---@param is_ssl boolean
---@return table nakama client config
function M.create_nakama_client(server_key, host, port, is_ssl)
	local config = {
		host = host,
		port = port,
		use_ssl = is_ssl,
		username = server_key,
		password = "",
		engine = defold,
		timeout = 10, -- connection timeout in seconds
	}
	return nakama.create_client(config)
end


---Return nakama socket client
---@param client nakama.client
---@return nakama.socket
function M.create_nakama_socket(client)
	return nakama.create_socket(client)
end


---Check and update if required the nakama session
---@param entity entity.nakama
function M.refresh_session(entity)
	local n = entity.nakama
	local session = n.session
	if not session or M.is_session_expire_soon(session) then
		logger:debug("Session token will expire soon, refresh")
		nakama.sync(function()
			M.auth(entity)
		end)
	end
end


---Check and update if required the nakama session
---@param entity entity.nakama
---@param token string|nil
function M.check_session(entity, token)
	local session = nakama_session.create({ token = token })
	if M.is_session_expire_soon(session) then
		logger:info("Session has expired, call reauth")
		token = M.auth(entity)
	else
		logger:debug("Session token is valid")
		M.set_session_token(entity, session)
	end
	return token
end


---@param entity entity.nakama
---@param callback function|nil
function M.socket_connect(entity, callback)
	local n = entity.nakama
	local socket_connected, socket_error = n.socket.connect()
	n.is_connecting = false

	if socket_connected then
		logger:info("Socket connected")
		n.is_connected = true

		if callback then
			callback()
		end
	else
		logger:error("Socket error", { error = socket_error })
		M.set_session_token(entity, nil)

		if string_ends(socket_error, "401") then
			logger:info("Token expired, reset")
			M.connect(entity, callback)
		end
	end
end


---@param entity entity.nakama
---@param session nakama.session|nil
function M.set_session_token(entity, session)
	local n = entity.nakama

	if session and session.token then
		SESSION.token = session.token
		sys.save(SESSION_FILE_PATH, SESSION)

		nakama.set_bearer_token(n.client, session.token)
		n.session = session
	else
		SESSION.token = ""
		sys.save(SESSION_FILE_PATH, SESSION)

		n.session = nil
	end
end


---@param token string|nil
function M.is_token_empty(token)
	return not token or token == ""
end


---@param session nakama.session
function M.is_session_expire_soon(session)
	local time_to_expire = (session.expires - os.time())
	return time_to_expire < 300 -- 5 minutes
end


---@param entity entity.nakama
function M.auth(entity)
	local player_id = M.get_player_id()
	logger:debug("Auth started", { id = player_id })

	local client = entity.nakama.client
	local session = nakama.authenticate_device(client, player_id, nil, true, player_id)
	if not session.token then
		logger:info("Auth failed, no session")
		return nil
	end

	M.set_session_token(entity, session)

	logger:debug("Authenticated", { token = session.token, user_id = session.user_id })
	return session.token
end


---@param entity entity.nakama
function M.check_new_user(entity, token)
	if M.is_token_empty(token) then
		logger:debug("Auth for new user")
		token = M.auth(entity)
	end

	return token
end


function M.get_player_id()
	-- TODO Test
	SESSION.player_id = uuid()

	if not SESSION.player_id then
		SESSION.player_id = uuid()
		sys.save(SESSION_FILE_PATH, SESSION)
	end

	return SESSION.player_id
end


return M
