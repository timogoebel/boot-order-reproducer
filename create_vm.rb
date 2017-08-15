#!/usr/bin/env ruby

# This file creates a VM in vSphere with the boot order set.
# This shows that you cannot remove the harddisk via vSphere UI anymore
# as the disk is referenced in the boot order array.
# When deleting this disk, the following error occurs:
# A specified parameter was not correct: "configSpec.bootOptions.bootOrder".

require 'rbvmomi'
require './settings.rb'
require './common.rb'

vm_name = 'bootorder-reproducer.example.com'
#datastore = 'datastore1'
datastore = 'LX_ESX_V7000_RZ2_06'

vim = RbVmomi::VIM.connect(
  host: SETTINGS[:host],
  user: SETTINGS[:user],
  password: SETTINGS[:password],
  insecure: true
)

dc = find_datacenter(vim, SETTINGS[:datacenter])
cluster = get_cluster(dc, SETTINGS[:cluster])
resourcePool = get_resource_pool(cluster, SETTINGS[:resourcePool])
vmFolder = find_folder(dc, SETTINGS[:folder])

vm_cfg = {
  :name => vm_name,
  :guestId => 'otherGuest',
  :files => { :vmPathName => "[#{datastore}]" },
  :numCPUs => 1,
  :memoryMB => 128,
  :deviceChange => [
    {
      :operation => :add,
      :device => RbVmomi::VIM.VirtualLsiLogicController(
        :key => 1000,
        :busNumber => 0,
        :sharedBus => :noSharing
      )
    },
    {
      :operation => :add,
      :fileOperation => :create,
      :device => RbVmomi::VIM.VirtualDisk(
        :key => 0,
        :backing => RbVmomi::VIM.VirtualDiskFlatVer2BackingInfo(
          :fileName => "[#{datastore}]",
          :diskMode => :persistent,
          :thinProvisioned => true
        ),
        :controllerKey => 1000,
        :unitNumber => 0,
        :capacityInKB => 4000000
      )
    },
  ],
  # This is the problematic setting
  :bootOptions => RbVmomi::VIM::VirtualMachineBootOptions.new({
    :bootOrder => [
      RbVmomi::VIM::VirtualMachineBootOptionsBootableDiskDevice.new(
        :deviceKey => 2000
      )
    ]
  })
}

task = vmFolder.CreateVM_Task(:config => vm_cfg, :pool => resourcePool)
puts 'Creating VM...'

result = task.wait_for_progress do |progress|
  puts "Progress: #{progress}%" if progress
end

puts "Created VM: #{result.name}"
puts "This VM shows, that you cannot delete the harddisk in the vSphere GUI without getting an error."
