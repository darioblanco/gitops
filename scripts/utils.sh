#!/usr/bin/env bash

reset_color='\033[0m'

function print_blue() {
  printf "⌛️ \033[34m%s%s\n" "$1" "$reset_color"
}

function print_cyan() {
  printf "🎉 \033[36m%s%s\n" "$1" "$reset_color"
}

function print_green() {
  printf "✅ \033[32m%s%s\n" "$1" "$reset_color"
}

function print_magenta() {
  printf "🤨 \033[35m%s%s\n" "$1" "$reset_color"
}

function print_red() {
  printf "🚨 \033[31m%s%s\n" "$1" "$reset_color"
}

function print_yellow() {
  printf "📣 \033[33m%s%s\n" "$1" "$reset_color"
}

function exit_gracefully() {
  print_red "** Exit"
  exit
}
