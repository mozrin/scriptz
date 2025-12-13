#!/bin/bash
# tv_series_template.sh
# Script to create a TV series pitch document structure

set -euo pipefail

# Defaults
EPISODES=8
SEASONS=1
SHOW=""
INCLUDE_PILOT=true
INCLUDE_TRAILER=true

show_help() {
  cat <<EOF
tv_series_template - Create a TV series pitch document structure

DESCRIPTION
  Creates a complete folder structure with markdown files for developing
  a TV series pitch. Includes sections for characters, world-building,
  episode guides, production considerations, and more.

USAGE
  tv_series_template --show=NAME [options]

ARGUMENTS
  --show=NAME       Required. Name of the TV series (spaces become underscores)

OPTIONS
  --episodes=N      Episodes per season (default: 8)
  --seasons=N       Number of seasons to create (default: 1)
  --no-pilot        Skip creating pilot_episode.md
  --no-trailer      Skip creating trailer.md
  --help            Show this help message and exit

CREATED STRUCTURE
  01_Cover_Page/          - Title and creator info
  02_Executive_Summary/   - One-paragraph overview
  03_Series_Overview/     - Genre, format, audience
  04_Themes_Core_Concepts/- Central themes
  05_Characters/          - Main and supporting characters
  06_World_Building/      - Settings and visual identity
  07_Season_Structure/    - Season arc and episode count
  08_Episode_Guide/       - Episode cards and synopses
  09_Production_Considerations/ - Budget, casting, effects
  10_Market_Positioning/  - Audience and distribution
  11_Closing_Section/     - Vision statement and call to action

EXAMPLES
  tv_series_template --show="Breaking Bad"
  tv_series_template --show="The Office" --episodes=22 --seasons=9
  tv_series_template --show="My Show" --no-pilot --no-trailer

EOF
  exit 0
}


# Blurb function
get_blurb() {
  declare -A blurbs
  blurbs["cover_page.md"]="Title, tagline, and creator information for the show."
  blurbs["executive_summary.md"]="One-paragraph overview and why the show matters now."
  blurbs["series_overview.md"]="Genre, format, audience, tone, and comparable titles."
  blurbs["themes_core_concepts.md"]="Central themes and narrative engine of the series."
  blurbs["main_characters.md"]="Profiles of the lead characters and their arcs."
  blurbs["supporting_characters.md"]="Descriptions of secondary characters and their roles."
  blurbs["antagonists.md"]="Outline of obstacles or antagonist forces in the story."
  blurbs["settings.md"]="Primary locations and environments where the story unfolds."
  blurbs["time_period.md"]="Historical or contemporary context for the series."
  blurbs["visual_identity.md"]="Notes on cinematography, palette, and design motifs."
  blurbs["season_arc.md"]="High-level arc of the season from beginning to end."
  blurbs["episode_count.md"]="Number of episodes and their length."
  blurbs["key_turning_points.md"]="Major narrative beats or turning points in the season."
  blurbs["episode_cards.md"]="Brief synopses of each episode."
  blurbs["pilot_episode.md"]="Expanded synopsis or beat sheet for the pilot episode."
  blurbs["trailer.md"]="Concept notes for promotional trailer or teaser."
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

# Parse arguments
for arg in "$@"; do
  case $arg in
    --episodes=*)
      EPISODES="${arg#*=}"
      ;;
    --seasons=*)
      SEASONS="${arg#*=}"
      ;;
    --show=*)
      SHOW="${arg#*=}"
      SHOW="${SHOW// /_}"  # replace spaces with underscores
      ;;
    --no-pilot)
      INCLUDE_PILOT=false
      ;;
    --no-trailer)
      INCLUDE_TRAILER=false
      ;;
    --help)
      show_help
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage."
      exit 1
      ;;
  esac
done

# Require SHOW
if [ -z "$SHOW" ]; then
  echo "Error: --show is required."
  exit 1
fi

