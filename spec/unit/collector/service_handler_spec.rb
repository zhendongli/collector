# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe Collector::ServiceHandler do

  describe :send_metric do
    it "should send the metric to the TSDB server with service & component" \
       "tag" do
      historian = mock("Historian")
      historian.should_receive(:send_data).
        with({
        key: "some_key",
        timestamp: 10_000,
        value: 2,
        tags: {
          index: 1,
          component: "unknown",
          service_type: "unknown",
          job: "Test",
          tag: "value"
        }
      })
      handler = Collector::ServiceHandler.new(historian, "Test", 1, 10000)
      handler.send_metric("some_key", 2, {:tag => "value"})
    end
  end

  describe :process_healthy_instances_metric do
    it "should report healthy instances percentage metric to TSDB server" do
      historian = mock('Historian')
      historian.should_receive(:send_data).
        with({
        key: "services.healthy_instances",
        timestamp: 10_000,
        value: "50.00",
        tags: {
          component: "unknown",
          index: 1,
          job: "Test",
          service_type: "unknown"
        }
      })

      handler = Collector::ServiceHandler.new(historian, "Test", 1, 10000)
      varz = {
        "instances" => {
          1 => 'ok',
          2 => 'fail',
          3 => 'fail',
          4 => 'ok'
        }
      }
      handler.process_healthy_instances_metric(varz)
    end
  end

  describe :process_plan_score_metric do
    it "should report low_water & high_water & score metric to TSDB server" do
      historian = mock("Historian")
      data = []
      historian.stub(:send_data) do |args|
        data << args
      end

      handler = Collector::ServiceHandler.new(historian, "Test", 1, 10000)
      varz = {
        "plans" => [
          {
            "plan" => "free",
            "low_water" => 100,
            "high_water" => 1400,
            "score" => 150,
            "max_capacity" => 500,
            "available_capacity" => 450,
            "used_capacity" => 50
          }
        ]
      }
      handler.process_plan_score_metric(varz)
      data.collect { |o| [o[:key], o[:value]] }.should =~ [
        ["services.plans.high_water", 1400],
        ["services.plans.low_water", 100],
        ["services.plans.score", 150],
        ["services.plans.allow_over_provisioning", 0],
        ["services.plans.used_capacity", 50],
        ["services.plans.max_capacity", 500],
        ["services.plans.available_capacity", 450]
      ]
    end
  end

  describe :process_online_nodes do
    it "should report online nodes number to TSDB server" do
      historian = mock("Historian")
      historian.should_receive(:send_data).
        with({
        key: "services.online_nodes",
        timestamp: 10_000,
        value: 2,
        tags: {
          component: "unknown",
          index: 1,
          job: "Test",
          service_type: 'unknown'
        }
      })
      handler = Collector::ServiceHandler.new(historian, "Test", 1, 10000)
      varz = {
        "nodes" => {
          "node_0" => {
            "available_capacity" => 50,
            "plan" => "free"
          },
          "node_1" => {
            "available_capacity" => 50,
            "plan" => "free"
          }
        }
      }
      handler.process_online_nodes(varz)
    end
  end

end
