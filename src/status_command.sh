json=$(seerr_api GET "/status$(seerr_query checkUpdateAvailable true)")
seerr_table "$json" '
  ["Version:", .version],
  ["Commit:", .commitTag],
  ["Update available:", (.updateAvailable | yes_no)],
  ["Commits behind:", .commitsBehind],
  ["Restart required:", (.restartRequired | yes_no)]'
