require "./cashrun/*"

module Cashrun
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
end

macro vputs(string)
  if config.verbose
    STDERR.puts {{string}}
  end
end

config, script_name, remaining_args = Cashrun::CLI.parse
config.parse_file!
vputs "Config: #{config}"
vputs "Running #{script_name}"

unless File.exists?(script_name)
  STDERR.puts "Origin script does not exist."
  exit 1
end

hexdigest = config.digest.class.hexdigest(File.read(script_name))
vputs "Hex Digest: #{hexdigest}"

cached_name = File.expand_path(File.join(config.cache_directory, hexdigest))
vputs "Cached Name: #{cached_name}"

unless Dir.exists?(File.expand_path(config.cache_directory))
  vputs "Cache Directory does not exist."
  Dir.mkdir_p(File.expand_path(config.cache_directory))
end

unless File.exists?(cached_name)
  vputs "Cached executable does not exist."

  real_script_location = File.real_path(File.expand_path(script_name))

  args = [
    "build",
    script_name,
    "-o", cached_name,
    "--no-debug",
  ]

  if config.release
    args << "--release"
  end

  vputs "running `crystal #{args.join(" ")}` after chdir: `#{real_script_location}`"
  Process.run(command: "crystal", args: args, chdir: real_script_location)
end

vputs "running `#{cached_name} #{remaining_args.join(" ")}`"
Process.exec(command: cached_name, args: remaining_args)
