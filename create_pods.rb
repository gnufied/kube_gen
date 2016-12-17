require 'yaml'
require 'erb'
require 'json'

threads = []
podnames = []

class PodDetail
  attr_accessor :pvc_name, :pod_name
  def initialize(pvc_name, pod_name)
    @pvc_name = pvc_name
    @pod_name = pod_name
  end

  def get_binding
    binding()
  end
end

threads << Thread.new do
  index = 0
  pvc_yaml = File.read("dyn-pvc.yaml")
  pod_yaml = File.read("dyn-pod.yaml")

  loop do
    pvc_name = "dyn-pvc-#{index}"
    pod_name = "pod-#{index}"
    pod_detail = PodDetail.new(pvc_name, pod_name)
    podnames << pod_detail
    pvc_erb = ERB.new(pvc_yaml)
    pvc_result_yaml = pvc_erb.result(pod_detail.get_binding)
    File.open("/tmp/#{pvc_name}.yaml", "w") do |fl|
      fl.write(pvc_result_yaml)
    end
    puts "Creating pvc #{pvc_name}"
    system("oc create -f /tmp/#{pvc_name}.yaml")
    check_for_pvc(pvc_name)
    pod_erb = ERB.new(pod_yaml)
    pod_result_yaml = pod_erb.result(pod_detail.get_binding)
    File.open("/tmp/#{pod_name}.yaml", "w") do |fl|
      fl.write(pod_result_yaml)
    end
    puts "Creating pod #{pod_name}"
    system("oc create -f /tmp/#{pod_name}.yaml")
    index += 1
    check_for_pod(pod_name)
    sleep(5)
  end
end

def check_for_pvc(pvc_name)
  loop do
    t = `oc get pvc #{pvc_name} -o json`
    pvc_info = load_pvc_json(t)
    if pvc_info && pvc_info["status"] && pvc_info["status"]["phase"] == "Bound"
      return true
    end
    sleep(2)
  end
end

def check_for_pod(pod_name)
  loop do
    t = `oc get pod #{pod_name} -o json`
    pvc_info = load_pvc_json(t)
    if pvc_info && pvc_info["status"] && pvc_info["status"]["phase"] == "Running"
      return true
    end
    sleep(2)
  end
end

def load_pvc_json(data)
  JSON.load(data)
rescue
  nil
end

def delete_pod(pod_name)
  t = `oc get pod #{pod_name} -o json`
  pod_info = JSON.load(t)
  if pod_info && pod_info["status"] && pod_info["status"]["phase"] == 'Running'
    puts "Deleting pod #{pod_name}"
    system("oc delete pod #{pod_name}")
    true
  end
  false
rescue
  puts "Error deleting pod #{pod_name}"
  false
end


threads.each { |thr| thr.join }
