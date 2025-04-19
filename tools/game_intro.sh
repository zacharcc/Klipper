#!/bin/bash

draw_game_intro() {

## --- Colors ---
C0="\033[0m"
## Green:
G1="\033[38;5;22m"
G2="\033[38;5;28m"
G3="\033[38;5;34m"
G4="\033[38;5;40m"
G5="\033[38;5;46m"
## Blue:
B3="\033[38;5;33m"
## Yelow:
Y1="\033[38;5;94m"
Y2="\033[38;5;172m"
Y3="\033[38;5;214m"
Y4="\033[38;5;220m"
## White/Gray:
W1="\033[38;5;240m"
W2="\033[38;5;244m"
W3="\033[38;5;248m"
W4="\033[38;5;252m"
## Background:
BG1="\033[48;5;236m"
BG2="\033[48;5;238m"
## Frame:
F1="\033[38;5;235m"
F2="\033[38;5;236m"
F3="\033[38;5;237m"
F4="\033[38;5;238m"
F5="\033[38;5;239m"
F6="\033[38;5;240m"

## --- SLEEP Speed ---
SPEED_FAST=0.1
SPEED_MEDIUM=0.15
SPEED_SLOW=0.45

shai_hulud() {
    tput sc
    echo -ne "\033[6A"
    echo -e "${F3}█${C0}${BG1}                                   ${C0}${Y3}█░${C0} ${Y3}░████${Y2}█████${Y3}████░${C0} ${Y3}░█${BG1}                                       ${C0}${F3}█${C0}"	
    sleep 0.25
    echo -ne "\033[1A"
    echo -e "${F3}█${C0}${BG1}                                   ${C0}${Y3}█░${G4}█${Y3}░████${Y2}█████${Y3}████░${B3}█${Y3}░█${BG1}                                       ${C0}${F3}█${C0}"
    echo -ne "\033[5B"
    tput rc
}

## --- Progress Bar 0% [########] 100% ---
simulate_loading_bar_with_ascii() {
    local steps=24
    local delay=0.15
    local bar_width=24

    for i in $(seq 0 $steps); do
        percent=$(( i * 100 / steps ))
        done_count=$i
        left_count=$(( bar_width - done_count ))

        if (( done_count == 0 )); then
            done_section=""
        else
            done_section=$(printf '■%.0s' $(seq 1 $done_count))
        fi

        if (( done_count == bar_width )); then
            left_section=""
        else
            left_section=$(printf '□%.0s' $(seq 1 $left_count))
        fi

        echo -ne "\033[3A"
		formatted_percent=$(printf "%3d%%" "$percent")

        echo -e "                                                                ${F3}█${C0}${BG1} ${formatted_percent}                100% ${C0}${F3}█${C0}"
        echo -e "                                                                ${F3}█${C0}${BG1} ${done_section}${left_section} ${C0}${F3}█${C0}"
        echo -e "                                                                ${F3}${F1}█${F3}██████████████████████████${F1}█${C0}"

        sleep $delay
    done
}

echo -e ""
echo -e ""
sleep $SPEED_MEDIUM

echo -e "${F3}████████████████████████████████████████████████████████████████████████████████████████████████${F1}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}                                                                                               ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ▓ Game Save: ${formatted_game_save}                ▓ ARMOR: Chamber           ▓ STAMINA: 40% (Of max flow)     ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}                                                                                               ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ▓ LEVEL: ${formatted_level} Unlocked                                        ▓ AMMO: 3xASA, 2xPLA            ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}                                                                                               ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ▓ POWER: 100% (500 WATT)             ${C0}${Y4}████▒${BG1}  ${C0}${Y4}████▒${C0}${BG1}          ▓ Machine gun: AMS not connected ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}                                    ${C0}${Y3}████${Y4}█░░█${Y3}███${Y4}█░░█${Y3}████▒${BG1}                                       ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}                                   ${C0}${Y3}█░${B3}█${Y3}░████${Y2}█████${Y3}████░${G4}█${Y3}░█${BG1}                                       ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}                                   ${C0}${Y3}█░░█░░░░░░░░░░░░░█░░█▒${BG1}                                      ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${F6}███████████████████████████████${BG2} ${C0}${Y3}▒██${Y2}░░███████████░░${Y3}██▒${BG2} ${C0}${F6}█████████████████████████${BG1}             ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}        ${C0}${G4}█${G3}▒${C0}${BG2}                       ${C0}${Y2}▓░░█▓${W1}▒${W3}▒▒▒${W2}█${W1}▒${W3}▒▒▒${Y2}▓█░░▓${C0}${BG2}                           ${BG1}             ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G1}█${G2}█${G3}██${G4}█${G5}██${G3}▒${C0}${BG2}  ${C0}${G4}█${G3}██${G5}██${G3}▒${C0}${BG2}  ${C0}${G3}█${G2}█▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}██${G3}██${G4}█${G5}█${G3}▒${W1}▒${W3}█${W1}▒${W3}▒▒█${W4}██${W1}▒${W3}▒▒${W3}█${W1}▒${G4}░${G3}█${G2}██${G3}█${G5}█${G3}▒${C0}${BG2}  ${C0}${G1}█${G2}██${G4}██${G2}█${G1}▒${C0}${BG2}  ${C0}${G2}█${G1}█▒${C0}${BG2}   ${C0}${G3}█${G5}█${G3}▒${C0}${BG2}   ${BG1}             ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G1}█${G2}█${G1}▒${G4}${C0}${BG2}      ${C0}${G3}█${G1}█▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G3}█${G2}██${G3}█▒${G5}█${G4}█${G3}▒${C0}${BG2} ${C0}${G2}█${G1}█▒${BG2}  ${C0}${G2}█${G5}█${W2}▒${W4}█${W3}█${W1}▒${W3}█${W4}█${W1}▒${W4}█${W3}█${W1}▒${W3}█${W4}█${W1}▒${G3}█${G2}▓▒░█${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█${G1}▒${BG2}  ${C0}${G4}██${G3}▒${C0}${BG2} ${C0}${G3}██${G2}█▒${C0}${BG2} ${C0}${G2}██${G5}█${G3}▒${C0}${BG2}   ${BG1}             ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
shai_hulud
sleep 0.2
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G2}██${G3}██${G4}██${G3}█${G3}▒${C0}${BG2} ${C0}${G3}█${G2}█▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}██${G1}▒${G3}█${G4}█${G5}██${G3}▒${C0}${BG2} ${C0}${G2}██▒${C0}${BG2}  ${C0}${G3}█${G5}█${G3}▒${C0}${BG2} ${C0}${W4}█${W1}▒${W4}█${W1}▒${W2}▒▒${W4}█${W1}▒${W4}█${W1}▒${C0}${BG2} ${C0}${G3}█${G2}█░▓${G3}░${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G2}███${G3}█${G4}█${G2}▒${G3}▒${C0}${BG2} ${C0}${G3}█${G2}██${G3}██${G4}██${G5}█${G3}▒${C0}${BG2}   ${BG1}             ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}      ${C0}${G2}▒${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}███${G4}███${G3}▒${C0}${BG2} ${C0}${G3}██${G3}▒${C0}${BG2} ${C0}${G4}██${G5}█${G3}▒${C0}${BG2} ${C0}${G3}█${G2}█▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${W4}█${W3}█${W4}█${W1}▒${C0}${BG2}  ${C0}${W4}█${W3}█${W4}█${W1}▒${C0}${BG2} ${C0}${G3}█${G2}█▓${G3}░${G4}░█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█${G1}▒${BG2} ${C0}${G3}█${G4}██${G3}▒${C0}${BG2} ${C0}${G3}█${G2}█▒${G3}█${G4}█${G2}▒${G5}█${G4}█${G3}▒${C0}${BG2}   ${BG1}             ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G2}█${G2}█${G4}██${G5}███${G3}▒${C0}${BG2} ${C0}${G4}█${G1}█▒${C0}${BG2}  ${C0}${G5}█${G4}▓${G3}▒${C0}${BG2} ${C0}${G3}█${G2}█${G3}▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G3}██${G4}██${G5}██${G3}▒${C0}${BG2}   ${C0}${W4}█${W1}▒${C0}${BG2}    ${C0}${W4}█${W1}▒${C0}${BG2}   ${C0}${G3}█${G4}███${G5}█${G3}▒${C0}${BG2}  ${C0}${G3}█${G4}█${G3}▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█${G2}▒${C0}${BG2}   ${C0}${G4}█${G5}█${G3}▒${C0}${BG2}   ${C0}${Y1}██░${C0}${BG1}          ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G2}█${G4}░${C0}${BG2}                                                      ${C0}${G4}█▒${C0}${BG2}              ${C0}${G4}█${G3}▒${C0}${BG2}   ${C0}${Y2}█${Y1}████░${C0}${BG1}   ${C0}▒${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G3}█░${C0}${BG2}                                                                      ${C0}${G3}█${G3}▒${C0}${BG2}   ${C0}${Y2}████${Y1}███░${C0}${BG1}     ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G4}█░${C0}${BG2}                             ${G4}* THE 3D PRINTING *                      ${C0}${G2}█${G3}▒${C0}${BG2}   ${C0}${Y3}█${Y2}████${Y1}███░${C0}${BG1}    ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G4}█▒${C0}${BG2}                                                           ${C0}${G5}▓${G3}▒${C0}${BG2}              ${C0}${Y3}██${Y2}████${Y1}███░${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${G5}█▒${C0}${BG2}                         ${C0}${G1}█${G2}██${G3}██${G4}█${G5}█${G3}▒${C0}${BG2}  ${C0}${G4}█${G3}██${G5}██${G3}▒${C0}${BG2}  ${C0}${G2}█${G3}█▒${C0}${BG2}   ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}▓${G3}███${G5}███${G3}▒${C0}${BG2}              ${C0}${Y3}███${Y2}████${Y1}███${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}                             ${C0}${G1}█${G2}█${G1}▒${G5}${C0}${BG2}      ${C0}${G3}█${G1}█▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G1}█${G2}██▒${C0}${BG2}${BG2} ${C0}${G5}██${G4}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█${G1}▒${G5}${C0}${BG2}                   ${C0}${Y3}███${Y2}████${Y1}███${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}                             ${C0}${G2}██▒${C0}${BG2} ${C0}${G5}█${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G3}█${G2}█▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█${G2}██${G5}██${G4}██${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█${G4}█${G5}██${G3}▒${C0}${BG2}               ${C0}${Y3}▒███${Y2}████${Y1}███${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}        ${C0}${Y3}▒████████▒${C0}${BG2}           ${C0}${G2}█${G3}█${G2}▒${C0}${BG2}  ${C0}${G4}█${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}███${G4}███${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█${G2}▒█${G4}█${G1}▒${G3}█${G3}█${G3}▒${C0}${BG2} ${C0}${G3}█${G2}█${G1}▒${G5}${C0}${BG2}                 ${C0}${Y3}▒███${Y2}█████${Y1}███${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}      ${C0}${Y2}▒████████${Y3}██████▒${C0}${BG2}       ${C0}${G2}█${G3}███${G4}██${G5}█${G3}▒${C0}${BG2} ${C0}${G2}█${G3}█▒${C0}${BG2}  ${C0}${G4}█${G3}█${G3}▒${C0}${BG2} ${C0}${G3}█${G2}█▒${C0}${BG2}   ${C0}${G3}█${G4}█${G3}▒${C0}${BG2} ${C0}${G3}█${G2}██${G3}██${G4}█${G5}█${G3}▒${C0}${BG2}           ${C0}${Y3}▒███${Y2}█████${Y1}████${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}    ${C0}${Y2}▒█████████████${Y3}██████▒${C0}${BG2}          ${C0}${G3}█${G3}▒${C0}${BG2}                                     ${C0}${Y3}▒████${Y2}█████${Y1}█████${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${Y2}▒███${Y1}███▒${C0}${BG2}    ${C0}${Y2}░██████${Y3}██████▒${C0}${BG2}                                            ${C0}${Y3}▒████${Y2}██████${Y1}█████░${C0}${BG1}   ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}   ${BG2}  ${C0}${Y3}█${Y2}██${Y1}██▒${C0}${BG2}         ${C0}${Y2}▒███████${Y3}█████▒${C0}${BG2}                                  ${C0}${Y3}▒█████████${Y2}██████${Y1}██████░${C0}${BG1}    ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}     ${C0}${Y3}█${Y2}██${Y1}█${C0}${BG1}             ${C0}${Y1}░███${Y2}██████${Y3}████████▒${C0}${BG1}                   ${C0}${Y3}▒███████████${Y2}█████████${Y1}███████░${C0}${BG1}      ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}  ${C0}▒${BG1}  ${C0}${Y3}█${Y2}██░${C0}${BG1}               ${C0}${Y1}░█████${Y2}████████${Y3}███████████${Y4}█████${Y3}█████████${Y2}███████████████${Y1}████████░${C0}${BG1}        ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}     ${C0}${Y3}█${Y2}██░${C0}${BG1}                  ${C0}${Y1}░████████${Y2}██████████${Y4}████${Y2}███${Y4}████${Y2}████████████████${Y1}███████████░${C0}${BG1}  ${C0}▒${BG1}       ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}     ${C0}${Y3}░${Y2}██░${C0}${BG1}                     ${C0}${Y1}░█████████${Y2}█████████${Y4}█████${Y2}██████████${Y1}████████████████░${C0}${BG1}              ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}      ${C0}${Y3}░█${Y2}█${C0}${BG1}                          ${C0}${Y1}░███████████${Y2}█████████${Y1}█████████████████░${C0}${BG1}                     ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}       ${C0}${Y3}░█${C0}${BG1}  ${C0}▒${BG1} LAUNCHING THE GAME...     ${C0}${Y1}░██████████████████████░${C0}${BG1}                                ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█${C0}${BG1}                                                               ${C0}${F3}███████████████████████████${F4}█${C0}${BG1}    ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "${F3}█████████████████████████████████████████████████████████████████${C0}${BG1} Loading:                 ${C0}${F3}█████${F1}█${C0}"
sleep $SPEED_MEDIUM
echo -e "                                                                ${F3}█${C0}${BG1} 0%                  100% ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "                                                                ${F3}█${C0}${BG1} □□□□□□□□□□□□□□□□□□□□□□□□ ${C0}${F3}█${C0}"
sleep $SPEED_MEDIUM
echo -e "                                                                ${F3}${F1}█${F3}██████████████████████████${F1}█${C0}"
sleep $SPEED_SLOW
simulate_loading_bar_with_ascii

sleep $SPEED_SLOW
}
