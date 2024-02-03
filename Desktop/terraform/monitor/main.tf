terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.8.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  virtual_machines = jsondecode(file("input.json")) 

  vm_rg_map = merge([
    for vm in local.virtual_machines :
    {
      for vm_name in vm.VMName :
      vm_name => vm.ResourceGroup
    }
  ]...)
  tags = {
    uai = "${var.uai}"
    env = "${var.env}"
    appname = "${var.appname}"
    buss = "${var.buss}"
  }
}

output "vm_rg_map_output" {
  value = local.vm_rg_map
}


data "azurerm_virtual_machine" "vms" {
  for_each = local.vm_rg_map

  name                = each.key
  resource_group_name = each.value
}

output "virtual_machine_info" {
  description = "Information about Azure Virtual Machines"

  value = {
    for vm_name, vm_data in data.azurerm_virtual_machine.vms :
    vm_name => {
      resource_group = vm_data.resource_group_name
      vm_name        = vm_data.name
    }
  }
}

resource "azurerm_monitor_action_group" "mallu_AG" {
  name                = "${var.buss}_${var.appname}_${var.env}_AG"
  resource_group_name = "${var.rg}"
  short_name = "mallu_AG"

  dynamic "email_receiver" {
    for_each = var.email_id

    content {
      name          = "sendmail_${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "vm_availibility" {
  for_each = local.vm_rg_map
  name                = "${var.buss}_${var.appname}_${var.env}_${each.key}_VM_AVAILABILITY"
  resource_group_name = each.value
  scopes              = [data.azurerm_virtual_machine.vms[each.key].id]
  description         = "Alerts for VM Availibility/CPU/IOPS DATA/IOPS OS"
  tags = local.tags
    criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.mallu_AG.id
  }
}


resource "azurerm_monitor_metric_alert" "cpu_percentage" {
  for_each = local.vm_rg_map
  name                = "${var.buss}_${var.appname}_${var.env}_${each.key}_CPU_PERCANTAGE"
  resource_group_name = each.value
  scopes              = [data.azurerm_virtual_machine.vms[each.key].id]
  description         = "Alerts for Percentage CPU"
  tags = local.tags
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 85
  }
  action {
    action_group_id = azurerm_monitor_action_group.mallu_AG.id
  }
}

resource "azurerm_monitor_metric_alert" "memory_percantage" {
  for_each = local.vm_rg_map
  name                = "${var.buss}_${var.appname}_${var.env}_${each.key}_MEMORY_PERCENTAGE"
  resource_group_name = each.value
  scopes              = [data.azurerm_virtual_machine.vms[each.key].id]
  description         = "Alerts for Percentage CPU"
  tags = local.tags
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 85
  }
  action {
    action_group_id = azurerm_monitor_action_group.mallu_AG.id
  }
}

resource "azurerm_monitor_metric_alert" "data_disk" {
  for_each = local.vm_rg_map
  name                = "${var.buss}_${var.appname}_${var.env}_${each.key}_DATA_DISKIO_PERCENTAGE"
  resource_group_name = each.value
  scopes              = [data.azurerm_virtual_machine.vms[each.key].id]
  description         = "Alerts for Percentage CPU"
  tags = local.tags
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Data Disk IOPS Consumed Percentage"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 90
  }
  action {
    action_group_id = azurerm_monitor_action_group.mallu_AG.id
  }
}

resource "azurerm_monitor_metric_alert" "os_disk" {
  for_each = local.vm_rg_map
  name                = "${var.buss}_${var.appname}_${var.env}_${each.key}_OS_DISKIO_PERCENTAGE"
  resource_group_name = each.value
  scopes              = [data.azurerm_virtual_machine.vms[each.key].id]
  description         = "Alerts for Percentage CPU"
  tags = local.tags
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "OS Disk IOPS Consumed Percentage"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 90
  }
  action {
    action_group_id = azurerm_monitor_action_group.mallu_AG.id
  }
}