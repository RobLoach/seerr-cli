json=$(seerr_api GET /request/count)
seerr_table "$json" '
  ["Total:", .total],
  ["Movies:", .movie],
  ["TV:", .tv],
  ["Pending:", .pending],
  ["Approved:", .approved],
  ["Declined:", .declined],
  ["Processing:", .processing],
  ["Available:", .available],
  ["Completed:", .completed]'
