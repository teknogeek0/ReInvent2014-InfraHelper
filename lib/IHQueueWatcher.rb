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
require_relative '../infrahelper_utils'

## load from config our environment variables
##CONFIG = YAML.load_file("IHQueueConfig.yml") unless defined? CONFIG

## create new SQS client
sqs = AWS::SQS.new(:region=> "sqs.#{CONFIG['Region']}.amazonaws.com")
## connect to our queue, if not, fail out.
begin
  queue = sqs.queues["#{CONFIG['IHQueue']}"]
rescue AWS::SQS::Errors::InvalidParameterValue => e
  logger.error('queuewatcher') { "Invalid queue name '#{CONFIG['IHQueue']}'. "+e.message }
  exit 1
end

logger.info('queuewatcher') { "Starting to poll for new events from queue: '#{CONFIG['IHQueue']}'" }
queue.poll() do |msg|
	##if here we have a message, lets now parse it
	sns_msg = msg.as_sns_message
	parsed_msg = JSON.parse(sns_msg.to_h[:body])
	
	myEvent = parsed_msg["Event"]

	case myEvent
		when "autoscaling:EC2_INSTANCE_LAUNCH","autoscaling:EC2_INSTANCE_TERMINATE"
			#get the other variables we'll need from the parsed msg
			myASG = parsed_msg["AutoScalingGroupName"]
			myInstance = parsed_msg["EC2InstanceId"]
	  	logger.info('queuewatcher') { "Found event: '#{CONFIG['myEvent']}' in AutoScalign Group:'#{CONFIG['myASG']}' affecting instance: '#{CONFIG['myInstance']}'" }

	  	if !myASG.empty? && !myInstance.empty?
	  		##now lets start our workflow
				InfraHelperUtils.new.workflow_client.start_execution(
					myEvent: myEvent,
					myASG: myASG,
					myInstance: myInstance
				)
				logger.info('queuewatcher') { "Workflow initiated" }
			else
				logger.error('queuewatcher') { "Something has gone wrong. Didn't find an ASG or instance as part of this message." }
	  	end
		when "autoscaling:EC2_INSTANCE_LAUNCH_ERROR","autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
			#log that we got an error performing an action
			logger.error('queuewatcher') { "RUH ROH. We got an error doing the following: '#{CONFIG['myEvent']}'." }
		when " autoscaling:TEST_NOTIFICATION "
			#this is just a test, so we don't really care
			logger.info('queuewatcher') { "This is a test of the new autoscaling notifcation SNS to SQS setup. Good work!" }
		else
			#assume an error here
			logger.error('queuewatcher') { "Something else went wrong here. Either we couldn't parse a message properly or who knows!" }
	end
end

