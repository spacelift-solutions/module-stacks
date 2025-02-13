module "ec2_worker_pool_stack" {
  source = "spacelift.io/spacelift-solutions/stacks-module/spacelift"

  name                  = "worker-pool-stack"
  description           = "Stack to create a worker pool"
  repository_name       = "spacelift"
  repository_branch     = "main"
  project_root          = "aws/ecs-worker-pool"
  labels                = ["worker-pool", "example"]
  manage_state          = true
  protect_from_deletion = true

  autodeploy     = true
  autoretry      = true

  enable_local_preview = true
  enable_well_known_secret_masking = true

  terraform_external_state_access = false
  terraform_smart_sanitization    = true

  administrative  = true
  allow_promotion = true
  tf_version      = "1.7.1"
  tf_workspace    = "worker-pool"
  workflow_tool   = "OPEN_TOFU"

  runner_image = "public.ecr.aws/spacelift/runner-terraform"

  vcs = {
    type       = "GITHUB"
    enterprise = false
    id         = "my-github-integration-id"
    namespace  = "my-namespace"
    url        = "my-url"

  }

  cloudformation = {
    stack_name          = "worker-pool"
    entry_template_file = "cloudformation/worker-pool.yml"
    region              = "us-west-2"
    template_bucket     = "my-template-bucket"
  }

  kubernetes_config = {
    kubectl_version = "latest"
    namespace       = "default"
  }

  terragrunt_config = {
    terragrunt_version   = "0.66.3"
    terraform_version    = "1.8.1"
    use_run_all          = true
    use_smart_sanitation = true
    tool                 = "OPEN_TOFU"
  }

  additional_project_globs = [
    "modules/spacelift/worker-pool/**/*"
  ]

  environment_variables = {
    TF_VAR_worker_pool_config = {
      sensitive = true
      value = jsonencode({
        token       = spacelift_worker_pool.this.config
        private_key = base64encode(tls_private_key.this.private_key_pem)
      })
    }
  }

  policies = {
    MY_AWESOME_PUSH_POLICY = spacelift_policy.this.id
  }

  contexts = {
    MY_AWESOME_CONTEXT = spacelift.context.id
  }

  dependencies = {
    MY_AWESOME_STACK = {
      child_stack_id = spacelift_stack.this.id

      references = {
        INPUT_1 = {
          input_name  = "INPUT_NAME_1"
          output_name = "OUTPUT_NAME_1"
        },
        INPUT_2 = {
          input_name     = "INPUT_NAME_2"
          output_name    = "OUTPUT_NAME_2"
          trigger_always = true
        },
      }
    }

    MY_OTHER_AWESOME_STACK = {
      dependent_stack_id = spacelift_stack.this.id
    }
  }

  hooks = {
    after = {
      apply = [
        "ls -lah"
      ]
    },
    before = {
      plan = [
        "echo 'Hello, World!'"
      ]
    }
  }

  worker_pool_id = spacelift_worker_pool.this.id
  space_id       = spacelift_space.aws.id
  aws_integration = {
    enabled = true
    id      = spacelift_aws_integration.work.id
  }

  drift_detection = {
    enabled      = true
    schedule     = ["*/15 * * * *"]
    reconcile    = true
    ignore_state = false
    timezone     = "UTC"
  }
}
