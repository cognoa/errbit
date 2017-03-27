module AirbrakeApi
  module V3
    class NoticeParser
      class ParamsError < StandardError; end

      attr_reader :params, :error

      def initialize(params)
        @params = params || {}
      end

      def attributes
        {
          error_class:        error['type'],
          message:            error['message'],
          backtrace:          backtrace,
          request:            request,
          server_environment: server_environment,
          api_key:            params['key'].present? ? params['key'] : params['project_id'],
          notifier:           context['notifier'] || params['notifier'],
          user_attributes:    user_attributes
        }
      end

      def report
        ErrorReport.new(attributes)
      end

    private

      def error
        fail AirbrakeApi::ParamsError unless params.key?('errors') && params['errors'].any?
        @error ||= params['errors'].first
      end

      def backtrace
        (error['backtrace'] || []).map do |backtrace_line|
          {
            method: backtrace_line['function'],
            file:   backtrace_line['file'],
            number: backtrace_line['line'],
            column: backtrace_line['column']
          }
        end
      end

      def server_environment
        {
          'environment-name' => context['environment'],
          'hostname'         => hostname,
          'project-root'     => context['rootDirectory'],
          'app-version'      => context['version']
        }
      end

      def request
        request_env = params['request_env'] || {}
        environment = (params['environment'] || {}).merge(
          'HTTP_ACCEPT' => request_env['HTTP_ACCEPT'],
          'HTTP_ACCEPT_ENCODING' => request_env['HTTP_ACCEPT_ENCODING'],
          'HTTP_ACCEPT_LANGUAGE' => request_env['HTTP_ACCEPT_LANGUAGE'],
          'HTTP_CACHE_CONTROL' => request_env['HTTP_CACHE_CONTROL'],
          'HTTP_CONNECTION' => request_env['HTTP_CONNECTION'],
          'HTTP_COOKIE' => request_env['HTTP_COOKIE'],
          'HTTP_HOST' => request_env['HTTP_HOST'],
          'HTTP_IF_NONE_MATCH' => request_env['HTTP_IF_NONE_MATCH'],
          'HTTP_UPGRADE_INSECURE_REQUESTS' => request_env['HTTP_UPGRADE_INSECURE_REQUESTS'],
          'HTTP_USER_AGENT' => request_env['HTTP_USER_AGENT'],
          'HTTP_VERSION' => request_env['HTTP_VERSION'],
          'HTTP_X_AMZ_SERVER_SIDE_ENCRYPTIO' => request_env['HTTP_X_AMZ_SERVER_SIDE_ENCRYPTIO'],
          'ORIGINAL_FULLPATH' => request_env['ORIGINAL_FULLPATH'],
          'ORIGINAL_SCRIPT_NAME' => request_env['ORIGINAL_SCRIPT_NAME'],
          'PATH_INFO' => request_env['PATH_INFO'],
          'QUERY_STRING' => request_env['QUERY_STRING'],
          'REMOTE_ADDR' => request_env['REMOTE_ADDR'],
          'REQUEST_METHOD' => request_env['REQUEST_METHOD'],
          'REQUEST_PATH' => request_env['REQUEST_PATH'],
          'REQUEST_URI' => request_env['REQUEST_URI'],
          'SERVER_NAME' => request_env['SERVER_NAME'],
          'SERVER_PORT' => request_env['SERVER_PORT'],
          'SERVER_PROTOCOL' => request_env['SERVER_PROTOCOL'],
          'SERVER_SOFTWARE' => request_env['SERVER_SOFTWARE']
        )

        {
          'cgi-data'  => environment,
          'session'   => params['session'],
          'params'    => params['params'],
          'url'       => url,
          'component' => context['component'],
          'action'    => context['action']
        }
      end

      def user_attributes
        return context['user'] if context['user']

        {
          'id'       => context['userId'],
          'name'     => context['userName'],
          'email'    => context['userEmail'],
          'username' => context['userUsername']
        }.compact
      end

      def url
        context['url']
      end

      def hostname
        context['hostname'] || URI.parse(url).hostname
      rescue URI::InvalidURIError
        ''
      end

      def context
        @context = params['context'] || {}
      end
    end
  end
end
