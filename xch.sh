#!/bin/bash

# Terminal fiat & crypto currency converter in Bash using openexchangerates.org
# Get a free API key via https://openexchangerates.org/signup/free 
# Supported currencies: https://docs.openexchangerates.org/reference/supported-currencies
#
# Usage: bash xch.sh [amount] [base-currency] [target-currency]

# Configuration
XCH_OPENEX_API_KEY=              # openexchangerates.org API KEY (Can also be set as OPENEX_API_KEY environment variable)
XCH_CACHE_TIME=5                 # Caching time for exchange rates in minutes
XCH_DIR="$HOME/.cache/xch"       # Directory for cached exchange rates

# Program

# Loading spinner (Source: https://github.com/aoki/sh-spinner)
spinner() {
  # Clear Line
  CL="\e[2K"
  # Spinner Character
  SPINNER="⣷⣯⣟⡿⢿⣻⣽⣾"
  # Spinner loop
  while :; do
    jobs %1 > /dev/null 2>&1
    [ $? = 0 ] || {
      break
    }
    local SPINNER_COLORNUM
    SPINNER_COLORNUM=7
    for (( i=0; i<${#SPINNER}; i++ )); do
      env sleep 0.1
        if [ $SPINNER_COLORNUM -eq 7 ]; then
          SPINNER_COLORNUM=1
        else
          SPINNER_COLORNUM=$((SPINNER_COLORNUM + 1))
        fi
      local COLOR
      COLOR=$(tput setaf ${SPINNER_COLORNUM}) 
      printf "${CL}${COLOR}${SPINNER:$i:1}\r"
    done
  done
}

# Define colors
COL='\033[0m'
DIM='\033[2;31m'
BOLD='\033[1;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
WHITE='\033[1;37m'

# Check if API Key is set at top of script or as environment variable, otherwise exit
if [[ -z $XCH_OPENEX_API_KEY ]]; then
  XCH_OPENEX_API_KEY="$OPENEX_API_KEY" 
  if [[ -z $XCH_OPENEX_API_KEY ]]; then 
    echo -e "${RED}Error: ${WHITE}Please set OpenExchange API Key at top of script or as OPENEX_API_KEY environment variable. \n"
    exit 1
  fi 
fi

XCH_JSON="$XCH_DIR/xch.json" # File for cached exchange rates

# Create Cache directory
mkdir -p "$XCH_DIR"

VOL="$1"      # Exchange amount
BASE="${2^^}" # Base currency code
CONV="${3^^}" # Target currency code

# Check for cached JSON, update every 5 minutes
if [[ ! -f "$XCH_JSON" || $(find "$XCH_JSON" -mmin +"$XCH_CACHE_TIME") ]]; then
  tput civis # Disable cursor for loading spinner
  curl -sL "https://openexchangerates.org/api/latest.json?app_id=\"${OPENEX_API_KEY}\"&show_alternative=true" >| "${XCH_JSON}" && sleep 1 \
  & spinner
  tput cnorm  # Re-enable cursor
fi

# Check if currency codes exist
HASBASE=$(jq ".rates | has(\"$BASE\")" <"$XCH_JSON")
HASCONV=$(jq ".rates | has(\"$CONV\")" <"$XCH_JSON")

[[ "$HASBASE" == "false" ]] && {
  echo -e "${RED}$BASE${COL} not found"
  exit 1
}
[[ "$HASCONV" == "false" ]] && {
  echo -e "${RED}$CONV${COL} not found"
  exit 1
}

# Get rates
VALBASE=$(jq .rates."${BASE}" <"$XCH_JSON")
VALCONV=$(jq .rates."${CONV}" <"$XCH_JSON")

# Print rates
XCH=$(echo "$VOL $VALBASE $VALCONV" | awk '{printf "%f", $1 / ($2 / $3)}')
echo -e "${BOLD}$1 ${RED}$BASE ${DIM}in ${ORANGE}$CONV ${COL}:\n"
echo -e "${GREEN}✔ $XCH ${ORANGE} $CONV\n"

