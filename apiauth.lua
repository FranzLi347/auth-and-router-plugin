-- require
local sha = require "sha2"
-- golbal variables
local uri = ngx.var.uri
local headers = ngx.req.get_headers()
-- sign data form headers
local dab = require "mysql_helper"

local signDt = {
  access_key = headers["accessKey"],
  sign = headers["sign"],
  timestamp = headers["timestamp"],
  nouce = headers['nouce']
}


local salt = "franzli"

local function get_sign(access_key, timestamp, nouce)
  local sk = dab.get_secertkey_by_accesskey(access_key)
  if sk == nil then
    dab.auth_error(1)
    return
  end
  --todo Add nose to Redis and verify nose times
  return sha.sha1(access_key .. nouce .. salt .. sk)
end
local function main()
  -- validated the req parameter
  if not signDt.access_key
      or not signDt.sign
      or not signDt.timestamp
      or not signDt.nouce
      or os.time() - signDt.timestamp > 60000
  then
    dab.auth_error(2)
    return
  end
  local server_sign = tostring(get_sign(signDt.access_key, signDt.timestamp, signDt.nouce))
  if server_sign == signDt.sign then
    -- set proxy_pass path
    ngx.var.upstream = dab.get_real_api(uri)
    return
  else
    dab.auth_error("   server    " .. server_sign .. "   remote    " .. signDt.sign)
    return
  end
end


-- main function
main()
