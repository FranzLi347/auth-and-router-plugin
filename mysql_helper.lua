local mysql = require("resty.mysql")
local cjson = require("cjson")

local _M = {}

local props = {
    host = "127.0.0.1",
    port = 3306,
    database = "frzApi",
    user = "root",
    password = "123456"
}

local function close_db(db)
    if not db then
        return
    end
    db:close()
end

function _M.get_secertkey_by_accesskey(access_key)
    local db, err = mysql:new()
    if not db then
        ngx.say("new mysql error:", err)
        return
    end
    db:set_timeout(5000)
    local res, err, errno, sqlstate = db:connect(props)
    if not res then
        ngx.say("connect to mysql error : ", err, " , errno : ", errno, " , sqlstate : ", sqlstate)
        close_db(db)
        return
    end
    local quoted = ngx.quote_sql_str(tostring(access_key))
    local sql = "SELECT * FROM key_info WHERE access_key = " .. quoted .. "and is_delete = 0"
    res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.say("database Error \n" .. err)
        close_db(db)
        return
    end
    for i, row in ipairs(res) do
        for name, value in pairs(row) do
            if name == "secert_key" then
                close_db(db)
                return value
            end
        end
    end
    close_db(db)
end

function _M.get_real_api(uri)
    local db, err = mysql:new()
    if not db then
        ngx.say("new mysql error:", err)
        return
    end
    db:set_timeout(5000)
    local res, err, errno, sqlstate = db:connect(props)
    if not res then
        ngx.say("connect to mysql error : ", err, " , errno : ", errno, " , sqlstate : ", sqlstate)
        close_db(db)
        return
    end
    local quoted = ngx.quote_sql_str(tostring(uri))
    local sql = "SELECT * FROM uri_mapping WHERE source = " .. quoted .. "and is_delete = 0"
    res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.say("database Error \n" .. err)
        close_db(db)
        return
    end
    for i, row in ipairs(res) do
        for name, value in pairs(row) do
            if name == "taget" then
                close_db(db)
                return value
            end
        end
    end
    close_db(db)
end

function _M.auth_error(tag)
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say(cjson.encode({ msg = "bad auth please check your req param" .. tag, code = 400 }))
end

return _M
