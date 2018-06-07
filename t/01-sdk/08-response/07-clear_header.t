use strict;
use warnings FATAL => 'all';
use Test::Nginx::Socket::Lua;
use t::Util;

$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();

plan tests => repeat_each() * (blocks() * 3);

run_tests();

__DATA__

=== TEST 1: response.clear_header() errors if arguments are not given
--- http_config eval: $t::Util::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
        }

        header_filter_by_lua_block {
            ngx.header.content_length = nil

            local SDK = require "kong.sdk"; ngx.ctx.kong_phase = require("kong.sdk.private.checks").phases.ACCESS
            local sdk = SDK.new()

            local ok, err = pcall(sdk.response.clear_header)
            if not ok then
                ngx.ctx.err = err
            end
        }

        body_filter_by_lua_block {
            ngx.arg[1] = ngx.ctx.err
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- response_body chop
header name must be a string
--- no_error_log
[error]



=== TEST 2: response.clear_header() errors if name is not a string
--- http_config eval: $t::Util::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
        }

        header_filter_by_lua_block {
            ngx.header.content_length = nil

            local SDK = require "kong.sdk"; ngx.ctx.kong_phase = require("kong.sdk.private.checks").phases.ACCESS
            local sdk = SDK.new()

            local po, err = pcall(sdk.response.clear_header, 127001, "foo")
            if not ok then
                ngx.ctx.err = err
            end
        }

        body_filter_by_lua_block {
            ngx.arg[1] = ngx.ctx.err
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- response_body chop
header name must be a string
--- no_error_log
[error]



=== TEST 3: response.clear_header() clears a given header
--- http_config eval
qq{
    $t::Util::HttpConfig

    server {
        listen unix:$ENV{TEST_NGINX_HTML_DIR}/nginx.sock;

        location /t {
            content_by_lua_block {
                ngx.header["X-Foo"] = "bar"
            }
        }
    }
}
--- config
    location = /t {
        proxy_pass http://unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        header_filter_by_lua_block {
            ngx.header.content_length = nil

            local SDK = require "kong.sdk"; ngx.ctx.kong_phase = require("kong.sdk.private.checks").phases.ACCESS
            local sdk = SDK.new()

            sdk.response.clear_header("X-Foo")
        }

        body_filter_by_lua_block {
            ngx.arg[1] = "X-Foo: {" .. type(ngx.header["X-Foo"]) .. "}"
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- response_body chop
X-Foo: {nil}
--- no_error_log
[error]



=== TEST 4: response.clear_header() clears multiple given headers
--- http_config eval
qq{
    $t::Util::HttpConfig

    server {
        listen unix:$ENV{TEST_NGINX_HTML_DIR}/nginx.sock;

        location /t {
            content_by_lua_block {
                ngx.header["X-Foo"] = { "hello", "world" }
            }
        }
    }
}
--- config
    location = /t {
        proxy_pass http://unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        header_filter_by_lua_block {
            ngx.header.content_length = nil

            local SDK = require "kong.sdk"; ngx.ctx.kong_phase = require("kong.sdk.private.checks").phases.ACCESS
            local sdk = SDK.new()

            sdk.response.clear_header("X-Foo")
        }

        body_filter_by_lua_block {
            ngx.arg[1] = "X-Foo: {" .. type(ngx.header["X-Foo"]) .. "}"
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- response_body chop
X-Foo: {nil}
--- no_error_log
[error]



=== TEST 5: response.clear_header() clears headers set via set_header
--- http_config eval: $t::Util::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
        }

        header_filter_by_lua_block {
            ngx.header.content_length = nil

            local SDK = require "kong.sdk"; ngx.ctx.kong_phase = require("kong.sdk.private.checks").phases.ACCESS
            local sdk = SDK.new()

            sdk.response.set_header("X-Foo", "hello")
            sdk.response.clear_header("X-Foo")
        }

        body_filter_by_lua_block {
            ngx.arg[1] = "X-Foo: {" .. type(ngx.header["X-Foo"]) .. "}"
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- response_body chop
X-Foo: {nil}
--- no_error_log
[error]



=== TEST 6: response.clear_header() clears headers set via add_header
--- http_config eval: $t::Util::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
        }

        header_filter_by_lua_block {
            ngx.header.content_length = nil

            local SDK = require "kong.sdk"; ngx.ctx.kong_phase = require("kong.sdk.private.checks").phases.ACCESS
            local sdk = SDK.new()

            sdk.response.add_header("X-Foo", "hello")
            sdk.response.clear_header("X-Foo")
        }

        body_filter_by_lua_block {
            ngx.arg[1] = "X-Foo: {" .. type(ngx.header["X-Foo"]) .. "}"
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- response_body chop
X-Foo: {nil}
--- no_error_log
[error]