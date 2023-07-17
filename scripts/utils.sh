#!/usr/bin/env bash

reset_color=$(tput sgr 0)

function print_blue() {
  printf "⌛️ %s%s%s\n" "$(tput setaf 4)" "$1" "$reset_color"
}

function print_cyan() {
  printf "🎉 %s%s%s\n" "$(tput setaf 6)" "$1" "$reset_color"
}

function print_green() {
  printf "✅ %s%s%s\n" "$(tput setaf 2)" "$1" "$reset_color"
}

function print_magenta() {
  printf "🤨 %s%s%s\n" "$(tput setaf 5)" "$1" "$reset_color"
}

function print_red() {
  printf "🚨 %s%s%s\n" "$(tput setaf 1)" "$1" "$reset_color"
}

function print_yellow() {
  printf "📣 %s%s%s\n" "$(tput setaf 3)" "$1" "$reset_color"
}

function exit_gracefully() {
  print_red "** Exit"
  exit
}
