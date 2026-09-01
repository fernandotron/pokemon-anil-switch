# El módulo SaveData se utiliza para manipular los datos de guardado. Contiene 
# los {Value}s que conforman los datos de guardado y {Conversion}s para resolver
# incompatibilidades entre Essentials y las versiones del juego.
# @see SaveData.register
# @see SaveData.register_conversion
module SaveData
  FILE_PATH = "./Game.rxdata"

  # @return [Boolean] si el archivo de guardado existe
  def self.exists?
    return File.file?(FILE_PATH)
  end

  # Escribe de forma atómica y segura los datos a disco (.tmp -> .bak -> archivo final)
  # para prevenir corrupción de datos en caso de corte de energía o crash en Nintendo Switch.
  def self.dump_to_file(file_path, data)
    validate file_path => String
    tmp_path = file_path + ".tmp"
    bak_path = file_path + ".bak"
    File.open(tmp_path, "wb") { |file| Marshal.dump(data, file) }
    if File.size(tmp_path) > 0
      if File.exist?(file_path)
        (File.delete(bak_path) rescue nil) if File.exist?(bak_path)
        (File.rename(file_path, bak_path) rescue nil)
      end
      File.rename(tmp_path, file_path)
      $SWITCH_FILE_EXIST_CACHE&.delete(file_path)
      $SWITCH_FILE_EXIST_CACHE&.delete(tmp_path)
      $SWITCH_FILE_EXIST_CACHE&.delete(bak_path)
    else
      (File.delete(tmp_path) rescue nil) if File.exist?(tmp_path)
      raise IOError, "Error al guardar: archivo generado con 0 bytes"
    end
  end

  # Obtiene los datos de guardado del archivo proporcionado.
  # Devuelve un Array en el caso de un archivo de guardado anterior a la 
  # versión 19. Cuenta con fallback automático al archivo de respaldo (.bak).
  # @param file_path [String] ruta del archivo desde el que cargar
  # @return [Hash, Array] datos de guardado cargados
  # @raise [IOError, SystemCallError] si falla la apertura del archivo
  def self.get_data_from_file(file_path)
    validate file_path => String
    save_data = nil
    begin
      File.open(file_path) do |file|
        data = Marshal.load(file)
        if data.is_a?(Hash)
          save_data = data
          next
        end
        save_data = [data]
        save_data << Marshal.load(file) until file.eof?
      end
    rescue Exception => e
      bak_path = file_path + ".bak"
      if File.file?(bak_path)
        log_compat("[SaveData] Archivo #{file_path} corrupto (#{e.message}). Recuperando desde backup #{bak_path}...") rescue nil
        File.open(bak_path) do |file|
          data = Marshal.load(file)
          if data.is_a?(Hash)
            save_data = data
            next
          end
          save_data = [data]
          save_data << Marshal.load(file) until file.eof?
        end
      else
        raise e
      end
    end
    return save_data
  end

  # Obtiene los datos de guardado del archivo proporcionado. Si necesita 
  # conversión, lo vuelve a guardar.
  # @param file_path [String] ruta del archivo desde el que leer
  # @return [Hash] datos de guardado en formato Hash
  # @raise (ver .get_data_from_file)
  def self.read_from_file(file_path)
    validate file_path => String
    save_data = get_data_from_file(file_path)
    save_data = to_hash_format(save_data) if save_data.is_a?(Array)
    if !save_data.empty? && run_conversions(save_data)
      self.dump_to_file(file_path, save_data)
    end
    return save_data
  end

  # Compila los datos de guardado y guarda una versión marshaled de ellos en
  # el archivo proporcionado mediante escritura atómica.
  # @param file_path [String] ruta del archivo donde guardar
  # @raise [InvalidValueError] si se está guardando un valor no válido
  def self.save_to_file(file_path)
    validate file_path => String
    save_data = self.compile_save_hash
    self.dump_to_file(file_path, save_data)
  end

  # Elimina el archivo de guardado (y un posible archivo de respaldo .bak 
  # si existe)
  # @raise [Error::ENOENT]
  def self.delete_file
    File.delete(FILE_PATH) if File.exist?(FILE_PATH)
    File.delete(FILE_PATH + ".bak") if File.file?(FILE_PATH + ".bak")
    $SWITCH_FILE_EXIST_CACHE&.delete(FILE_PATH)
    $SWITCH_FILE_EXIST_CACHE&.delete(FILE_PATH + ".bak")
  end

  # Convierte los datos de formato anterior a la versión 19 al nuevo formato.
  # @param old_format [Array] datos de guardado en formato anterior a la 
  # versión 19
  # @return [Hash] datos de guardado en el nuevo formato
  def self.to_hash_format(old_format)
    validate old_format => Array
    hash = {}
    @values.each do |value|
      data = value.get_from_old_format(old_format)
      hash[value.id] = data unless data.nil?
    end
    return hash
  end
end