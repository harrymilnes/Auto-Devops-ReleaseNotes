terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "resource-group" {
  name     = "resource-group"
  location = "UK South"
}

resource "azurerm_log_analytics_workspace" "analytics-workspace" {
  name                = "workspace-test-milnes"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "application-insights" {
  name                = "appinsights-test-milnes"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  workspace_id        = azurerm_log_analytics_workspace.analytics-workspace.id
  application_type    = "web"
}


resource "azurerm_app_service_plan" "service-plan" {
  name                = "service-plan"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  kind                = "FunctionApp"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_storage_account" "release-notes-storage" {
  name                     = "releasenotessto"
  resource_group_name      = azurerm_resource_group.resource-group.name
  location                 = azurerm_resource_group.resource-group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "release-notes-container" {
  name                  = "release-notes"
  storage_account_name  = azurerm_storage_account.release-notes-storage.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "api-func-storage" {
  name                     = "rnapifuncsto"
  resource_group_name      = azurerm_resource_group.resource-group.name
  location                 = azurerm_resource_group.resource-group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "api-func" {
  name                       = "hm-rna-api-func"
  location                   = azurerm_resource_group.resource-group.location
  resource_group_name        = azurerm_resource_group.resource-group.name
  app_service_plan_id        = azurerm_app_service_plan.service-plan.id
  storage_account_name       = azurerm_storage_account.api-func-storage.name
  storage_account_access_key = azurerm_storage_account.api-func-storage.primary_access_key

  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION" = "3"
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
    "ReleaseNotesAzureWebStorage" = azurerm_storage_account.release-notes-storage.primary_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application-insights.instrumentation_key
  }
}