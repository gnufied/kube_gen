class CleanFailed
  def clean
    failing_pods = `kubectl get pods|grep ContainerCreating|tr -s ' '|cut -f 1 -d ' '`
    failing_pods.split("\n").each do |fp|
      if fp && !fp.strip.empty?
        pod_number = fp.split("-")[1]
        pv = `kubectl get pv|grep 'dyn-pvc-#{pod_number}\\s' |tr -s ' '|cut -f 1 -d ' '`
        pv.strip!
        volume_id = `kubectl get pv #{pv} -o json|jq '.spec.awsElasticBlockStore.volumeID'`
        aws_volume_id = volume_id.split("/")[-1]
        puts "for #{pod_number}  #{aws_volume_id}"
      end
    end
  end
end


CleanFailed.new.clean()
