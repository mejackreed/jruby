# Copyright (c) 2014, 2016 Oracle and/or its affiliates. All rights reserved. This
# code is released under a tri EPL/GPL/LGPL license. You can use it,
# redistribute it and/or modify it under the terms of the:
#
# Eclipse Public License version 1.0
# GNU General Public License version 2
# GNU Lesser General Public License version 2.1

# These are implemented just to get other stuff working - we'll go back and
# implement these properly later.

# Windows probably doesn't have a HOME env var, but Rubinius requires it in places, so we need
# to construct the value and place it in the hash.
#unless ENV['HOME']
#  if ENV['HOMEDRIVE']
#    ENV['HOME'] = if ENV['HOMEPATH']
#                    ENV['HOMEDRIVE'] + ENV['HOMEPATH']
#                  else
#                    ENV['USERPROFILE']
#                  end
#  end
#end

class Exception

  def to_s
    if message.nil?
      self.class.to_s
    else
      message.to_s
    end
  end

end

# Hack to let code run that try to invoke RubyGems directly.  We don't yet support RubyGems, but in most cases where
# this call would be made, we've already set up the $LOAD_PATH so the call would no-op anyway.
module Kernel
  def gem(*args)
  end
end

# Find out why Rubinius doesn't implement this
class Rubinius::ARGFClass
end

module Enumerable

  alias_method :min_internal, :min
  alias_method :max_internal, :max

end

# JRuby uses this for example to make proxy settings visible to stdlib/uri/common.rb

ENV_JAVA = {}

# The translator adds a call to Truffle.get_data to set up the DATA constant

module Truffle
  def self.get_data(path, offset)
    file = File.open(path)
    file.seek(offset)

    # I think if the file can't be locked then we just silently ignore
    file.flock(File::LOCK_EX | File::LOCK_NB)

    Truffle::Kernel.at_exit true do
      file.flock(File::LOCK_UN)
    end

    file
  end
end

module Truffle
  def self.load_arguments_from_array_kw_helper(array, kwrest_name, binding)
    array = array.dup

    last_arg = array.pop

    if last_arg.respond_to?(:to_hash)
      kwargs = last_arg.to_hash

      if kwargs.nil?
        array.push last_arg
        return array
      end

      raise TypeError.new("can't convert #{last_arg.class} to Hash (#{last_arg.class}#to_hash gives #{kwargs.class})") unless kwargs.is_a?(Hash)

      return array + [kwargs] unless kwargs.keys.any? { |k| k.is_a? Symbol }

      kwargs.select! do |key, value|
        symbol = key.is_a? Symbol
        array.push({key => value}) unless symbol
        symbol
      end
    else
      kwargs = {}
    end

    binding.local_variable_set(kwrest_name, kwargs) if kwrest_name
    array
  end

  def self.add_rejected_kwargs_to_rest(rest, kwargs)
    return if kwargs.nil?

    rejected = kwargs.select { |key, value|
      not key.is_a?(Symbol)
    }

    unless rejected.empty?
      rest.push rejected
    end
  end
end

def when_splat(cases, expression)
  cases.any? do |c|
    c === expression
  end
end
