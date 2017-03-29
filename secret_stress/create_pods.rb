require 'yaml'
require 'erb'
require 'base64'
require 'pry'
require 'json'

class PodDetail
  attr_accessor :pod_name, :secret
  def initialize(pod_name, secret)
    @pod_name = pod_name
    @secret = secret
  end

  def get_binding
    binding()
  end
end

class Secret
  attr_accessor :secret_name, :username, :password
  def initialize(secret_name, username, password)
    @secret_name = secret_name
    @username = Base64.encode64(username)
    @password = Base64.encode64(password)
  end

  def get_binding
    binding()
  end
end


class CreatePods
  POD_YAML = File.read("pod.yaml")
  SECRET_YAML = File.read("secret.yaml")

  def create(count, start_index)
    if count == -1
      infinite_create(start_index)
    else
      finite_create(count, start_index)
    end
  end

  def finite_create(count, start_index)
    count.times do |i|
      net_index = start_index + i
      secret_name = "secret-#{net_index}"
      pod_name = "pod-#{net_index}"
      username = "username-#{net_index}"
      password = "password-#{net_index}"
      create_secret(secret_name, username, password)

      create_pods(pod_name, secret_name)
      sleep(2)
    end
  end

  def infinite_create(index = 0)
    net_index = index
    loop do
      secret_name = "secret-#{net_index}"
      pod_name = "pod-#{net_index}"
      username = "username-#{net_index}"
      password = "password-#{net_index}"
      create_secret(secret_name, username, password)

      create_pods(pod_name, secret_name)
      net_index += 1
      sleep(2)
    end
  end


  def create_pods(pod_name, secret_name)
    pod_info = PodDetail.new(pod_name, secret_name)
    pod_erb = ERB.new(POD_YAML)
    pod_yaml_result = pod_erb.result(pod_info.get_binding)
    File.open("/tmp/#{pod_name}.yaml", "w") do |fl|
      fl.write(pod_yaml_result)
    end
    puts "Creating pod #{pod_name}"
    system("kubectl create -f /tmp/#{pod_name}.yaml")
    check_for_pod(pod_name)
  end


  def create_secret(secret_name, username, password)
    secret = Secret.new(secret_name, username, password)
    secret_erb = ERB.new(SECRET_YAML)
    secret_result_yaml = secret_erb.result(secret.get_binding)
    File.open("/tmp/#{secret_name}.yaml", "w") do |fl|
      fl.write(secret_result_yaml)
    end
    puts "Creating secret #{secret_name}"
    system("kubectl create -f /tmp/#{secret_name}.yaml")
    sleep(2)
  end


  def check_for_pod(pod_name)
    loop do
      puts "Getting pod #{pod_name}"
      t = `kubectl get pod #{pod_name} -o json`
      pod_info = load_json(t)
      if pod_info && pod_info["status"] && pod_info["status"]["phase"] == "Running"
        return true
      end
      sleep(2)
    end
  end

  def delete_pods
    index = 0
    loop do
      pod_name = "pod-#{index}"
      check_for_pod(pod_name)
      puts "Deleting pod #{pod_name}"
      system("kubectl delete pod #{pod_name}")
      index += 1
      sleep(1)
    end
  end

  def load_json(data)
    JSON.load(data)
  rescue
    nil
  end
end

CreatePods.new.create(-1, 0)
# CreatePods.new.delete_pods
