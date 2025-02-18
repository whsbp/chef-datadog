require 'spec_helper'

describe 'datadog::security-agent' do
  context 'with CWS enabled' do
    cached(:solo) do
      ChefSpec::SoloRunner.new(
        platform: 'ubuntu',
        version: '16.04'
      ) do |node|
        node.name 'chef-nodename' # expected to be used as the hostname in `datadog.yaml`
        node.normal['datadog'] = {
          'api_key' => 'somethingnotnil',
          'agent_major_version' => 6,
          'security_agent' => {
            'cws' => {
              'enabled' => true,
            }
          },
          'extra_config' => {
            'security_agent' => {
              'runtime_security_config' => {
                'activity_dump' => {
                  'enabled' => true,
                }
              }
            }
          }
        }
      end
    end

    cached(:chef_run) do
      solo.converge(described_recipe) do
        solo.resource_collection.insert(
          Chef::Resource::Service.new('datadog-agent', solo.run_context))
      end
    end

    it 'security-agent.yaml is created' do
      expect(chef_run).to create_template('/etc/datadog-agent/security-agent.yaml')
    end

    it 'security-agent.yaml contains expected YAML configuration' do
      expected_yaml = <<-EOF
      compliance_config:
        enabled: false
      runtime_security_config:
        enabled: true
        activity_dump:
          enabled: true
      EOF

      expect(chef_run).to(render_file('/etc/datadog-agent/security-agent.yaml').with_content { |content|
        expect(YAML.safe_load(content).to_json).to be_json_eql(YAML.safe_load(expected_yaml).to_json)
      })
    end
  end
end
