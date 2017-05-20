require 'active_support/core_ext/object'
require 'backgrounder/support/backends'
require 'backgrounder/orm/base'
require 'backgrounder/delay'

module CarrierWave
  module Backgrounder
    include Support::Backends

    mattr_accessor :enabled
    self.enabled = true

    def self.configure
      yield self
      case @backend
      when :sidekiq
        require 'sidekiq'
        ::CarrierWave::Workers::ProcessAsset.class_eval do
          include ::Sidekiq::Worker
        end
        ::CarrierWave::Workers::StoreAsset.class_eval do
          include ::Sidekiq::Worker
        end
      when :sucker_punch
        require 'sucker_punch'
        ::CarrierWave::Workers::ProcessAsset.class_eval do
          include ::SuckerPunch::Job
        end
        ::CarrierWave::Workers::StoreAsset.class_eval do
          include ::SuckerPunch::Job
        end
      end
    end

    #Warning: Not thread safe. For tests only!
    def self.with_perform(value = true)
      old = enabled
      self.enabled = value
      yield
    ensure
      self.enabled = old
    end
  end
end

require 'backgrounder/railtie' if defined?(Rails)
