#
# default_gateway.rb
#
# This fact provides information about the default gateway (or the "route of
# last resort" if you wish) that is available on the system ...
#

require 'facter'

if Facter.value(:kernel) == 'Linux'
  # We store information about the default gateway here ...
  gateway = ''

  #
  # Modern Linux kernels provide "/proc/net/route" in the following format:
  #
  #  Iface      Destination     Gateway         Flags   RefCnt  Use     Metric  Mask            MTU     Window  IRTT
  #  eth0       0000FEA9        00000000        0001    0       0       1000    0000FFFF        0       0       0
  #  eth0       00006C0A        00000000        0001    0       0       1       0000FFFF        0       0       0
  #  eth0       00000000        460B6C0A        0003    0       0       0       00000000        0       0       0
  #

  #
  # We utilise rely on "cat" for reading values from entries under "/proc".
  # This is due to some problems with IO#read in Ruby and reading content of
  # the "proc" file system that was reported more than once in the past ...
  #
  Facter::Util::Resolution.exec('cat /proc/net/route 2> /dev/null').each_line do |line|
    # Remove bloat ...
    line.strip!

    # Skip header line ...
    next if line.match(/^[Ii]face.+/)

    # Skip new and empty lines ...
    next if line.match(/^(\r\n|\n|\s*)$|^$/)

    # Retrieve destination and gateway ...
    values = line.split("\t").slice(1, 2)

    # Convert values to a pair of bytes ...
    values.collect! { |i| i.to_a.pack('H*') }

    #
    # A value (actually, a sum if you wish) of zero will indicate that we have
    # the default gateway.  Anything else indicates known destination ...
    #
    unless values[0].unpack('C4').inject(:+) > 0
      # A default gateway there?  Convert back to Integer ...
      gateway = values[1].unpack('C4')
    else
      # Skip irrelevant entries ...
      next
    end
  end

  Facter.add('default_gateway') do
    confine :kernel => :linux
    # Reverse from network order ...
    setcode { gateway.reverse.join('.') }
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
