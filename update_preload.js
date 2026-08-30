const fs = require('fs');

let preload = fs.readFileSync('preload.rb', 'utf-8');

const saveDataStub = `
# 1.7 Stubs globales de SaveData y Manejo de Sistema
module SaveData
  @values ||= []
  @conversions ||= { essentials: {}, game: {} }
  FILE_PATH = "./Game.rxdata" unless const_defined?(:FILE_PATH)

  class << self
    def initialize_bootup_values
      (@values || []).each do |v|
        next unless v.respond_to?(:load_in_bootup?) && v.load_in_bootup?
        v.load_new_game_value if v.respond_to?(:has_new_game_proc?) && v.has_new_game_proc? && !v.loaded?
      end rescue nil
    end

    def load_bootup_values(save_data = {})
      nil
    end

    def load_new_game_values
      (@values || []).each do |v|
        v.load_new_game_value if v.respond_to?(:has_new_game_proc?) && v.has_new_game_proc?
      end rescue nil
    end

    def exists?
      File.file?(FILE_PATH) rescue false
    end

    def get_newest_save_slot
      nil
    end

    def read_from_file_safe(path, **opts)
      {}
    end

    def get_full_path(slot)
      "./Game.rxdata"
    end
  end
end
`;

if (!preload.includes('def initialize_bootup_values')) {
  preload += '\n' + saveDataStub + '\n';
  fs.writeFileSync('preload.rb', preload);
  console.log('Successfully added SaveData stubs to preload.rb!');
} else {
  console.log('SaveData stubs already in preload.rb');
}
