require "digest"
require "yaml"

class Cashrun::Configuration
  property config_file : String
  property cache_directory : String
  property digest : Digest::Base
  property verbose : Bool

  def initialize(@config_file, @cache_directory, @digest, @verbose); end

  def self.default
    Cashrun::Configuration.new("~/.config/cashrun", "~/.cache/cashrun", Digest::MD5.new, false)
  end

  def self.decide_hash(hashname) : Digest::Base?
    case hashname
    when "md5"
      Digest::MD5.new
    else
      nil
    end
  end

  def to_partial
    partial = Cashrun::Configuration::Partial.new
    partial.config_file = config_file
    partial.cache_directory = cache_directory
    partial.digest = digest
    partial.verbose = verbose
    partial
  end

  def to_s(io)
    io << <<-TOS
    #<Cashrun::Configuration @config_file="#{config_file}" @cache_directory="#{cache_directory}" @digest="#{digest}" @verbose="#{verbose}" >
    TOS
  end

  class Partial
    property config_file : String?
    property cache_directory : String?
    property digest : Digest::Base?
    property verbose : Bool?

    def unpartial
      raise MissingError.new("Missing config_file") if config_file.nil?
      raise MissingError.new("Missing cache_directory") if cache_directory.nil?
      raise MissingError.new("Missing digest") if digest.nil?
      raise MissingError.new("Missing verbose") if verbose.nil?

      Cashrun::Configuration.new(
        config_file.not_nil!,
        cache_directory.not_nil!,
        digest.not_nil!,
        verbose.not_nil!
      )
    end

    class MissingError < Exception; end
  end

  def parse_file!
    filename = File.expand_path(config_file)

    unless File.exists?(filename)
      return
    end

    yaml = YAML.parse(File.read(filename))

    if yaml["cache_directory"]?
      @cache_directory = yaml["cache_directory"].as_s
    end

    if yaml["digest"]?
      Cashrun::Configuration.decide_hash(yaml["digest"].as_s).try { |h| @digest = h }
    end
  end
end