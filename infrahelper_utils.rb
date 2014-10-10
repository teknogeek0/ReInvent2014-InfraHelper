require_relative '../../utils'

class InfraHelperUtils
  include SharedUtils

  WF_VERSION = "1.0"
  ACTIVITY_VERSION = "1.0"
  WF_TASKLIST = "infrahelper_workflow_task_list"
  ACTIVITY_TASKLIST = "infrahelper_activity_task_list"
  DOMAIN = "ReInvent2014"

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

