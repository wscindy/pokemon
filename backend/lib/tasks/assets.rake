# 為了讓 Zeabur 的 pre-processing 不會失敗
# 建立一個空的 assets:precompile task
namespace :assets do
  task :precompile do
    puts "Skipping assets:precompile - using pre-built Vue frontend"
  end
end
