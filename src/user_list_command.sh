query=$(seerr_query \
  take "${args[--take]}" \
  skip "$(seerr_skip)" \
  sort "${args[--sort]}")
json=$(seerr_api GET "/user$query")
seerr_table "$json" '
  ["ID", "NAME", "EMAIL", "TYPE", "REQUESTS", "CREATED"],
  (.results[] | [.id, user_name, .email, (.userType | user_type), .requestCount, (.createdAt | date)])'
seerr_footer "$json" page_info_footer
