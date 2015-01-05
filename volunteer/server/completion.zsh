compctl -K _db_interface ./db_interface.rb

_db_interface() {
  local words completions
  read -cA words

  if [ "${#words}" -eq 2 ]; then
    completions="$(./db_interface.rb commands)"
  else
    completions="$(./db_interface.rb completions ${words[2,-2]})"
  fi

  reply=("${(ps:\n:)completions}")
}


