require_relative 'infrahelper_utils.rb'

class InfraHelperActivity
 extend AWS::Flow::Activities 



end

# Start an ActivityWorker to work on the InfraHelperActivity tasks
InfraHelperUtils.new.activity_worker.start if $0 == __FILE__
