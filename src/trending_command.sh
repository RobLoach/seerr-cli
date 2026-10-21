query=$(seerr_query page "${args[--page]}" language "${args[--language]:-}" mediaType "${args[--type]}" timeWindow "${args[--window]}")
json=$(seerr_api GET "/discover/trending$query")
seerr_table "$json" results_table
seerr_footer "$json" page_footer
