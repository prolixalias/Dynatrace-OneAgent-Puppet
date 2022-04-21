# frozen_string_literal: true

require 'spec_helper'

describe 'dynatraceoneagent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          'tenant_url' => 'https://tenant.fervid.us',
          'paas_token' => 'abc123'
        }
      end

      it { is_expected.to compile }
    end
  end
end
