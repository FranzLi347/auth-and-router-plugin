-- require
local cjson = require "cjson"
-- golbal variables
local uri = ngx.var.uri
local headers = ngx.req.get_headers()
local access_key = headers["accessKey"]
local sign = headers["sign"]
local timestamp = headers["timestamp"]
local nouce = headers['nouce']
local sha1 = require("sha1")

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

local props = {
    host = "127.0.0.1",
    port = 3306,
    database = "frzApi",
    user = "root",
    password = "123456"
}

local res, err, errno, sqlstate = db:connect(props)

if not res then
    ngx.say("connect to mysql error : ", err, " , errno : ", errno, " , sqlstate : ", sqlstate)
    return close_db(db)
end

local skData = {}

local function get_secertKey_by_accesskey()
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
          skData[name] = value
        end
    end
end


local function get_sign(serverSk)
  return sha1(serverSk .. access_key)
end

local function auth()
    
    -- validated the req parameter
    -- if not access_key or not sign or not timestamp or not nouce then
    --     ngx.status = ngx.HTTP_UNAUTHORIZED
    --     ngx.say(cjson.encode({msg = "bad auth please check your req param",code = 400}))
    --     return
    -- end
    get_secertKey_by_accesskey()
    -- todo validated by sign
    if skData.secert_key == "123321" and skData.access_key == "123321" then
      local service = ngx.var.service
      local upstream = "http://v.api.aa1.cn/api/yiyan/index.php"
      ngx.var.upstream = upstream
    end
end




-- main function
-- default 
ngx.header.content_type = "application/json"
auth()
