locals {
  is_tf_tool        = var.workflow_tool == "OPEN_TOFU" || var.workflow_tool == "TERRAFORM_FOSS"
  is_terragrunt     = var.workflow_tool == "TERRAGRUNT"
  is_cloudformation = var.workflow_tool == "CLOUDFORMATION"
  is_ansible        = var.workflow_tool == "ANSIBLE"
  is_kubernetes     = var.workflow_tool == "KUBERNETES"
  is_pulumi         = var.workflow_tool == "PULUMI"

  is_latest_tf_tool = local.is_tf_tool && var.tf_version == "latest"
  tf_version        = local.is_latest_tf_tool ? data.spacelift_tool_versions.latest["TERRAFORM"].versions[0] : (local.is_tf_tool ? var.tf_version : null)

  is_latest_k8s_tool = local.is_kubernetes && var.kubernetes_config.kubectl_version == "latest"
  k8s_version        = local.is_latest_k8s_tool ? data.spacelift_tool_versions.k8s_latest["KUBERNETES"].versions[0] : (local.is_kubernetes ? var.kubernetes_config.kubectl_version : null)

  hooks = {
    before = {
      init    = try(var.hooks.before.init, [])
      plan    = try(var.hooks.before.plan, [])
      apply   = try(var.hooks.before.apply, [])
      destroy = try(var.hooks.before.destroy, [])
      perform = try(var.hooks.before.perform, [])
    }
    after = {
      init    = try(var.hooks.after.init, [])
      plan    = try(var.hooks.after.plan, [])
      apply   = try(var.hooks.after.apply, [])
      destroy = try(var.hooks.after.destroy, [])
      perform = try(var.hooks.after.perform, [])
    }
  }

}

data "spacelift_tool_versions" "latest" {
  for_each = local.is_latest_tf_tool ? toset(["TERRAFORM"]) : toset([])

  tool = var.workflow_tool
}

data "spacelift_tool_versions" "k8s_latest" {
  for_each = local.is_latest_k8s_tool ? toset(["KUBERNETES"]) : toset([])

  tool = "KUBECTL"
}

resource "spacelift_stack" "this" {
  name                     = var.name
  repository               = var.repository_name
  branch                   = var.repository_branch
  description              = var.description
  terraform_version        = local.tf_version
  worker_pool_id           = var.worker_pool_id
  project_root             = var.project_root
  labels                   = var.labels
  enable_local_preview     = var.enable_local_preview
  enable_well_known_secret_masking = var.enable_well_known_secret_masking
  autodeploy               = var.autodeploy
  autoretry                = var.autoretry
  manage_state             = var.manage_state
  terraform_workflow_tool  = local.is_tf_tool ? var.workflow_tool : null
  space_id                 = var.space_id
  runner_image             = var.runner_image
  github_action_deploy     = var.allow_promotion
  terraform_workspace      = var.tf_workspace
  additional_project_globs = var.additional_project_globs
  protect_from_deletion    = var.protect_from_deletion

  administrative = var.administrative

  terraform_external_state_access = var.terraform_external_state_access
  terraform_smart_sanitization = var.terraform_smart_sanitization

  before_init    = local.hooks.before.init
  before_plan    = local.hooks.before.plan
  before_apply   = local.hooks.before.apply
  before_destroy = local.hooks.before.destroy
  before_perform = local.hooks.before.perform
  after_init     = local.hooks.after.init
  after_plan     = local.hooks.after.plan
  after_apply    = local.hooks.after.apply
  after_destroy  = local.hooks.after.destroy
  after_perform  = local.hooks.after.perform

  dynamic "pulumi" {
    for_each = local.is_pulumi ? ["PULUMI"] : []

    content {
      login_url  = var.pulumi.login_url
      stack_name = var.pulumi.stack_name
    }
  }

  dynamic "terragrunt" {
    for_each = local.is_terragrunt ? ["TERRAGRUNT"] : []

    content {
      terragrunt_version     = var.terragrunt_config.terragrunt_version
      terraform_version      = var.terragrunt_config.terraform_version
      use_run_all            = var.terragrunt_config.use_run_all
      use_smart_sanitization = var.terragrunt_config.use_smart_sanitation
      tool                   = var.terragrunt_config.tool
    }
  }

  dynamic "bitbucket_cloud" {
    for_each = (var.vcs.type == "BITBUCKET" && !var.vcs.enterprise) || (var.vcs.type == "BITBUCKET" && var.vcs.enterprise == null) ? ["BITBUCKET"] : []

    content {
      namespace = var.vcs.namespace
      id        = var.vcs.id
    }
  }

  dynamic "bitbucket_datacenter" {
    for_each = var.vcs.type == "BITBUCKET" && var.vcs.enterprise != null && var.vcs.enterprise ? ["BITBUCKET"] : []

    content {
      namespace = var.vcs.namespace
      id        = var.vcs.id
    }
  }

  dynamic "github_enterprise" {
    for_each = var.vcs.type == "GITHUB" && var.vcs.enterprise != null && var.vcs.enterprise ? ["GITHUB"] : []

    content {
      namespace = var.vcs.namespace
      id        = var.vcs.id
    }
  }

  dynamic "gitlab" {
    for_each = var.vcs.type == "GITLAB" ? ["GITLAB"] : []

    content {
      namespace = var.vcs.namespace
      id        = var.vcs.id
    }
  }

  dynamic "raw_git" {
    for_each = var.vcs.type == "RAW_GIT" ? ["RAW_GIT"] : []

    content {
      namespace = var.vcs.namespace
      url       = var.vcs.url
    }
  }

  dynamic "cloudformation" {
    for_each = local.is_cloudformation ? ["CLOUDFORMATION"] : []

    content {
      stack_name          = var.cloudformation.stack_name
      entry_template_file = var.cloudformation.entry_template_file
      region              = var.cloudformation.region
      template_bucket     = var.cloudformation.template_bucket
    }
  }

  dynamic "ansible" {
    for_each = local.is_ansible ? ["ANSIBLE"] : []

    content {
      playbook = var.ansible_playbook
    }
  }

  dynamic "kubernetes" {
    for_each = local.is_kubernetes ? ["KUBERNETES"] : []

    content {
      kubectl_version = local.k8s_version
      namespace       = var.kubernetes_config.namespace
    }
  }

}

