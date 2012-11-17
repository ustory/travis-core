require 'spec_helper'

describe Travis::Services::UpdateHook do
  include Travis::Testing::Stubs

  let(:service) { described_class.new(user, params) }
  let(:params)  { { id: repo.id, active: true } }

  before :each do
    repo.stubs(:update_column)
    service.stubs(:service).returns(stub(run: repo))
    user.stubs(:service_hook).returns(repo)
  end

  it 'finds the repo by the given params' do
    user.expects(:service_hook).with(id: repo.id).returns(repo)
    service.run
  end

  it 'sets the given :active param to the hook' do
    service.expects(:service).with(:github_set_hook, params).returns(stub(run: nil))
    service.run
  end

  describe 'sets the repo to the active param' do
    it 'given true' do
      service.params.update(active: true)
      repo.expects(:update_column).with(:active, true)
      service.run
    end

    it 'given false' do
      service.params.update(active: false)
      repo.expects(:update_column).with(:active, false)
      service.run
    end

    it 'given "true"' do
      service.params.update(active: 'true')
      repo.expects(:update_column).with(:active, true)
      service.run
    end

    it 'given "false"' do
      service.params.update(active: 'false')
      repo.expects(:update_column).with(:active, false)
      service.run
    end
  end
end

describe Travis::Services::UpdateHook::Instrument do
  include Travis::Testing::Stubs

  let(:service)   { Travis::Services::UpdateHook.new(user, params) }
  let(:params)    { { id: repository.id, active: 'true' } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events.last }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    Travis::Services::GithubSetHook.any_instance.stubs(:run)
    user.stubs(:service_hook).returns(repo)
    repo.stubs(:update_column).returns(true)
  end

  it 'publishes a event' do
    service.run
    event.should publish_instrumentation_event(
      event: 'travis.services.update_hook.run:completed',
      message: 'Travis::Services::UpdateHook#run:completed for svenfuchs/minimal active=true (svenfuchs)',
      result: true
    )
  end
end
