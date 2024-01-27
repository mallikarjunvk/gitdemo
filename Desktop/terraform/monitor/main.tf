terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.0.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_monitor_action_group" "mallu_AG" {
  name                = "mallu_AG"
  resource_group_name = "${var.resource_group}"
  short_name = "email"

  email_receiver {
    name     = "sendmail"
    email_address = "vkmallikarjun@gmail.com"
  }
  tags = {
    env = "dev"
    purpose = "test"
  }
}

resource "azurerm_monitor_metric_alert" "mallu_ALERT" {
  name                = "mallu_ALERT"
  resource_group_name = "${var.resource_group}"
#   scopes              = ["/subscriptions/d8f91232-3cb0-4b1c-9a92-e0a39a04dbfa/resourceGroups/WEB-SERVER_GROUP/providers/Microsoft.Compute/virtualMachines/WEB-SERVER"]  # Replace with your VM resource ID
    scopes              = ["/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Compute/virtualMachines/${var.vm_name}"]
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 85
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage Memory"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 85
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Data Disk I/O Percentage"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 95
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "OS Disk I/O Percentage"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.mallu_AG.id
  }
}