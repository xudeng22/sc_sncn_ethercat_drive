.. _Demo_Master_Object_Dictionary_Access:

Demo Master Object Dictionary Access
====================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

This linux application tests and demonstrates the access to the object
dictionary from a linux master. After startup a automatic test which reads the
object dictionary from the selected slave and tests the accessability of
read/write and read only objects.

.. cssclass:: github

 `See Application on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/develop/examples/app_demo_master_object_dictionary>`_

Prerequisites
+++++++++++++

  * :ref:`IgH EtherLab to be installed <ethercat_master_software_linux>` in at least version 1.5.2-sncn-4
  * :ref:`app_demo_slave_sdo_handling`

To compile this application simply type ::

  make

You can find the resulting binary in the newly created `bin/` folder.

Usage
+++++

The applicatin accepts various command line arguments. With `-h` a short
overview of the available options are available.

All the options in detail are:

  * `-h` a short list of the available objects
  * `-l` show a list of all connected slaves and exit
  * `-m <index>` select the master with numerical index (value range:  0 .. n), if more than one master is available (default: 0)
  * `-n <index>` select the slave to use for testing (index rage: 0 .. n) (default: 0)
  * `-c` experimental function to start cyclic operation after the object dictionary is read

.. important:: The command line parameter `-c` is only useable if :ref:`app_demo_slave_sdo_handling` is running on the slave module!

Examples
--------

If you run the application without any options the master 0 and slave 0 is used. All other master and devices are ignored ::

  ./bin/app_demo_master_object_dictionary

To get a list of all slaves which are connected to the master run ::

  ./bin/app_demo_master_object_dictionary -l

If there is more than one slave active on the bus and you want to request the 4th device you run ::

  ./bin/app_demo_master_object_dictionary -n 3

Since the device enumeration starts with 0 the 4th device has the index 3.

To access the second slave on the second master you have to run the application with ::

  ./bin/app_demo_master_object_dictionary -m 1 -n 2

Like the devices the index of the available masters start at 0.
