#!/usr/bin/env bash

############################################
# General library of color formats

load_gen_lib_color_formats() {
  # Define color output functions for better readability
  txt_d_red() { printf "\033[38;5;88m%s\033[0m\n" "$*"; }         # Dark Red
  txt_red() { printf "\033[38;5;1m%s\033[0m\n" "$*"; }            # Red
  txt_l_red() { printf "\033[38;5;9m%s\033[0m\n" "$*"; }          # Light Red

  txt_peach() { printf "\033[38;5;173m%s\033[0m\n" "$*"; }        # Peach
  txt_orange() { printf "\033[38;5;202m%s\033[0m\n" "$*"; }       # Orange
  txt_d_orange() { printf "\033[38;5;166m%s\033[0m\n" "$*"; }     # Dark Orange
  txt_l_orange() { printf "\033[38;5;208m%s\033[0m\n" "$*"; }     # Light Orange

  txt_brown() { printf "\033[38;5;94m%s\033[0m\n" "$*"; }         # Brown
  txt_yellow() { printf "\033[38;5;11m%s\033[0m\n" "$*"; }        # Yellow
  txt_l_yellow() { printf "\033[38;5;191m%s\033[0m\n" "$*"; }     # Light Yellow
  txt_d_yellow() { printf "\033[38;5;3m%s\033[0m\n" "$*"; }       # Dark Yellow
  txt_gold() { printf "\033[38;5;58m%s\033[0m\n" "$*"; }          # Gold
  txt_neon() { printf "\033[38;5;154m%s\033[0m\n" "$*"; }         # Neon

  txt_l_green() { printf "\033[38;5;10m%s\033[0m\n" "$*"; }       # Light Green
  txt_green() { printf "\033[38;5;34m%s\033[0m\n" "$*"; }         # Green
  txt_b_green() { printf "\033[38;5;46m%s\033[0m\n" "$*"; }       # Bright Green
  txt_d_green() { printf "\033[38;5;28m%s\033[0m\n" "$*"; }       # Dark Green
  txt_forrest() { printf "\033[38;5;22m%s\033[0m\n" "$*"; }       # Forrest

  txt_d_teal() { printf "\033[38;5;23m%s\033[0m\n" "$*"; }        # Dark Teal
  txt_teal() { printf "\033[38;5;30m%s\033[0m\n" "$*"; }          # Teal
  txt_l_teal() { printf "\033[38;5;43m%s\033[0m\n" "$*"; }        # Light Teal
  txt_aqua() { printf "\033[38;5;50m%s\033[0m\n" "$*"; }          # Aqua

  txt_cyan() { printf "\033[38;5;51m%s\033[0m\n" "$*"; }          # Cyan
  txt_b_blue() { printf "\033[38;5;45m%s\033[0m\n" "$*"; }        # Bright Blue
  txt_blue() { printf "\033[38;5;33m%s\033[0m\n" "$*"; }          # Blue
  txt_d_blue() { printf "\033[38;5;27m%s\033[0m\n" "$*"; }        # Dark Blue
  txt_l_blue() { printf "\033[38;5;12m%s\033[0m\n" "$*"; }        # Light Blue

  txt_l_purple() { printf "\033[38;5;105m%s\033[0m\n" "$*"; }     # Light Purple
  txt_d_purple() { printf "\033[38;5;57m%s\033[0m\n" "$*"; }      # Dark Purple
  txt_purple() { printf "\033[38;5;99m%s\033[0m\n" "$*"; }        # Purple
  txt_b_purple() { printf "\033[38;5;129m%s\033[0m\n" "$*"; }     # Bright Purple
  txt_lavender() { printf "\033[38;5;13m%s\033[0m\n" "$*"; }      # Lavender

  txt_hotpink() { printf "\033[38;5;165m%s\033[0m\n" "$*"; }      # Hot Pink
  txt_pink() { printf "\033[38;5;212m%s\033[0m\n" "$*"; }         # Pink
  txt_rose() { printf "\033[38;5;174m%s\033[0m\n" "$*"; }         # Rose

  txt_d_grey() { printf "\033[38;5;239m%s\033[0m\n" "$*"; }       # Dark Grey
  txt_grey() { printf "\033[38;5;243m%s\033[0m\n" "$*"; }         # Grey
  txt_l_grey() { printf "\033[38;5;248m%s\033[0m\n" "$*"; }       # Light Grey

  txt_white() { printf "\033[38;5;255m%s\033[0m\n" "$*"; }        # White

  txt_bold() { printf "\033[1m%s\033[0m\n" "$*"; }                # Bold
  txt_underline() { printf "\033[4m%s\033[0m\n" "$*"; }           # Underline
  txt_italics() { printf "\033[3m%s\033[0m\n" "$*"; }             # Italics
}


############################################
# Load the general library of color formats
load_gen_lib_color_formats


# Check if the script is being sourced or executed directly
# If executed directly then run output example of all
# color functions
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  (
    printf "Script %s run directly, displaying all text colors...\n\n" "$(txt_d_yellow "$(basename -- "$0")")"

    sample_text="This is a sample text."

    printf "Testing color functions:\n"
    txt_d_red "txt_d_red: $sample_text"
    txt_red "txt_red: $sample_text"
    txt_l_red "txt_l_red: $sample_text"

    txt_peach "txt_peach: $sample_text"
    txt_orange "txt_orange: $sample_text"
    txt_d_orange "txt_d_orange: $sample_text"
    txt_l_orange "txt_l_orange: $sample_text"

    txt_brown "txt_brown: $sample_text"
    txt_yellow "txt_yellow: $sample_text"
    txt_l_yellow "txt_l_yellow: $sample_text"
    txt_d_yellow "txt_d_yellow: $sample_text"
    txt_gold "txt_gold: $sample_text"
    txt_neon "txt_neon: $sample_text"

    txt_l_green "txt_l_green: $sample_text"
    txt_green "txt_green: $sample_text"
    txt_b_green "txt_b_green: $sample_text"
    txt_d_green "txt_d_green: $sample_text"
    txt_forrest "txt_forrest: $sample_text"

    txt_d_teal "txt_d_teal: $sample_text"
    txt_teal "txt_teal: $sample_text"
    txt_l_teal "txt_l_teal: $sample_text"
    txt_aqua "txt_aqua: $sample_text"

    txt_cyan "txt_cyan: $sample_text"
    txt_b_blue "txt_b_blue: $sample_text"
    txt_blue "txt_blue: $sample_text"
    txt_d_blue "txt_d_blue: $sample_text"
    txt_l_blue "txt_l_blue: $sample_text"

    txt_l_purple "txt_l_purple: $sample_text"
    txt_d_purple "txt_d_purple: $sample_text"
    txt_purple "txt_purple: $sample_text"
    txt_b_purple "txt_b_purple: $sample_text"
    txt_lavender "txt_lavender: $sample_text"

    txt_hotpink "txt_hotpink: $sample_text"
    txt_pink "txt_pink: $sample_text"
    txt_rose "txt_rose: $sample_text"

    txt_d_grey "txt_d_grey: $sample_text"
    txt_grey "txt_grey: $sample_text"
    txt_l_grey "txt_l_grey: $sample_text"

    txt_white "txt_white: $sample_text"

    txt_bold "txt_bold: $sample_text"
    txt_underline "txt_underline: $sample_text"
    txt_italics "txt_italics: $sample_text"
  )
fi
