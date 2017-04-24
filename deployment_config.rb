require 'yaml'
require 'erb'
require 'json'


class DeploymentConfig
  attr_accessor :dc_name
  def initialize(dc_name)
    @dc_name = dc_name
  end
end
