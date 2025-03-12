Install Terraform (>=1.0)
Configure Azure CLI (az login)
Install Azure DevOps Terraform Provider
Generate a GitHub personal access token (PAT) with repo and admin:repo_hook permissions

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~>1.0"
    }
    github = {
      source  = "integrations/github"
      version = "~>5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/YOUR_ORG"
  personal_access_token = var.azure_devops_pat
}

provider "github" {
  token = var.github_token
}

# Variables
variable "resource_group_name" {
  default = "rg-devops-github"
}

variable "location" {
  default = "East US"
}

variable "project_name" {
  default = "GitHub-Terraform-Demo"
}

variable "github_repo_name" {
  default = "terraform-azure-github-project"
}

variable "github_org" {
  default = "YOUR_GITHUB_ORG"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  sensitive   = true
}

variable "azure_devops_pat" {
  description = "Azure DevOps Personal Access Token"
  sensitive   = true
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Azure DevOps Project
resource "azuredevops_project" "project" {
  name               = var.project_name
  description        = "Terraform-managed Azure DevOps project"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

# Create GitHub Repository
resource "github_repository" "repo" {
  name        = var.github_repo_name
  description = "Terraform-managed GitHub repo for Azure DevOps integration"
  visibility  = "public"
  auto_init   = true
}

# Create a Service Connection to GitHub in Azure DevOps
resource "azuredevops_serviceendpoint_github" "github_connection" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "GitHub Connection"
  description           = "Service connection for GitHub repository"
  auth_personal {
    personal_access_token = var.github_token
  }
}

# Link Azure DevOps Project to GitHub Repo
resource "azuredevops_repository" "repo_link" {
  project_id  = azuredevops_project.project.id
  repository  = github_repository.repo.full_name
  service_endpoint_id = azuredevops_serviceendpoint_github.github_connection.id
  type        = "GitHub"
}
