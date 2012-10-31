require 'active_support/core_ext/class/attribute'

module Travis
  module Services
    module Github
      # encapsulates fetching a .travis.yml from a given commit's config_url
      class FetchConfig
        include Logging
        extend Instrumentation

        attr_accessor :request

        def initialize(request)
          @request = request
        end

        def run
          config = parse(fetch)
          Travis.logger.info("Empty config for request #{request.id}") if config.nil?
          config
        rescue GH::Error => e
          if e.info[:response_status] == 404
            { '.result' => 'not_found' }
          else
            { '.result' => 'server_error' }
          end
        end
        instrument :run

        def config_url
          request.config_url
        end

        private

          def fetch
            content = GH[config_url]['content']
            Travis.logger.warn("Got empty content for #{config_url}") if content.nil?
            content = content.to_s.unpack('m').first
            Travis.logger.warn("Got empty unpacked content for #{config_url}, content was #{content.inspect}") if content.nil?
            content
          end

          def parse(yaml)
            YAML.load(yaml).merge('.result' => 'configured')
          rescue StandardError, Psych::SyntaxError => e
            log_exception(e)
            { '.result' => 'parsing_failed' }
          end

          Notification::Instrument::Services::Github::FetchConfig.attach_to(self)
      end
    end
  end
end
