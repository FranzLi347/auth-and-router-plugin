-- require
local cjson = require "cjson"
local sha = require "sha2"
-- golbal variables
local uri = ngx.var.uri
local headers = ngx.req.get_headers()
-- sign data form headers
local signDt = {
  access_key = headers["accessKey"],
  sign = headers["sign"],
  timestamp = headers["timestamp"],
  nouce = headers['nouce']
}
local props = {
  host = "127.0.0.1",
  port = 3306,
  database = "frzApi",
  user = "root",
  password = "123456"
}

local function close_db( db )
    if not db then
      return
    end
    db:close()
end
local mysql = require("resty.mysql")
  -- 创建实例
local db, err = mysql:new()
if not db then
    ngx.say("new  mysql error:", err)
    return
end
  -- 设置超时时间(毫秒)
db:set_timeout(5000)
local res, err, errno, sqlstate = db:connect(props)
if not res then
    ngx.say("connect to mysql error : ", err, " , errno : ", errno, " , sqlstate : ", sqlstate)
    return close_db(db)
end

local function auth_error(tag)
  ngx.status = ngx.HTTP_UNAUTHORIZED
  ngx.say(cjson.encode({msg = "bad auth please check your req param" .. tag,code = 400}))
end

local function get_secertKey_by_accesskey(access_key) 
    local quoted= ngx.quote_sql_str(tostring(access_key))
    local sql = "SELECT * FROM key_info WHERE access_key = " .. quoted .."and is_delete = 0"
    res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.say("database Error \n" .. err)
        close_db(db)
        return
    end
    for i, row in ipairs(res) do
        for name, value in pairs(row) do
          if name == "secert_key" then
            return value
          end

        end
    end
end


local function get_real_api(uri)
  local quoted= ngx.quote_sql_str(tostring(uri))
  local sql = "SELECT * FROM uri_mapping WHERE source = " .. quoted .."and is_delete = 0"
  res, err, errno, sqlstate = db:query(sql)
  if not res then
    ngx.say("database Error \n" .. err)
    close_db(db)
    return
  end
  for i, row in ipairs(res) do
    for name, value in pairs(row) do
       if name == "taget" then
          return value;
      end
    end
  end
end



local salt = "franzli"
local function get_sign(access_key,timestamp,nouce)
  local sk = get_secertKey_by_accesskey(access_key)
  if sk == nil then
    auth_error(1)
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
      auth_error(2)
      return
    end
    local server_sign = tostring(get_sign(signDt.access_key,signDt.timestamp,signDt.nouce))

    if server_sign == signDt.sign then
      -- set proxy_pass path
      ngx.var.upstream = get_real_api(uri)
      return
    else
      auth_error("   server    " .. server_sign  .. "   remote    " .. signDt.sign)
      return
    end
end
-- main function
main()

