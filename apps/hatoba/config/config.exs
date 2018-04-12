use Mix.Config

config :porcelain, driver: Porcelain.Driver.Basic

config :hatoba,
  base_dir: "/tmp/hatoba",
  booru_url: "http://httpbin.org/post",
  booru_user: "user",
  booru_api_key: "api_key"
