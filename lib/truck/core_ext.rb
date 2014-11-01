class Module
  def const_missing(const)
    offending_file = caller[0]
    $stderr.puts "Module#const_missing: const=#{const.inspect}, self=#{inspect}, file=#{offending_file}" if Truck.debug_mode
    catch :const do
      Truck::Autoloader.handle const, self, offending_file
    end
  rescue NameError => name_error
    if name_error.class == NameError
      # Reraise the error to keep our junk out of the backtrace
      raise NameError, name_error.message
    else
      # NoMethodError inherits from NameError
      raise name_error
    end
  end
end
