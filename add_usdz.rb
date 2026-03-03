require 'xcodeproj'
project_path = '3dstudio.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first
group = project.main_group.find_subpath('3dstudio', true)

# Check if already exists to avoid duplicates
existing_file_ref = group.files.find { |f| f.path == 'stu1.usdz' }
if existing_file_ref.nil?
    file_ref = group.new_reference('stu1.usdz')
    target.add_resources([file_ref])
    project.save
    puts "Added stu1.usdz to project resources."
else
    puts "stu1.usdz already in project."
end
