require 'base64'

module EcsDeployer
  module Util
    class Cipher
      ENCRYPT_VARIABLE_PATTERN = /^\${(.+)}$/

      # @param [Hash] aws_options
      # @return [EcsDeployer::Util::Cipher]
      def initialize(aws_options = {})
        @kms = Aws::KMS::Client.new(aws_options)
      end

      # @param [String] mater_key
      # @param [String] value
      # @return [String]
      def encrypt(master_key, value)
        encode = @kms.encrypt(key_id: "alias/#{master_key}", plaintext: value)
        "${#{Base64.strict_encode64(encode.ciphertext_blob)}}"
      rescue => e
        raise KmsEncryptError, e.to_s
      end

      # @param [String] value
      # @return [String]
      def decrypt(value)
        match = value.match(ENCRYPT_VARIABLE_PATTERN)
        raise KmsDecryptError, 'Encrypted string is invalid.' unless match

        begin
          @kms.decrypt(ciphertext_blob: Base64.strict_decode64(match[1])).plaintext
        rescue => e
          raise KmsDecryptError, e.to_s
        end
      end

      # @param [String] value
      # @return [Bool]
      def encrypt_value?(value)
        value.to_s.match(ENCRYPT_VARIABLE_PATTERN) ? true : false
      end
    end
  end
end
