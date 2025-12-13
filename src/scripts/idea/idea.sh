#!/bin/bash
# idea.sh
# Script to scaffold creative or business projects by type and name.

set -euo pipefail

# Path to ancillary modules
MODULES_PATH="/home/mozrin/Code/scriptz/src/scripts/idea"

show_help() {
  cat <<EOF
idea - Scaffold creative and business projects

DESCRIPTION
  Creates a folder structure with placeholder markdown files for different
  project types. Each type has its own template with relevant sections.

USAGE
  idea <type> <project_name> [options]

ARGUMENTS
  <type>            Required. The project type (see TYPES below).
  <project_name>    Required. Name for the project folder.

TYPES
  tv_series         TV series pitch document with seasons/episodes structure
  class             Educational class or course structure
  (other)           Generic project with basic Content folder

OPTIONS
  --help            Show this help message and exit
  (Additional options depend on the project type)

TV_SERIES OPTIONS
  --episodes=N      Episodes per season (default: 8)
  --seasons=N       Number of seasons (default: 1)
  --no-pilot        Skip pilot episode template
  --no-trailer      Skip trailer template

EXAMPLES
  idea tv_series "Breaking Bad"
  idea tv_series "The Office" --episodes=22 --seasons=9
  idea class "Python 101"

EOF
  exit 0
}

parse_args() {
  if [ "${1:-}" = "--help" ] || [ -z "${1:-}" ]; then
    show_help
  fi
  TYPE="$1"
  PROJECT="${2:-}"
  shift 2 2>/dev/null || true
  OPTIONS=("$@")
}

validate_args() {
  if [ -z "$TYPE" ] || [ -z "$PROJECT" ]; then
    echo "Error: type and project_name are required."
    echo "Usage: idea <type> <project_name> [options]"
    echo "Try 'idea --help' for more information."
    exit 1
  fi
}


get_blurb() {
  declare -A blurbs
  blurbs["cover_page.md"]="Title, tagline, and creator information."
  blurbs["executive_summary.md"]="One-paragraph overview and why it matters now."
  blurbs["series_overview.md"]="Genre, format, audience, tone, and comparable titles."
  blurbs["themes_core_concepts.md"]="Central themes and narrative engine."
  blurbs["main_characters.md"]="Profiles of lead characters and arcs."
  blurbs["supporting_characters.md"]="Descriptions of secondary characters."
  blurbs["antagonists.md"]="Outline of obstacles or antagonist forces."
  blurbs["settings.md"]="Primary locations and environments."
  blurbs["time_period.md"]="Historical or contemporary context."
  blurbs["visual_identity.md"]="Notes on cinematography, palette, and design motifs."
  blurbs["season_arc.md"]="High-level arc of the season."
  blurbs["episode_count.md"]="Number of episodes and their length."
  blurbs["key_turning_points.md"]="Major narrative beats or turning points."
  blurbs["episode_cards.md"]="Brief synopses of each episode."
  blurbs["pilot_episode.md"]="Expanded synopsis or beat sheet for the pilot."
  blurbs["trailer.md"]="Concept notes for promotional trailer."
  blurbs["budget.md"]="Budget range and scale considerations."
  blurbs["casting.md"]="Casting approach and talent requirements."
  blurbs["filming_style.md"]="Filming style and production methodology."
  blurbs["special_effects.md"]="Special effects or practical production needs."
  blurbs["audience_appeal.md"]="Target audience and why they will watch."
  blurbs["distribution.md"]="Distribution strategy and potential platforms."
  blurbs["franchise_potential.md"]="Spin-off or franchise expansion opportunities."
  blurbs["vision_statement.md"]="Creator’s intent and long-term vision."
  blurbs["call_to_action.md"]="Funding, distribution, or partnership request."
  echo "${blurbs[$1]:-Placeholder: describe content for $1 here.}"
}

create_metadata() {
  cat <<EOF > README.md
# Project Document

## Info
- Type: $TYPE
- Name: $PROJECT
- Generated On: $(date)

## Structure
$(find . -maxdepth 2 -type f | sed 's|^\./||')
EOF

  cat <<EOF > metadata.md
# Metadata

- Type: $TYPE
- Name: $PROJECT
- Generated On: $(date)
- Script Version: 2.0
EOF
}

parse_args "$@"
validate_args

case "$TYPE" in
  tv_series)
    source "$MODULES_PATH/idea_tv_series.sh"
    create_tv_series_structure "$PROJECT" "${OPTIONS[@]}"
    populate_tv_series_blurbs
    ;;
  class)
    source "$MODULES_PATH/idea_class.sh"
    create_class_structure "$PROJECT"
    populate_class_blurbs
    ;;
  *)
    mkdir -p "$PROJECT/Content"
    echo "Placeholder: overview for $PROJECT" > "$PROJECT/Content/overview.md"
    ;;
esac

create_metadata
echo "Project scaffold created successfully."
