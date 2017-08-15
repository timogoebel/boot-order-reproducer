#!/usr/bin/env ruby

# This file creates a Template from a VM.

require 'rbvmomi'
require './settings.rb'
require './common.rb'

vm_name = 'bootorder-reproducer.example.com'

vim = RbVmomi::VIM.connect(
  host: SETTINGS[:host],
  user: SETTINGS[:user],
  password: SETTINGS[:password],
  insecure: true
)

dc = find_datacenter(vim, SETTINGS[:datacenter])
vm = dc.find_vm(SETTINGS[:folder] + '/' + vm_name) || fail('VM not found')

if vm.config.template
  puts "VM #{vm.name} is already marked as a template."
  exit 1
else
  vm.MarkAsTemplate!
  puts "Marked vm #{vm.name} as Template."
end
