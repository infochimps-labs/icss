# -*- ruby -*-

# def run_spec(pattern, subdir = '')
#   subdir << '/' unless subdir == '' || subdir =~ %r{./$}
#   if !(files = Dir["spec/#{subdir}**/*#{pattern}*_spec.rb"]).empty?
#     rspec(files)
#   end
# end

def run_with_ruby(file)
  unless File.exist?(file) then puts "#{file} does not exist" ; return ; end
  puts   "Running #{file}"
  system "ruby", file
  puts
end

def run_spec(file)
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts   "Running #{file}"
  # system "bundle exec rspec #{file}"
  system "rspec #{file}"
  puts
end

watch("spec/.*/.*_spec\.rb") do |match|
  run_spec match[0]
end

watch("spec/.*_spec\.rb") do |match|
  run_spec match[0]
end

watch("lib/icss/(.*/)?(.*)\.rb") do |match|
  if match.string =~ /zaml/
    run_with_ruby %{spec/#{match[1]}#{match[2]}_test.rb}
    run_spec      %{spec/#{match[1]}#{match[2]}_spec.rb}
  else
    run_spec      %{spec/#{match[1]}#{match[2]}_spec.rb}
  end
end

watch("spec/.*_test\.rb") do |match|
  run_with_ruby match[0]
end
