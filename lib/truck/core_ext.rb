class Module
  def const_missing(const)
    catch :const do
      Truck::Autoloader.handle const, from: self
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
