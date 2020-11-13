terraform {
  required_providers {
    netapp-cloudmanager = {
      source = "NetApp/netapp-cloudmanager"
      version = "20.10.0"
    }
  }
}

resource "netapp-cloudmanager_connector_aws" "cm-aws" {
  provider = netapp-cloudmanager
  name = "TF-ConnectorAWS"
  region = "us-east-1"
  key_name = "automation_key"
  company = "NetApp"
  instance_type = "t3.xlarge"
  subnet_id = "subnet-xxxxxx"
  security_group_id = "sg-xxxxxxx"
  iam_instance_profile_name = "occm"
  account_id = "account-XXXXXXX" #Cloud Mgr Account #
}

resource "netapp-cloudmanager_cvo_aws" "cvo-aws" {
  provider = netapp-cloudmanager
  name = "TerraformCVO1"
  region = "us-east-1"
  subnet_id = "subnet-xxxxxxxx"
  vpc_id = "vpc-xxxxxxxx"
  capacity_tier = "NONE"
  aws_tag {
              tag_key = "NAME"
              tag_value = "CVOTF"
            }
  svm_password = "testX123"
  client_id = netapp-cloudmanager_connector_aws.cm-aws.client_id 
}

resource "netapp-cloudmanager_aggregate" "cvo-aggregate" {
  provider = netapp-cloudmanager
  name = "aggr2"
  working_environment_id = netapp-cloudmanager_cvo_aws.cvo-aws.id 
  client_id = netapp-cloudmanager_connector_aws.cm-aws.client_id
  capacity_tier = "NONE"
  number_of_disks = 1
  provider_volume_type = "gp2"
  disk_size_size = 100
  disk_size_unit = "GB"
}

resource "netapp-cloudmanager_cifs_server" "cvo-cifs-workgroup" {
   depends_on = [netapp-cloudmanager_aggregate.cvo-aggregate]
   provider = netapp-cloudmanager
   server_name = "server"
   workgroup_name  = "workgroup"
   client_id = netapp-cloudmanager_connector_aws.cm-aws.client_id 
   working_environment_name = "TerraformCVO1"
   is_workgroup = true
}

resource "netapp-cloudmanager_volume" "cifs-volume-1" {
  depends_on = [netapp-cloudmanager_cifs_server.cvo-cifs-workgroup]
  provider = netapp-cloudmanager
  name = "cifs_test_vol_1"
  volume_protocol = "cifs"
  provider_volume_type = "gp2"
  size = 10
  unit = "GB"
  share_name = "share_cifs"
  permission = "full_control"
  users = ["Everyone"]
  working_environment_name = "TerraformCVO1"
  client_id = netapp-cloudmanager_connector_aws.cm-aws.client_id 
  capacity_tier= "none"
}
