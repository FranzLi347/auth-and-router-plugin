# lua脚本实现openresty中的身份认证和动态路由

## 只完成大体框架，细节未完善

## todolist

1. 完善细节
2. 完善签名算法(防止重放攻击)
3. 支持rpc调用

参考openresty配置

```
  
    server {
        listen       38800;
        server_name  localhost;
        resolver 114.114.114.114;
        #charset koi8-r;
        #access_log  logs/host.access.log  main;
        
        
        location / {
        set $upstream '';
        #修改为直接返回text模式，而不是返回文件。默认配置在极速模式下得浏览器会形成下载文件
        default_type text/html;
        #关闭缓存模式，每次都读取lua文件，不使用已经缓存的lua文件（修改nginx.conf文件还是要重启的）
        lua_code_cache off;
        #在返回节点加载lua文件（相对路径即可）
        access_by_lua_file lua/apiauthlua.lua;
        proxy_http_version  1.1;
        proxy_cache_bypass  $http_upgrade;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "upgrade";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header X-Forwarded-Port  $server_port;
        proxy_pass $upstream;
    
    }
    }

```