resource "spacelift_aws_integration_attachment" "this" {
  count = var.aws_integration.enabled ? 1 : 0

  integration_id = var.aws_integration.id
  stack_id       = spacelift_stack.this.id
  read           = true
  write          = true
}

resource "spacelift_environment_variable" "this" {
  for_each = var.environment_variables

  stack_id   = spacelift_stack.this.id
  name       = each.key
  value      = each.value.value
  write_only = each.value.sensitive
}

resource "spacelift_policy_attachment" "this" {
  for_each = var.policies

  policy_id = each.value
  stack_id  = spacelift_stack.this.id
}

resource "spacelift_context_attachment" "this" {
  for_each = var.contexts

  context_id = each.value
  stack_id   = spacelift_stack.this.id
}

locals {
  references_list = flatten([
    for key, value in var.dependencies : [
      for reference_key, reference in value.references : {
        reference_key       = reference_key
        stack_dependency_id = key
        input_name          = reference.input_name
        output_name         = reference.output_name
        trigger_always      = coalesce(reference.trigger_always, false)
      }
    ] if value.references != null
  ])

  references = {
    for key, reference in local.references_list : "${reference.stack_dependency_id}_${reference.reference_key}" => reference
  }
}

resource "spacelift_stack_dependency" "this" {
  for_each = var.dependencies

  stack_id            = each.value.child_stack_id != null ? each.value.child_stack_id : spacelift_stack.this.id
  depends_on_stack_id = each.value.parent_stack_id != null ? each.value.parent_stack_id : spacelift_stack.this.id
}

resource "spacelift_stack_dependency_reference" "this" {
  for_each = local.references

  stack_dependency_id = spacelift_stack_dependency.this[each.value.stack_dependency_id].id
  input_name          = each.value.input_name
  output_name         = each.value.output_name
  trigger_always      = each.value.trigger_always
}

resource "spacelift_drift_detection" "this" {
  for_each = var.drift_detection.enabled ? toset(["ENABLED"]) : toset([])

  stack_id     = spacelift_stack.this.id
  schedule     = var.drift_detection.schedule
  reconcile    = var.drift_detection.reconcile
  timezone     = var.drift_detection.timezone
  ignore_state = var.drift_detection.ignore_state
}
