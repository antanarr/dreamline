#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Dreamline.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Dreamline' }

# Files to add
new_files = [
  'Sources/Features/Today/TransitDiagramView.swift',
  'Sources/Features/Today/AccuracyFeedbackView.swift',
  'Sources/Features/Today/BestDaysView.swift',
  'Sources/Features/Today/BehindThisForecastView.swift',
  'Sources/Features/Today/LifeAreaDetailView.swift',
  'Sources/Features/Today/SeasonalContentView.swift',
  'Sources/Features/Today/YourDayHeroCard.swift',
  'Sources/Features/Today/LifeAreaRow.swift',
  'Sources/Shared/Models/ZodiacSign.swift',
  'Sources/Shared/Models/DreamPattern.swift',
  'Sources/Shared/Models/BestDayInfo.swift',
  'Sources/Services/DreamPatternService.swift',
  'Sources/Services/PaywallService.swift'
]

new_files.each do |file_path|
  # Check if file already exists in project
  existing = target.source_build_phase.files.find { |f| f.file_ref&.path&.end_with?(File.basename(file_path)) }
  next if existing
  
  # Add file to project
  file_ref = project.main_group.find_file_by_path(file_path) || project.main_group.new_reference(file_path)
  target.add_file_references([file_ref])
  puts "Added: #{file_path}"
end

project.save
puts "Done!"
