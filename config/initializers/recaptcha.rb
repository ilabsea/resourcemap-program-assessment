CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'recaptcha.yml'))[Rails.env] rescue {}

Recaptcha.configure do |config|
  config.site_key  = CONFIG['site_key']
  config.secret_key = CONFIG['secret_key']
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end
