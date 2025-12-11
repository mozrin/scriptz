#!/bin/bash
# idea_class.sh
# Functions to scaffold a 12-week class project with lecture + assignment + lab rhythm.

# ■ Create class structure
create_class_structure() {
  PROJECT="$1"
  mkdir -p "$PROJECT"
  cd "$PROJECT" || exit

  mkdir -p 01_PreEnrollment && touch 01_PreEnrollment/prerequisite_test.md 01_PreEnrollment/admissions.md

  mkdir -p 02_Orientation && touch 02_Orientation/introduction.md 02_Orientation/syllabus.md 02_Orientation/course_policies.md 02_Orientation/assignment_intro.md \
    02_Orientation/lab_system_check.md 02_Orientation/environment_setup.md 02_Orientation/lab_activity.md 02_Orientation/support_channels.md

  mkdir -p 03_Weekly_Modules
  for w in $(seq 2 11); do
    mkdir -p "03_Weekly_Modules/Week_${w}"
    touch "03_Weekly_Modules/Week_${w}/lecture.md" \
          "03_Weekly_Modules/Week_${w}/assignment.md" \
          "03_Weekly_Modules/Week_${w}/lab.md"
  done

  mkdir -p 04_Final_Week && touch 04_Final_Week/study_guides.md 04_Final_Week/exam_schedule.md 04_Final_Week/final_exam.md 04_Final_Week/feedback.md

  mkdir -p 05_Resources && touch 05_Resources/resources.md 05_Resources/tools_and_materials.md 05_Resources/student_support.md

  mkdir -p 06_Logistics && touch 06_Logistics/calendar.md 06_Logistics/location.md 06_Logistics/budget.md

  mkdir -p 07_Closing && touch 07_Closing/certification.md 07_Closing/vision_statement.md 07_Closing/call_to_action.md
}

# ■ Populate blurbs for class files
populate_class_blurbs() {
  declare -A blurbs
  blurbs["prerequisite_test.md"]="Entry assessment to ensure readiness."
  blurbs["admissions.md"]="Enrollment criteria and policies."
  blurbs["introduction.md"]="Welcome, overview, and instructor introduction."
  blurbs["syllabus.md"]="Outline of topics, grading, expectations."
  blurbs["course_policies.md"]="Attendance, participation, deadlines, integrity."
  blurbs["assignment_intro.md"]="Reflective assignment to set context."
  blurbs["lab_system_check.md"]="Checklist to ensure computers are ready."
  blurbs["environment_setup.md"]="Instructions for installing required tools."
  blurbs["lab_activity.md"]="Guided exercise to confirm setup works."
  blurbs["support_channels.md"]="How to get help (forums, office hours)."
  blurbs["lecture.md"]="Lecture notes and theory for the week."
  blurbs["assignment.md"]="Homework or project tied to lecture."
  blurbs["lab.md"]="Hands-on practice applying lecture concepts."
  blurbs["study_guides.md"]="Consolidated notes and review materials."
  blurbs["exam_schedule.md"]="Dates/times for final exams."
  blurbs["final_exam.md"]="Comprehensive test covering all material."
  blurbs["feedback.md"]="Student evaluations and reflections."
  blurbs["resources.md"]="Books, articles, multimedia references."
  blurbs["tools_and_materials.md"]="Software, equipment, supplies."
  blurbs["student_support.md"]="Office hours, mentoring, forums."
  blurbs["calendar.md"]="Full 12-week calendar view."
  blurbs["location.md"]="Classroom or online platform details."
  blurbs["budget.md"]="Costs for materials, instructor fees, hosting."
  blurbs["certification.md"]="Certificates, credits, recognition offered."
  blurbs["vision_statement.md"]="Long-term intent of the class."
  blurbs["call_to_action.md"]="Enrollment instructions, partnership requests."

  for file in $(find . -type f -name "*.md"); do
    blurb="${blurbs[$(basename "$file")]}"
    echo "${blurb:-Placeholder: describe content for $(basename "$file") here.}" > "$file"
  done
}
