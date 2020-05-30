module OverlooksHelper
  class Obrab
    def initialize(file_obrab = "")
      @@file_obrab = file_obrab
    end
    def self.file_obrab
      @@file_obrab
    end
    def self.file_obrab=(new_name_file)
      @@file_obrab = new_name_file
    end
  end
end
