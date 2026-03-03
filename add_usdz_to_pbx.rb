require 'xcodeproj'

project_path = '3dstudio.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

['stu1.usdz', 'stu2.usdz', 'stu3.usdz'].each do |file_name|
  file_path = "3dstudio/#{file_name}"
  
  # Find or create a group for these files
  group = project.main_group.find_subpath('3dstudio', true)
  
  # Check if the file reference already exists
  file_ref = group.files.find { |f| f.path == file_name }
  unless file_ref
    file_ref = group.new_file(file_name)
    puts "Added file reference for #{file_name}"
  end

  # Add to Target's Resource Build Phase
  resources_phase = target.resources_build_phase
  unless resources_phase.files_references.include?(file_ref)
    resources_phase.add_file_reference(file_ref)
    puts "Added #{file_name} to resources build phase"
  end
end

project.save
puts "Project saved successfully."
