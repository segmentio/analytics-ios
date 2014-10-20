if [[ ! -o interactive ]]; then
    return
fi

compctl -K _cli cli

_cli() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(cli commands)"
  else
    completions="$(cli completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}
