json=$(seerr_api GET "/user/${args[id]}")
seerr_table "$json" '
  ["ID:", .id],
  ["Name:", user_name],
  ["Email:", .email],
  ["Type:", (.userType | user_type)],
  ["Requests:", .requestCount],
  ["Created:", (.createdAt | date)],
  ["Updated:", (.updatedAt | date)]'
