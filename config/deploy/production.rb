server "ec2-34-214-33-97.us-west-2.compute.amazonaws.com", user: "ubuntu", roles: %w(web app db)

set :ssh_options,
  keys: %w(~/.pem/production.nophi.pem),
  forward_agent: false,
  auth_methods: %w(publickey)
