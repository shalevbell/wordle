#!/usr/bin/env bash

echo "Welcome to Wordle!"
echo

date=$(date +%Y-%m-%d)
if [[ "${1:-}" == "--date" && -n "${2:-}" ]]; then
    date=$2
fi

echo "Loading $date's word..."
echo
response=$(curl -s "https://www.nytimes.com/svc/wordle/v2/$date.json")
word=$(echo "$response" | jq -r '.solution' 2>/dev/null)

if [[ -z "$word" || "$word" == "null" ]]; then
    echo "Error: Could not fetch today's word"
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m'
RESET='\033[0m'

results=()

check_guess() {
    local guess=$1
    local answer=$2
    local result=""
    local used=()

    for ((i=0; i<5; i++)); do
        used[i]=0
    done

    for ((i=0; i<5; i++)); do
        if [[ "${guess:i:1}" == "${answer:i:1}" ]]; then
            used[i]=1
        fi
    done

    for ((i=0; i<5; i++)); do
        local char="${guess:i:1}"

        if [[ "$char" == "${answer:i:1}" ]]; then
            result+="${GREEN}${char}${RESET}"
        else
            local found=0
            for ((j=0; j<5; j++)); do
                if [[ "$char" == "${answer:j:1}" && ${used[j]} -eq 0 ]]; then
                    result+="${YELLOW}${char}${RESET}"
                    used[j]=1
                    found=1
                    break
                fi
            done

            if [[ $found -eq 0 ]]; then
                result+="${GRAY}${char}${RESET}"
            fi
        fi
    done

    echo -e "$result"
}

for ((attempt=1; attempt<6; attempt++)); do
    while true; do
        echo -ne "Word $attempt: "
        read -r guess
        guess=${guess,,}

        if [[ ${#guess} -ne 5 ]]; then
            echo "Error: Word must be exactly 5 letters"
            continue
        fi
        break
    done

    result=$(check_guess "$guess" "$word")
    results+=("$result")

    if [[ "$guess" == "$word" ]]; then
        echo -e "$result"
        echo
        echo "You guessed the word!"
        exit 0
    fi

    echo -e "$result"
    echo
done

echo -e "The word was: ${GREEN}${word}${RESET}"
echo "You guessed:"
for result in "${results[@]}"; do
    echo -e "$result"
done
echo "Better luck next time!"
