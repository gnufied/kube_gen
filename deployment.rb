require 'yaml'
require 'erb'
require 'json'


class DcDetail
  attr_accessor :pvc_name, :dc_name
  def initialize(pvc_name, dc_name)
    @pvc_name = pvc_name
    @dc_name = dc_name
  end

  def get_binding
    binding()
  end
end


class Deployment
  attr_accessor :dc_name, :pvc_name
  PVC_YAML = File.read("dyn-pvc.yaml")
  DC_YAML = File.read("dyn-dc.yaml")

  def initialize(dc_name)
    @dc_name = dc_name
  end

  def create(pvc_name)
    @pvc_name = pvc_name
    dc_detail = DcDetail.new(pvc_name, dc_name)
    pvc_erb = ERB.new(PVC_YAML)
    pvc_result_yaml = pvc_erb.result(dc_detail.get_binding)
    File.open("/tmp/#{pvc_name}.yaml", "w") do |fl|
      fl.write(pvc_result_yaml)
    end
    puts "Creating pvc #{pvc_name}"
    system("kubectl create -f /tmp/#{pvc_name}.yaml")
  end

  def check_if_up
    puts "Checking if deployment #{dc_name} is up"
    loop do
      t = `kubectl get deployments #{dc_name} -o json`
      dc_info = load_json(t)
      if dc_info && dc_info["status"] && dc_info["status"]["availableReplicas"] == 1
        return true
      end
      sleep(2)
    end
  end

  def check_if_down
    puts "Checking if deployment #{dc_name} is down"
    loop do
      t = `kubectl get deployments #{dc_name} -o json`
      dc_info = load_json(t)
      if dc_info && dc_info["spec"] && dc_info["spec"]["replicas"] == 0
        return true
      end
      sleep(2)
    end
  end

  def load_json(data)
    JSON.load(data)
  rescue
    nil
  end
end
