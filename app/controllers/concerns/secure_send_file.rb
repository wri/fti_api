module SecureSendFile
  private

  def secure_send_file(allowed_directory, filename, options = {})
    allowed_path = File.expand_path(allowed_directory)
    full_path = File.expand_path(File.join(allowed_directory, filename))

    unless full_path.start_with?(allowed_path + File::SEPARATOR) || full_path == allowed_path
      raise_not_found_exception
    end

    send_file full_path, options
  end
end
