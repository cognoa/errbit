describe AirbrakeApi::V3::NoticeParser do
  let(:app) { Fabricate(:app) }
  let(:notifier_params) do
    {
      'name'    => 'notifiername',
      'version' => 'notifierversion',
      'url'     => 'notifierurl'
    }
  end

  it 'raises error when errors attribute is missing' do
    expect do
      described_class.new({}).report
    end.to raise_error(AirbrakeApi::ParamsError)

    expect do
      described_class.new('errors' => []).report
    end.to raise_error(AirbrakeApi::ParamsError)
  end

  it 'does not raise an error for the optional environment field' do
    expect do
      described_class.new('errors' => ['MyError']).report
    end.not_to raise_error
  end

  it 'parses JSON payload and returns ErrorReport' do
    params = build_params_for('api_v3_request.json', key: app.api_key)

    report = described_class.new(params).report
    notice = report.generate_notice!

    expect(report.error_class).to eq('Error')
    expect(report.message).to eq('Error: TestError')
    expect(report.backtrace.lines.size).to eq(9)
    expect(notice.user_attributes).to include(
      'id'       => 1,
      'name'     => 'John Doe',
      'email'    => 'john.doe@example.org',
      'username' => 'john'
    )
    expect(notice.session).to include('isAdmin' => true)
    expect(notice.params).to include('returnTo' => 'dashboard')
    request_env = {}
    expect(notice.env_vars).to include(
      'navigator_vendor' => 'Google Inc.',
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
  end

  it 'parses JSON payload when api_key is missing but project_id is present' do
    params = build_params_for('api_v3_request.json', key: nil, project_id: app.api_key)

    report = described_class.new(params).report
    expect(report).to be_valid
  end

  it 'parses JSON payload with missing backtrace' do
    json = Rails.root.join('spec', 'fixtures', 'api_v3_request_without_backtrace.json').read
    params = JSON.parse(json)
    params['key'] = app.api_key

    report = described_class.new(params).report
    report.generate_notice!

    expect(report.error_class).to eq('Error')
    expect(report.message).to eq('Error: TestError')
    expect(report.backtrace.lines.size).to eq(0)
  end

  it 'parses JSON payload with deprecated user keys' do
    params = build_params_for('api_v3_request_with_deprecated_user_keys.json', key: app.api_key)

    report = AirbrakeApi::V3::NoticeParser.new(params).report
    notice = report.generate_notice!

    expect(notice.user_attributes).to include(
      'id'       => 1,
      'name'     => 'John Doe',
      'email'    => 'john.doe@example.org',
      'username' => 'john'
    )
  end

  it 'takes the notifier from root' do
    parser = described_class.new(
      'errors'      => ['MyError'],
      'notifier'    => notifier_params,
      'environment' => {})
    expect(parser.attributes[:notifier]).to eq(notifier_params)
  end

  it 'takes the notifier from the context' do
    parser = described_class.new(
      'errors'      => ['MyError'],
      'context'     => { 'notifier' => notifier_params },
      'environment' => {})
    expect(parser.attributes[:notifier]).to eq(notifier_params)
  end

  it 'takes the hostname from the context' do
    parser = described_class.new(
        'errors'      => ['MyError'],
        'context'     => { 'hostname' => 'app01.infra.example.com', 'url' => 'http://example.com/some-page' },
        'environment' => {})
    expect(parser.attributes[:server_environment]['hostname']).to eq('app01.infra.example.com')
  end

  def build_params_for(fixture, options = {})
    json = Rails.root.join('spec', 'fixtures', fixture).read
    data = JSON.parse(json)

    data['key'] = options[:key] if options.key?(:key)
    data['project_id'] = options[:project_id] if options.key?(:project_id)

    data
  end
end
