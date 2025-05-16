variable "additional_project_globs" {
  type        = list(string)
  description = "Additional project globs to add to the stack."
  default     = []
}

variable "administrative" {
  type        = bool
  description = "Whether the stack is administrative or not."
  default     = false
}

variable "allow_promotion" {
  type        = bool
  description = "Whether to allow promotion of the stack to the next environment."
  default     = true
}

variable "ansible_playbook" {
  type        = string
  description = "The path to the Ansible playbook to use for the stack."
  default     = null
}

variable "autodeploy" {
  type        = bool
  description = "Whether to auto deploy the stack."
  default     = false
}

variable "autoretry" {
  type        = bool
  description = "Whether to auto retry the stack"
default       = false
}

variable "aws_integration" {
  type = object({
    enabled = bool
    id      = optional(string)
  })
  description = "Spacelift AWS integration configuration"

  default = {
    enabled = false
  }

  validation {
    condition     = var.aws_integration.enabled == false || (var.aws_integration.enabled && var.aws_integration.id != null)
    error_message = "The integration id must be included if aws_entegration is enabled."
  }
}

variable "cloudformation" {
  type = object({
    stack_name          = string
    entry_template_file = string
    region              = string
    template_bucket     = string
  })
  description = "Cloudformation integration configuration"
  default     = null
}

variable "contexts" {
  type        = map(string)
  description = "Contexts to add to the stack."
  default     = {}
}

variable "dependencies" {
  type = map(object({
    parent_stack_id = optional(string)
    child_stack_id  = optional(string)
    references = optional(map(object({
      input_name     = string
      output_name    = string
      trigger_always = optional(bool)
    })))
  }))
  description = "Stack dependencies to add to the stack."
  default     = {}

  validation {
    condition = alltrue(flatten([
      for key, value in var.dependencies : [
        (value.parent_stack_id != null && value.child_stack_id == null) || (value.parent_stack_id == null && value.child_stack_id != null),
      ]
    ]))
    error_message = "You must provide either a parent_stack_id or a child_stack_id, but not both."
  }
}

variable "description" {
  type        = string
  description = "REQUIRED A description to describe your Spacelift stack."
}

variable "drift_detection" {
  type = object({
    enabled      = bool
    schedule     = optional(list(string))
    ignore_state = optional(bool)
    timezone     = optional(string)
    reconcile    = optional(bool)
  })
  description = "Drift detection configuration for stack"

  default = {
    enabled = false
  }

  validation {
    condition     = var.drift_detection.enabled == false || (var.drift_detection.enabled && var.drift_detection.schedule != null)
    error_message = "The schedule must be included if drift detection is enabled"
  }
}

variable "enable_local_preview" {
  type        = bool
  description = "Enable local preview"
  default     = false
}

variable "enable_well_known_secret_masking" {
  type        = bool
  description = "Enable well known secret masking"
  default     = true
}

variable "environment_variables" {
  type = map(object({
    value     = string
    sensitive = optional(bool, false)
  }))
  description = "Environment variables to add to the context."
  default     = {}
}

variable "hooks" {
  type = object({
    before = optional(object({
      init    = optional(list(string))
      plan    = optional(list(string))
      apply   = optional(list(string))
      destroy = optional(list(string))
      perform = optional(list(string))
    }))
    after = optional(object({
      init    = optional(list(string))
      plan    = optional(list(string))
      apply   = optional(list(string))
      destroy = optional(list(string))
      perform = optional(list(string))
    }))
  })
  description = "Hooks to add to the stack."
  default     = {}
}

variable "kubernetes_config" {
  type = object({
    kubectl_version = string
    namespace       = optional(string)
  })
  description = "Kubernetes integration configuration"
  default = {
    kubectl_version = "latest"
    namespace       = null
  }
}

variable "labels" {
  type        = list(string)
  description = "Labels to apply to the stack being created."
  default     = []
}

variable "manage_state" {
  type        = bool
  description = "Should spacelift manage state files"
  default     = true
}

variable "name" {
  type        = string
  description = "REQUIRED The name of the Spacelift stack to create."
}

variable "policies" {
  type        = map(string)
  description = "Policies to add to the stack."
  default     = {}
}

