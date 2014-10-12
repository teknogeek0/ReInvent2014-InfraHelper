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
require_relative 'infrahelper_utils.rb'

class InfraHelperActivity
 extend AWS::Flow::Activities 

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
    puts "Assigning an EIP to instance ID: #{myInstance}\n"
  end

  # This activity can be used to set the SRC/DEST flag
  def setSrcDest(myInstance)
    puts "Setting SRC/DEST for instance ID: #{myInstance}\n"
  end

  # This activity can be used to set the instance as the default route for a route table
  def setRoute(myASG, myInstance)
    puts "Set instance as default route for RouteTable: #{customer_id}\n"
  end

end

# Start an ActivityWorker to work on the InfraHelperActivity tasks
InfraHelperUtils.new.activity_worker.start if $0 == __FILE__
