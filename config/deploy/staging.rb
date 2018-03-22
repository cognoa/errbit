server "35.165.8.120", user: "ubuntu", roles: %w(web app db)

set :ssh_options,
  forward_agent: false,
  auth_methods: %w(publickey)
