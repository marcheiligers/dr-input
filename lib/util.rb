module Input
  module Util
    extend self

    def parse_color(params, name, dr: 0, dg: 0, db: 0, da: 255)
      cp = params["#{name}_color".to_sym]
      if cp
        case cp
        when Array
          { r: cp[0] || dr, g: cp[1] || dg, b: cp[2] || db, a: cp[3] || da }
        when Hash
          { r: cp.r || dr, g: cp.g || dg, b: cp.b || db, a: cp.a || da }
        when Integer
          if cp > 0xFFFFFF
            { r: (cp & 0xFF000000) >> 24, g: (cp & 0xFF0000) >> 16, b: (cp & 0xFF00) >> 8, a: cp & 0xFF }
          else
            { r: (cp & 0xFF0000) >> 16, g: (cp & 0xFF00) >> 8, b: cp & 0xFF, a: da }
          end
        else
          raise ArgumentError, "Color #{name} should be an Integer, Array or Hash"
        end
      else
        {
          r: params["#{name}_r".to_sym] || dr,
          g: params["#{name}_g".to_sym] || dg,
          b: params["#{name}_b".to_sym] || db,
          a: params["#{name}_a".to_sym] || da,
        }
      end
    end

    def parse_color_nilable(params, name)
      return parse_color(params, name) if params["#{name}_color".to_sym] || params["#{name}_r".to_sym] || params["#{name}_g".to_sym] || params["#{name}_b".to_sym] || params["#{name}_a".to_sym]

      nil
    end
  end
end
