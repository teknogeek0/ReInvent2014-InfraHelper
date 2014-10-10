require_relative 'infrahelper_activity'
require_relative '../infrahelper_utils'

class InfraHelperWorkflow
  extend AWS::Flow::Workflows


end

# Start a WorkflowWorker to work on the InfraHelperWorkflow tasks
InfraHelperUtils.new.workflow_worker.start if $0 == __FILE__
