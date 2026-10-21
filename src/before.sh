## Runs after the command line is parsed, before any command.
case $action in
  # Completions don't talk to Seerr, so a broken config shouldn't stop them.
  completions) ;;
  # `config set` may create the config file, or fix a bad value in it.
  "config set") seerr_settings_resolve lenient ;;
  *) seerr_settings_resolve ;;
esac