variable "project_root" {
  type        = string
  description = "The path to your project root in your repository to use as the root of the stack. Defaults to root of the repository."
  default     = null
}

variable "protect_from_deletion" {
  type        = bool
  description = "Whether to protect the stack from deletion."
  default     = false
}

variable "pulumi" {
  type = object({
    login_url  = string
    stack_name = string
  })
  description = "config for pulumi in spacelift"
  default = {
    login_url  = null
    stack_name = null
  }
}

variable "repository_branch" {
  type        = string
  description = "The name of the branch to use for the specified Git repository."
  default     = "main"
}

variable "repository_name" {
  type        = string
  description = "REQUIRED The name of the Git repository for the stack to use."
}

variable "runner_image" {
  type        = string
  description = "The runner image to use for the stack. Defaults to the latest version."
  default     = null
}

variable "space_id" {
  type        = string
  description = "REQUIRED The ID of the space this stack will be in."
}

variable "terraform_external_state_access" {
  type        = bool
  description = "Terraform external state access"
  default     = false
}

variable "terraform_smart_sanitization" {
  type        = bool
  description = "Terraform smart sanitization"
  default     = true
}

variable "terragrunt_config" {
  type = object({
    terraform_version    = string
    terragrunt_version   = string
    use_run_all          = optional(bool)
    use_smart_sanitation = optional(bool)
    tool                 = string
  })
  description = "config for terragrunt in spacelift"
  default = {
    terraform_version  = null
    terragrunt_version = null
    tool               = null
  }
}

variable "tf_version" {
  type        = string
  description = "The version of OpenTofu/Terraform for your stack to use. Defaults to latest."
  default     = "latest"
}

variable "tf_workspace" {
  type        = string
  description = "The workspace to use for the stack."
  default     = null
}

variable "vcs" {
  type = object({
    type       = string
    enterprise = optional(bool, false)
    namespace  = optional(string)
    id         = optional(string)
    url        = optional(string)
  })
  description = "VCS integration configuration"
  default = {
    type = "GITHUB"
  }

  validation {
    condition     = var.vcs.type == "BITBUCKET" || var.vcs.type == "GITHUB" || var.vcs.type == "GITLAB" || var.vcs.type == "RAW_GIT"
    error_message = "The vcs.type must be either BITBUCKET, GITLAB, RAW_GIT, or GITHUB."
  }

  validation {
    condition     = ((var.vcs.type == "BITBUCKET" || var.vcs.type == "GITLAB") && var.vcs.namespace != null) || var.vcs.type == "GITHUB" || var.vcs.type == "RAW_GIT"
    error_message = "The vcs.namespace must be included if vcs.type is BITBUCKET or GITLAB."
  }

  validation {
    condition     = (var.vcs.type == "GITHUB" && var.vcs.enterprise && var.vcs.namespace != null) || (var.vcs.type == "GITHUB" && !var.vcs.enterprise) || var.vcs.type == "RAW_GIT" || var.vcs.type == "BITBUCKET" || var.vcs.type == "GITLAB"
    error_message = "The vcs.namespace must be included if vcs.type is GITHUB and vcs.enterprise is true."
  }

  validation {
    condition     = (var.vcs.type == "RAW_GIT" && var.vcs.url != null && var.vcs.namespace != null) || var.vcs.type == "GITHUB" || var.vcs.type == "BITBUCKET" || var.vcs.type == "GITLAB"
    error_message = "The vcs.url and vcs.namespace must be included if vcs.type is RAW_GIT."
  }
}

variable "worker_pool_id" {
  type        = string
  description = "The ID of the worker pool to use for Spacelift stack runs. Defaults to public worker pool."
  default     = null
}

variable "workflow_tool" {
  type        = string
  description = "The workflow tool to use"
  default     = "OPEN_TOFU"

  validation {
    condition     = contains(["TERRAFORM_FOSS", "OPEN_TOFU", "CLOUDFORMATION", "TERRAGRUNT", "ANSIBLE", "KUBERNETES", "PULUMI"], var.workflow_tool)
    error_message = "The workflow tool must be TERRAFORM_FOSS, OPEN_TOFU, CLOUDFORMATION, ANSIBLE, KUBERNETES, PULUMI or TERRAGRUNT."
  }
}
