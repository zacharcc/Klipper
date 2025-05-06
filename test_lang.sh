#!/bin/bash

select_lang() {
    local options=("English" "Czech" "German")
    local lang_codes=(1 2 3)
    local selected=0

    local GREEN="\033[1;32m"
    local RESET="\033[0m"

    echo ""
    echo "Select language using arrows (← →), confirm with [Enter]:"

    draw_selector() {
        echo -ne "\r\033[K"
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -ne "${GREEN}[${options[$i]}]${RESET} "
            else
                echo -ne " ${options[$i]}  "
            fi
        done
        echo -ne "\r"
    }

    draw_selector
    while true; do
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 rest
            key+=$rest
            case "$key" in
                $'\x1b[C') ((selected++)); ((selected >= ${#options[@]})) && selected=0 ;;
                $'\x1b[D') ((selected--)); ((selected < 0)) && selected=$((${#options[@]} - 1)) ;;
            esac
        elif [[ $key == "" ]]; then
            break
        fi
        draw_selector
    done

    echo ""
    echo "You selected: ${options[$selected]}"
    echo "Selected lang code: ${lang_codes[$selected]}"
}

select_lang
