#!/usr/bin/env bash

reset_color='\033[0m'

function print_blue() {
  echo -e "⌛️ \033[34m${1}${reset_color}"
}

function print_cyan() {
  echo -e "🎉 \033[36m${1}${reset_color}"
}

function print_green() {
  echo -e "✅ \033[32m${1}${reset_color}"
}

function print_magenta() {
  echo -e "🤨 \033[35m${1}${reset_color}"
}

function print_red() {
  echo -e "🚨 \033[31m${1}${reset_color}"
}

function print_yellow() {
  echo -e "📣 \033[33m${1}${reset_color}"
}

function exit_gracefully() {
  print_red "** Exit"
  exit
}
