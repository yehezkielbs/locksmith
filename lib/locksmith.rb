require 'rubygems'
require 'tuwaga'
require 'digest/md5'

class Locksmith
  attr_accessor :private_password, :domain, :username
  attr_reader :errors

  @@alpha_hex = Tuwaga.new(16, 'abcdefghijklmnop')
  @@symbol_hex = Tuwaga.new(16, '~!@#$%^&*()_+-={')
  @@hex = Tuwaga.new(16)

  def initialize private_password, domain, username, options
    @private_password = private_password
    @domain = domain
    @username = username
    @use_alphabet = options[:use_alphabet]
    @use_number = options[:use_number]
    @use_symbol = options[:use_symbol]

    @errors = []
  end

  def use_alphabet?
    @use_alphabet
  end

  def use_alphabet= use_alphabet
    @use_alphabet = use_alphabet
  end

  def use_number?
    @use_number
  end

  def use_number= use_number
    @use_number = use_number
  end

  def use_symbol?
    @use_symbol
  end

  def use_symbol= use_symbol
    @use_symbol = use_symbol
  end

  def valid?
    @errors = []

    if !@private_password || @private_password.empty?
      @errors << 'private password is required'
    end

    if !@domain || @domain.empty?
      @errors << 'domain is required'
    end

    if !@use_alphabet && !@use_number && !@use_symbol
      @errors << 'at least on of use_alphabet, use_number or use_symbol must be true'
    end

    (@errors.length == 0)
  end

  def generated_password
    if valid?
      raw = @private_password + @domain + (@username || '')
      hex_string = Digest::MD5.hexdigest(raw)

      result = ''

      if @use_alphabet
        result += @@alpha_hex.convert_from(hex_string[0, 1], @@hex).upcase
        hex_string = hex_string[1, (hex_string.length - 1)]

        result += @@alpha_hex.convert_from(hex_string[0, 1], @@hex).downcase
        hex_string = hex_string[1, (hex_string.length - 1)]
      end

      if @use_number
        result += @@hex.to_decimal(hex_string[0, 1]).to_s
        hex_string = hex_string[1, (hex_string.length - 1)]
      end

      if @use_symbol
        result += @@symbol_hex.convert_from(hex_string[0, 1], @@hex)
        hex_string = hex_string[1, (hex_string.length - 1)]
      end

      base_x_symbols = ''
      base_x_symbols += 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' if @use_alphabet
      base_x_symbols += '0123456789' if @use_number
      base_x_symbols += '~!@#$%^&*()_+-={}|[]\\;\':"<>?,./' if @use_symbol
      base_x = Tuwaga.new(base_x_symbols.length, base_x_symbols)
      result += base_x.convert_from(hex_string, @@hex)

      result
    else
      raise('Can not generate password: ' + @errors.join(', '))
    end
  end
end