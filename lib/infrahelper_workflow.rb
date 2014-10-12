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

require_relative 'infrahelper_activity'
require_relative '../infrahelper_utils'

class InfraHelperWorkflow
  extend AWS::Flow::Workflows

	# Use the workflow method to define workflow entry point.
  workflow :fix_NAT do
    {
      version: InfraHelperUtils::WF_VERSION,
      default_task_list: InfraHelperUtils::WF_TASKLIST,
      default_execution_start_to_close_timeout: 120
    }
  end

  # Create an activity client using the activity_client method to schedule
  # activities
  activity_client(:client) { { from_class: "InfraHelperActivity" } }

  # This is the entry point for the workflow
  def fix_NAT options

    puts "Workflow has started\n" unless is_replaying?
    # This array will hold all futures that are created when asynchronous
    # activities are scheduled
    futures = []

    if options[:myEvent]=="autoscaling:EC2_INSTANCE_LAUNCH"
      puts "Reserving a car for customer\n" unless is_replaying?
      # The activity client can be used to schedule activities
      # asynchronously by using the send_async method
      futures << client.send_async(:assignEIP, options[:myInstance])
      futures << client.send_async(:setSrcDest, options[:myInstance])
      futures << client.send_async(:setRoute, options[:myASG, :myInstance])
    elsif options[:myEvent]=="autoscaling:EC2_INSTANCE_TERMINATE"
      puts "Reserving air ticket\n" unless is_replaying?
      futures << client.send_async(:setRoute, options[:myASG, :myInstance])
    end

    puts "Waiting for activities to complete\n" unless is_replaying?
    # wait_for_all is a flow construct that will wait on the array of
    # futures passed to it
    wait_for_all(futures)

    puts "Workflow has completed\n" unless is_replaying?
  end

  # Helper method to check if Flow is replaying the workflow. This is used to
  # avoid duplicate log messages
  def is_replaying?
    decision_context.workflow_clock.replaying
  end

end

# Start a WorkflowWorker to work on the InfraHelperWorkflow tasks
InfraHelperUtils.new.workflow_worker.start if $0 == __FILE__
