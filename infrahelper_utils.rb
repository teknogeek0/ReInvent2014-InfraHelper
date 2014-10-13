#!/usr/bin/ruby
#
# Copyright 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
#

## require what we'll need

require 'bundler/setup'
require 'aws/decider'
require 'logger'
require 'yaml'
require 'aws-sdk'
require 'json'

## load from config our environment variables
$CONFIG = YAML.load_file("IHQueueConfig.yml") unless defined? CONFIG
$IH_CONFIG = JSON.parse(File.read("infrahelper.json"))

## set up our loggers
logFile = File.open('/var/log/infrahelper/app.log', File::WRONLY | File::APPEND | File::CREAT)
$logger = Logger.new(logFile)

# These are utilities that are common
module SharedUtils

  def setup_domain(domain_name)
    swf = AWS::SimpleWorkflow.new(region: "#{CONFIG['Region']}")
    domain = swf.domains[domain_name]
    unless domain.exists?
        swf.domains.create(domain_name, 10)
    end
    domain
  end

  def build_workflow_worker(domain, klass, task_list)
    AWS::Flow::WorkflowWorker.new(domain.client, domain, task_list, klass)
  end

  def build_generic_activity_worker(domain, task_list)
    AWS::Flow::ActivityWorker.new(domain.client, domain, task_list)
  end

  def build_activity_worker(domain, klass, task_list)
    AWS::Flow::ActivityWorker.new(domain.client, domain, task_list, klass)
  end

  def build_workflow_client(domain, options_hash)
    AWS::Flow::workflow_client(domain.client, domain) { options_hash }
  end
end


class InfraHelperUtils
  include SharedUtils

  WF_VERSION = "1.0"
  ACTIVITY_VERSION = "1.0"
  WF_TASKLIST = "infrahelper_workflow_task_list"
  ACTIVITY_TASKLIST = "infrahelper_activity_task_list"
  DOMAIN = IH_CONFIG["domain"]["name"]

  def initialize
    @domain = setup_domain(DOMAIN)
  end

  def activity_worker
    build_activity_worker(@domain, InfraHelperActivity, ACTIVITY_TASKLIST)
  end

  def workflow_worker
    build_workflow_worker(@domain, InfraHelperWorkflow, WF_TASKLIST)
  end

  def workflow_client
    build_workflow_client(@domain, from_class: "InfraHelperWorkflow")
  end
end

