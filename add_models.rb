require 'xcodeproj'
project_path = '3dstudio.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == '3dstudio' }

# Get or create a group for the models
group = project.main_group.find_subpath(File.join('3dstudio', 'Resources'), true)
group.set_source_tree('<group>')

# Add the models to the group and the target's resources phase
resources_phase = target.resources_build_phase
['stu1.usdz', 'stu2.usdz', 'stu3.usdz'].each do |model_name|
  file_path = "../3DModel/#{model_name}"
  file_reference = group.new_reference(file_path)
  
  # Check if it's already in the build phase to avoid duplicates
  unless resources_phase.files_references.include?(file_reference)
    resources_phase.add_file_reference(file_reference)
  end
end

project.save
puts "Added 3D models to Xcode project"
