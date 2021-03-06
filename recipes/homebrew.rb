include_recipe "sprout-base::user_owns_usr_local"

# Do not be tempted to use the git-resource to check out
# homebrew directly into /usr/local; it will fail if
# it finds *anything* in /usr/local, and it will find
# at least a bin directory because the user_owns_usr_local
# recipe creates it, and that's a pre-req.  Also, things like
# MacFuse, Audacity, and others tend to put things in /usr/local

directory Chef::Config[:file_cache_path] do
  action :create
  recursive true
  mode "0775"
  owner "root"
  group "staff"
end

git "#{Chef::Config[:file_cache_path]}/homebrew" do
  repository node["homebrew"]["repository"]
  revision node["homebrew"]["version"]
  destination "#{Chef::Config[:file_cache_path]}/homebrew"
  action :sync
end

execute "Copying homebrew's .git to /usr/local" do
  command "rsync -axSH #{Chef::Config[:file_cache_path]}/homebrew/ /usr/local/"
  user node['sprout']['user']
end

execute "Run git clean in /usr/local to clear out cruft after rsync" do
  command "cd /usr/local; git clean -fd"
  user node['sprout']['user']
end

ruby_block "Check that homebrew is running & working" do
  block do
    `brew --version`
    if $? != 0
      raise "Couldn't find brew"
    end
  end
end

directory "/usr/local/sbin" do
  owner node['sprout']['user']
end

directory "/Users/#{node['sprout']['user']}/Applications" do
  owner node['sprout']['user']
end
