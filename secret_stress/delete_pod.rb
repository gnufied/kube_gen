require 'yaml'
require 'erb'
require 'base64'
require 'json'


class DeletePod
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

  def delete_pods(start_index = 0)
    index = start_index
    loop do
      pod_name = "pod-#{index}"
      check_for_pod(pod_name)
      puts "Deleting pod #{pod_name}"
      system("kubectl delete pod #{pod_name}")
      if $? != 0
        index = 0
        next
      end
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

DeletePod.new.delete_pods()
