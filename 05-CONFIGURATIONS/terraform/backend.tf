terraform {
  backend "s3" {
    bucket         = "mantis-agentic-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mantis-state-lock" # Bloqueo concurrente
    encrypt        = true                # C5: Cifrado en reposo
  }
}
