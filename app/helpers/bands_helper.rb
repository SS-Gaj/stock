module BandsHelper
  class Tegiobrab
    def initialize(name_teg = "")
      @@name_teg = name_teg
    end
    def self.name_teg
      @@name_teg
    end
    def self.name_teg=(new_name_file)
      @@name_teg = new_name_file
    end
  end

end
