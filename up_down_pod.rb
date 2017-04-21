require 'thread'
require_relative "./deployment"

class UpDown
  attr_accessor :min, :max
  def initialize(min, max)
    @min = min
    @max = max

  end

  def up_down_pod(state = :down)
    puts "Scaling the pods #{state}"
    min.upto(max) do |current_index|
      if state == :down
        system("kubectl scale --replicas=0 deployment/dc-#{current_index}")
      else
        system("kubectl scale --replicas=1 deployment/dc-#{current_index}")
      end
    end

    deployment = Deployment.new("dc-#{max}")

    if state == :down
      deployment.check_if_down
    else
      deployment.check_if_up
    end
  end
end


t = UpDown.new(7, 30)

state = :up
10.times do
  t.up_down_pod(state)
  if state == :up
    state = :down
  else
    state = :up
  end
end

t.up_down_pod(:up)
