require_relative "./deployment_config"

class LaunchPostgres
  attr_accessor :dc_name
  def initialize(dc_name)
    @dc_name = dc_name
  end

  def launch_cmd
    "oc new-app postgres.json -p DATABASE_SERVICE_NAME=#{dc_name} POSTGRESQL_USER=hekumar POSTGRESQL_PASSWORD=password"
  end

  def create
    system(launch_cmd)
  end
end

lp = LaunchPostgres.new("foobar")
pl.create
