# encoding: utf-8
class ImageUploader < CarrierWave::Uploader::Base
  #include CarrierWave::RMagick
  storage :grid_fs
  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  def cache_dir
    "#{Sinatra::Application.root}./tmp/uploads"
  end
end
