#!/bin/bash
# idea_tv_series.sh
# Functions to scaffold a TV series pitch project.

create_tv_series_structure() {
  PROJECT="$1"
  OPTIONS=("${@:2}")

  EPISODES=8
  SEASONS=1
  INCLUDE_PILOT=true
  INCLUDE_TRAILER=true

  for opt in "${OPTIONS[@]}"; do
    case $opt in
      --episodes=*) EPISODES="${opt#*=}" ;;
      --seasons=*) SEASONS="${opt#*=}" ;;
      --no-pilot) INCLUDE_PILOT=false ;;
      --no-trailer) INCLUDE_TRAILER=false ;;
    esac
  done

  mkdir -p "$PROJECT"
  cd "$PROJECT" || exit

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
}

populate_tv_series_blurbs() {
  for file in $(find . -type f -name "*.md"); do
    blurb=$(get_blurb "$(basename "$file")")
    echo "$blurb" > "$file"
  done
}
