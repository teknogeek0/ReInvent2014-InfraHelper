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
require 'socket'

## load from config our environment variables
$CONFIG = YAML.load_file(File.dirname(__FILE__)+"/IHQueueConfig.yml") unless defined? CONFIG
$IH_CONFIG = JSON.parse(File.read(File.dirname(__FILE__)+"/infrahelper.json"))

# default region for all services
AWS.config({region: "#{$CONFIG['Region']}"})

## set up our loggers
logFile = File.open('/var/log/infrahelper/app.log', File::WRONLY | File::APPEND | File::CREAT)
logFile.sync = true
$logger = Logger.new(logFile)
$logger.formatter = proc do |severity, datetime, progname, msg|
   "#{Socket.gethostname} [#{datetime.strftime('%d/%b/%Y:%H:%M:%S %z')}] #{progname} #{severity} ##{Process.pid}: #{msg}\n"
end

# These are utilities that are common
module SharedUtils


  def setup_domain(domain_name)
    swf = AWS::SimpleWorkflow.new()
    domain = swf.domains[domain_name]
    unless domain.exists?
        swf.domains.create(domain_name, 10)
    end
    
    $logger.info('utils') { "DEBUG: inside setup_domain. this is my config region: #{$CONFIG['Region']}" }
    $logger.info('utils') { "DEBUG: inside setup_domain. this is my domain: #{$IH_CONFIG["domain"]["name"]}" }
    $logger.info('utils') { "DEBUG: inside setup_domain. this is my region: #{swf.config.region}" }
    $logger.info('utils') { "DEBUG: inside setup_domain. this is my swf region: #{swf.config.simple_workflow_region}" }
    
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

  WF_VERSION = "1.3"
  ACTIVITY_VERSION = "1.3"
  WF_TASKLIST = "infrahelper_workflow_task_list"
  ACTIVITY_TASKLIST = "infrahelper_activity_task_list"
  DOMAIN = $IH_CONFIG["domain"]["name"]
  AWS.config({region: "#{$CONFIG['Region']}"})

  def initialize
    @domain = setup_domain(DOMAIN)
  end

  def activity_worker
    $logger.info('utils') { "DEBUG: inside activity_worker. this is my config region: #{$CONFIG['Region']}" }
    $logger.info('utils') { "DEBUG: inside activity_worker. this is my domain: #{$IH_CONFIG["domain"]["name"]}" }
    $logger.info('utils') { "DEBUG: inside activity_worker. this is my region: #{@domain.client.config.region}" }
    $logger.info('utils') { "DEBUG: inside activity_worker. this is my swf region: #{@domain.client.config.simple_workflow_region}" }
    build_activity_worker(@domain, InfraHelperActivity, ACTIVITY_TASKLIST)
  end

  def workflow_worker
    build_workflow_worker(@domain, InfraHelperWorkflow, WF_TASKLIST)
  end

  def workflow_client
    build_workflow_client(@domain, from_class: "InfraHelperWorkflow")
  end
end

