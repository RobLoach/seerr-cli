query=$(seerr_query query "${args[query]}" page "${args[--page]}" language "${args[--language]:-}")
json=$(seerr_api GET "/search$query")
seerr_table "$json" results_table
seerr_footer "$json" page_footer
