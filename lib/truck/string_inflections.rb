module Truck
  module StringInflections
    refine String do
      def to_camel_case
        str = "_#{self}"
        str.gsub!(%r{_[a-z]}) { |snake| snake.slice(1).upcase }
        str.gsub!('/', '::')
        str
      end

      def to_snake_case
        str = gsub '::', '/'
        # Convert FOOBar => FooBar
        str.gsub! %r{[[:upper:]]{2,}} do |uppercase|
          bit = uppercase[0]
          bit << uppercase[1...-1].downcase
          bit << uppercase[-1]
          bit
        end
        str.gsub! %r{[[:lower:]][[:upper:]]+[[:lower:]]} do |camel|
          bit = camel[0]
          bit << '_'
          bit << camel[1..-1].downcase
        end
        str.downcase!
        str
      end
    end
  end
end
