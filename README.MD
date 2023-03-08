# lua脚本实现openresty中的身份认证和动态路由

## 只完成大体框架，细节未完善

## todolist

1. 完善细节
2. 完善签名算法(防止重放攻击)
3. 直接rpc调用

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
            #在返回节点加载lua文件（相对路径即可）
            access_by_lua_file lua/apiauthlua.lua;
            proxy_pass $upstream;
        }
        
    }

```
