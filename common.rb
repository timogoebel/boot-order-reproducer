#!/usr/bin/env ruby

# This file contains commonly used helper code

def find_datacenter(vim, datacenter)
  vim.serviceInstance.find_datacenter(datacenter) || abort("datacenter not found")
end

def find_folder(dc, path)
  dc_root_folder = dc.vmFolder
  paths          = path.split('/')
  return dc_root_folder if paths.empty?
  paths.reduce(dc_root_folder) do |last_returned_folder, sub_folder|
    last_returned_folder.find(sub_folder, RbVmomi::VIM::Folder)
  end
end

def get_cluster(dc, name)
  dc.find_compute_resource(name)
end

def get_resource_pool(cluster, rp_name)
  return cluster.resourcePool if rp_name.nil? || rp_name.empty?
  cluster.resourcePool.find(rp_name)
end
