#!/data/data/com.termux/files/usr/bin/bash

# ==================================================
#        MATRIX PREMIUM - BINARY DIGITAL RAIN
#        WHITE HEAD -> BRIGHT GREEN -> DARK GREEN
# ==================================================

clear
printf '\033[?25l'
printf '\033[40m'

trap 'printf "\033[?25h\033[0m\033[2J\033[H"; exit' INT

COLS=$(tput cols)
ROWS=$(tput lines)

declare -a POS
declare -a SPEED
declare -a LENGTH

# Buat setiap kolom
for ((x=0; x<COLS; x++)); do
    POS[$x]=$((RANDOM % (ROWS + 20) - 20))
    SPEED[$x]=$((RANDOM % 3 + 1))
    LENGTH[$x]=$((RANDOM % 14 + 8))
done

while true; do

    # Jika ukuran Termux berubah
    NEWCOLS=$(tput cols)
    NEWROWS=$(tput lines)

    if [[ "$NEWCOLS" != "$COLS" || "$NEWROWS" != "$ROWS" ]]; then
        COLS=$NEWCOLS
        ROWS=$NEWROWS
        clear

        for ((x=0; x<COLS; x++)); do
            POS[$x]=$((RANDOM % (ROWS + 20) - 20))
            SPEED[$x]=$((RANDOM % 3 + 1))
            LENGTH[$x]=$((RANDOM % 14 + 8))
        done
    fi

    for ((x=0; x<COLS; x++)); do

        y=${POS[$x]}
        len=${LENGTH[$x]}

        # ==========================================
        # KEPALA - PUTIH TERANG
        # ==========================================
        if (( y >= 0 && y < ROWS )); then

            printf "\033[%d;%dH" "$((y+1))" "$((x+1))"
            printf "\033[1;97m"

            # Karakter kepala
            if (( RANDOM % 18 == 0 )); then
                printf "@"
            elif (( RANDOM % 2 == 0 )); then
                printf "1"
            else
                printf "0"
            fi
        fi

        # ==========================================
        # EKOR MATRIX
        # ==========================================
        for ((j=1; j<len; j++)); do

            yy=$((y-j))

            if (( yy < 0 || yy >= ROWS )); then
                continue
            fi

            printf "\033[%d;%dH" "$((yy+1))" "$((x+1))"

            # --------------------------------------
            # LEVEL 1 - HIJAU TERANG
            # --------------------------------------
            if (( j <= 3 )); then
                printf "\033[1;92m"

            # --------------------------------------
            # LEVEL 2 - HIJAU NORMAL
            # --------------------------------------
            elif (( j <= 7 )); then
                printf "\033[32m"

            # --------------------------------------
            # LEVEL 3 - HIJAU REDUP
            # --------------------------------------
            else
                printf "\033[2;32m"
            fi

            # Binary random
            if (( RANDOM % 2 == 0 )); then
                printf "0"
            else
                printf "1"
            fi
        done

        # ==========================================
        # HAPUS UJUNG EKOR
        # ==========================================
        old=$((y-len))

        if (( old >= 0 && old < ROWS )); then
            printf "\033[%d;%dH " "$((old+1))" "$((x+1))"
        fi

        # ==========================================
        # GERAKKAN HUJAN
        # ==========================================
        POS[$x]=$((y + SPEED[$x]))

        # ==========================================
        # RESET KOLOM
        # ==========================================
        if (( POS[$x] > ROWS + len )); then
            POS[$x]=$((RANDOM % 12 - 12))
            SPEED[$x]=$((RANDOM % 3 + 1))
            LENGTH[$x]=$((RANDOM % 14 + 8))
        fi

    done

    # Kecepatan animasi
    sleep 0.035
done
