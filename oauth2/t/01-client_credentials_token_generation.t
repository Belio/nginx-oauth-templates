use Test::Nginx::Socket::Lua 'no_plan';

no_long_string();
no_diff();
run_tests();

__DATA__

=== TEST 1:

--- main_config
env THREESCALE_DEPLOYMENT_ENV;
env PROVIDER_KEY;
env SERVICE_ID;
env USER_KEY;
env CLIENT_ID;
env CLIENT_SECRET;
env API_BACKEND;
env PORT;
--- http_config
	lua_shared_dict api_keys 10m;
  server_names_hash_bucket_size 128;
  lua_package_path ";;$prefix/?.lua;$prefix/conf/?.lua";
  init_by_lua 'math.randomseed(ngx.time()) ; cjson = require("cjson")';

  resolver 8.8.8.8 8.8.4.4;

  upstream backend_API_BACKEND {
    # service name: SERVICE_NAME ;
    server API_BACKEND:PORT max_fails=5 fail_timeout=30;
  }
--- config
		lua_code_cache off;
		underscores_in_headers on;
    set_by_lua $deployment 'return os.getenv("THREESCALE_DEPLOYMENT_ENV")';
    set $threescale_backend "https://su1.3scale.net:443";

    location = /_threescale/check_credentials {
      internal;
      proxy_set_header  X-Real-IP  $remote_addr;
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header  Host "su1.3scale.net"; #needed. backend discards other hosts

      set $provider_key PROVIDER_KEY;
      set $service_id SERVICE_ID;

      proxy_pass $threescale_backend/transactions/oauth_authorize.xml?provider_key=$provider_key&service_id=$service_id&$args;
    }

    location = /oauth/token  {
      proxy_set_header  X-Real-IP  $remote_addr;
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header  Host $http_host;
      proxy_set_header  Content-Type "application/x-www-form-urlencoded";

      set $provider_key PROVIDER_KEY;

      content_by_lua_file get_token.lua;
    }

    location = /_threescale/oauth_store_token {
      internal;
      proxy_set_header  X-Real-IP  $remote_addr;
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header  Host "su1.3scale.net"; #needed. backend discards other hosts

      set $provider_keyPROVIDER_KEY;
      set $service_id SERVICE_ID;

      proxy_method POST;
      proxy_pass $threescale_backend/services/$service_id/oauth_access_tokens.xml?provider_key=$provider_key;
    }

--- pipelined_requests eval
[""]
--- more_headers eval
[""]
--- error_code eval
[""]