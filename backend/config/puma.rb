# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# ==================== 🔥 WebSocket 支援關鍵設定 ====================

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
preload_app!

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# ==================== Worker 相關設定 ====================

# Code to run before workers are forked from the master process
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Code to run immediately before master process forks workers
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# ==================== WebSocket 超時設定 ====================

# Increase worker timeout for WebSocket connections
# WebSocket connections can be long-lived, so we need to increase the timeout
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# In production, set a reasonable timeout (e.g., 60 seconds)
worker_timeout ENV.fetch("WORKER_TIMEOUT") { 60 }.to_i if ENV.fetch("RAILS_ENV", "development") == "production"

# ==================== 錯誤處理 (便於 Debug) ====================

# Only in production, add error handling for debugging
if ENV['RAILS_ENV'] == 'production'
  # This will catch errors during request handling
  lowlevel_error_handler do |e, env, status_code|
    [status_code, {}, ["An error has occurred: #{e}\n#{e.backtrace.join("\n")}"]]
  end
end

# ==================== 啟用 Keep-Alive (WebSocket 需要) ====================

# Enable keep-alive for WebSocket connections
enable_keep_alives true

# Persistent timeout for WebSocket
persistent_timeout 600

# First data timeout
first_data_timeout 30