# Validate EPISODES
if ! [[ "$EPISODES" =~ ^[0-9]+$ ]]; then
  echo "Error: --episodes must be an integer."
  exit 1
fi
if [ "$EPISODES" -le 0 ]; then
  echo "Error: --episodes must be greater than 0."
  exit 1
fi

# Validate SEASONS
if ! [[ "$SEASONS" =~ ^[0-9]+$ ]]; then
  echo "Error: --seasons must be an integer."
  exit 1
fi
if [ "$SEASONS" -le 0 ]; then
  echo "Error: --seasons must be greater than 0."
  exit 1
fi

# Root folder
mkdir -p "$SHOW"
cd "$SHOW" || exit

# Create folders and files
mkdir -p 01_Cover_Page && touch 01_Cover_Page/cover_page.md
mkdir -p 02_Executive_Summary && touch 02_Executive_Summary/executive_summary.md
mkdir -p 03_Series_Overview && touch 03_Series_Overview/series_overview.md
mkdir -p 04_Themes_Core_Concepts && touch 04_Themes_Core_Concepts/themes_core_concepts.md
mkdir -p 05_Characters && touch 05_Characters/main_characters.md 05_Characters/supporting_characters.md 05_Characters/antagonists.md
mkdir -p 06_World_Building && touch 06_World_Building/settings.md 06_World_Building/time_period.md 06_World_Building/visual_identity.md
mkdir -p 07_Season_Structure && touch 07_Season_Structure/season_arc.md 07_Season_Structure/episode_count.md 07_Season_Structure/key_turning_points.md
mkdir -p 08_Episode_Guide && touch 08_Episode_Guide/episode_cards.md
[ "$INCLUDE_PILOT" = true ] && touch 08_Episode_Guide/pilot_episode.md
[ "$INCLUDE_TRAILER" = true ] && touch 08_Episode_Guide/trailer.md
for s in $(seq 1 "$SEASONS"); do
  mkdir -p "08_Episode_Guide/Season_${s}"
  for e in $(seq 1 "$EPISODES"); do
    touch "08_Episode_Guide/Season_${s}/episode_${e}.md"
  done
done
mkdir -p 09_Production_Considerations && touch 09_Production_Considerations/budget.md 09_Production_Considerations/casting.md 09_Production_Considerations/filming_style.md 09_Production_Considerations/special_effects.md
mkdir -p 10_Market_Positioning && touch 10_Market_Positioning/audience_appeal.md 10_Market_Positioning/distribution.md 10_Market_Positioning/franchise_potential.md
mkdir -p 11_Closing_Section && touch 11_Closing_Section/vision_statement.md 11_Closing_Section/call_to_action.md

# Populate blurbs
for file in $(find . -type f -name "*.md"); do
  blurb=$(get_blurb "$(basename "$file")")
  echo "$blurb" > "$file"
done

# Create README.md
cat <<EOF > README.md
# Show Pitch Document

## Project Info
- Show Name: $SHOW
- Seasons: $SEASONS
- Episodes per Season: $EPISODES
- Generated On: $(date)

## Structure
Outline of folders and files created (top-level only):
$(find . -maxdepth 2 -type f | sed 's|^\./||')

## How to Use
- Fill each .md file with details according to its blurb.
- Use Git for version control.
- Update metadata.md with creator info and notes.
EOF

# Create metadata.md
cat <<EOF > metadata.md
# Metadata

- Show Name: $SHOW
- Seasons: $SEASONS
- Episodes per Season: $EPISODES
- Generated On: $(date)
- Script Version: 1.0
EOF

# Create .gitignore
cat <<EOF > .gitignore
# OS junk
.DS_Store
Thumbs.db

# Editor swap files
*.swp
*.swo
*~

# Logs
*.log

# Node / Python / build caches
node_modules/
__pycache__/
dist/
build/

# Misc
.env
EOF

# Concise tree output
echo "Project structure (top-level and one level down):"
find . -maxdepth 2 -type d -print | sed 's|^\./||'

echo "TV series pitch template created successfully."

