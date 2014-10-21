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
require_relative '../infrahelper_utils.rb'

class InfraHelperActivity
 extend AWS::Flow::Activities 

  AWS.config({region: "#{$CONFIG['Region']}"})

	# The activity method is used to define activities. It accepts a list of names
  # of activities and a block specifying registration options for those
  # activities
  activity :assignEIP, :setSrcDest, :setRoute do
    {
      version: InfraHelperUtils::ACTIVITY_VERSION,
      default_task_list: InfraHelperUtils::ACTIVITY_TASKLIST,
      default_task_schedule_to_start_timeout: 30,
      default_task_start_to_close_timeout: 30
    }
  end

  # This activity can be used to assign an EIP to an instance
  def assignEIP(myInstance)
  	$logger.info('assignEIP_activity') { "Assigning an EIP to instance ID: #{myInstance}" }
  	instance = ec2.instances[myInstance]

    eips = ec2.elastic_ips.select{|ip| !ip.associated? and ip.vpc?}
    if eips.empty?
      $logger.info('assignEIP_activity') { "No free VPC EIPs found, creating one." }
      eip = ec2.elastic_ips.create(:vpc => true)
      assocEIP(eip, instance)
    else
      eips.each do |ips|
        $logger.info('assignEIP_activity') { "Found a free VPC EIPs found, associating it to our instance." }
        assocEIP(ips, instance)
        break
      end
    end
  	$logger.info('assignEIP_activity') { "Finished activity" }
  end

  # This activity can be used to set the SRC/DEST flag
  def setSrcDest(myInstance)
    $logger.info('setSrcDest_activity') { "Setting SRC/DEST for instance ID: #{myInstance}" }
    ec2.instances[myInstance].source_dest_check = false
    if !ec2.instances[myInstance].source_dest_check
      $logger.info('setSrcDest_activity') { "Finished activity" }
    else
      ## should probably write smarter failure stuff...
      $logger.info('setSrcDest_activity') { "FAILED activity" }
    end
  end

  # This activity can be used to set the instance as the default route for a route table
  def setRoute(options)
  	routeEndPoint = options[:myInstance]
  	group = ec2.auto_scaling.groups[options[:myASG]]
		group.ec2_instances.each do |instance|
  		puts instance.id
  		## we'll do something useful here
		end
    $logger.info('setRoute_activity') { "Set instance as default route for RouteTable: #{routeEndPoint}" }
    ##assume something is happening here
  	$logger.info('setRoute_activity') { "Finished activity" }
  end

  def ec2
    # Initialize the S3 client if it's not already initialized
    @ec2 ||= AWS::EC2.new
  end

  def assocEIP(eip, instance)
    instance.associate_elastic_ip(eip)
    if eip.associated?
      $logger.info('assignEIP_activity') { "Successfully assigned EIP: #{eip} to Instance: #{instance}" }
    end
  end

end

# Start an ActivityWorker to work on the InfraHelperActivity tasks
InfraHelperUtils.new.activity_worker.start if $0 == __FILE__
$logger.info('activities') { "Starting our activity process against SWF Domain: '#{$IH_CONFIG["domain"]["name"]}'" }