.. _app_demo_master_pdo_handling:

===================================
EtherCAT PDO Handling Demo (Master)
===================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

.. cssclass:: github

  `See Application on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/master/examples/app_demo_master_pdo_handling/>`_

   Connecting the motor and cables to your kit

Build the application
+++++++++++++++++++++
The application is build as usual with ::

  make

The application is build in the ``bin/`` subfolder.

Please make sure the latest Synapticon EtherCAT Master is installed and
functional, see :ref:`IgH EtherLab to be installed <ethercat_master_software_linux>`
in at least version 1.5.2-sncn-4


Run the application
+++++++++++++++++++

When the application has been compiled (just execute make), the next step is to
run it on the Linux PC. Before doing that, make sure that the SOMANET EtherCAT
stack is running a proper software for the EtherCAT slave side, i.e.
:ref:`EtherCAT PDO Handling Demo (Slave) <app_demo_slave_pdo_handling>`.

   #. Make sure your EtherCAT Master is up and running. To start the Master on a Linux machine, execute the following command: ::

       sudo /etc/init.d/ethercat start

   #. Make sure your SOMANET node is accessible by the EtherCAT master by typing: ::

        ethercat slave 

      The output should indicate a presence of the SOMANET node and pre-operational state if the slave side software is running: ::

        0  0:0  PREOP  +  CiA402 Drive

   #. Navigate with the terminal to your compiled application binary on the hard disk. Then execute the application with super user rights: ::

       sudo ./bin/app_demo_master_pdo_handling

The application provides the following command line arguments

  - ``-h``             print this help and exit
  - ``-n slave``       slave number, default to 0
  - ``-d``             print domain registry before start
  - ``-w``             enable graphical output

Running the application with ``-w`` shows a table with the send and received
values of the PDO entries. The values are changed automatically according
theire data type.

The option ``-d`` is primary for debug and gives the current domain registration
of the PDO values.
