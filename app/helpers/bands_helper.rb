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

  class Datereview
    def initialize(date_review = "")
      @@date_review = date_review
    end
    def self.date_review
      @@date_review
    end
    def self.date_review=(new_name_file)
      @@date_review = new_name_file
    end
  end

end
