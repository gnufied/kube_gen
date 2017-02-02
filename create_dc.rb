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

class CreateDc
  PVC_YAML = File.read("dyn-pvc.yaml")
  DC_YAML = File.read("dyn-dc.yaml")

  def create(count, start_index)
    if count == -1
      infinite_create(start_index)
    else
      finite_create(count, start_index)
    end
  end

  def infinite_create(start_index = 0)
    index = start_index
    loop do
      pvc_name = "dyn-pvc-#{index}"
      dc_name = "dc-#{index}"
      create_dc(pvc_name, dc_name)
      index +=1
      sleep(2)
    end
  end

  def finite_create(count, start_index)
    count.times do |i|
      net_index = start_index + i
      pvc_name = "dyn-pvc-#{net_index}"
      dc_name = "dc-#{net_index}"
      create_dc(pvc_name, dc_name)
      sleep(2)
    end
  end

  def create_dc(pvc_name, dc_name)
    dc_detail = DcDetail.new(pvc_name, dc_name)
    pvc_erb = ERB.new(PVC_YAML)
    pvc_result_yaml = pvc_erb.result(dc_detail.get_binding)
    File.open("/tmp/#{pvc_name}.yaml", "w") do |fl|
      fl.write(pvc_result_yaml)
    end
    puts "Creating pvc #{pvc_name}"
    system("oc create -f /tmp/#{pvc_name}.yaml")
    check_for_pvc(pvc_name)

    # create dc
    dc_erb = ERB.new(DC_YAML)
    dc_result_yaml = dc_erb.result(dc_detail.get_binding)
    File.open("/tmp/#{dc_name}.yaml", "w") do |fl|
      fl.write(dc_result_yaml)
    end
    puts "Creating dc #{dc_name}"
    system("oc create -f /tmp/#{dc_name}.yaml")
    check_for_dc(dc_name)
  end

  def check_for_dc(dc_name)
    loop do
      t = `oc get deployments #{dc_name} -o json`
      dc_info = load_json(t)
      if dc_info && dc_info["status"] && dc_info["status"]["availableReplicas"] == 1
        return true
      end
      sleep(2)
    end
  end

  def check_for_pvc(pvc_name)
    loop do
      t = `oc get pvc #{pvc_name} -o json`
      pvc_info = load_json(t)
      if pvc_info && pvc_info["status"] && pvc_info["status"]["phase"] == "Bound"
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

DcDetail.new.create(10, 5)
