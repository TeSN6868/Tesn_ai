#!/data/data/com.termux/files/usr/bin/bash

# BINARY MATRIX RAIN
clear
printf '\033[?25l'

trap 'printf "\033[?25h\033[0m\033[2J\033[H"; exit' INT

while true
do
    COLS=$(tput cols)
    ROWS=$(tput lines)

    # Bersihkan layar
    printf '\033[2J\033[H'

    # Buat hujan binary
    for ((y=1; y<=ROWS; y++))
    do
        for ((x=1; x<=COLS; x++))
        do
            if (( RANDOM % 5 == 0 )); then
                printf '\033[32m1'
            else
                printf '\033[32m0'
            fi
        done
        printf '\n'
    done

    sleep 0.08
done
