.. _app_demo_master_pdo_handling:

===================================
EtherCAT PDO Handling Demo (Master)
===================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

Connect the motor and cables to your kit.

Run the application
+++++++++++++++++++

When the application has been compiled (just execute make), the next step is to run it on the Linux PC. Before doing that, make sure that the SOMANET EtherCAT stack is running a proper software for the EtherCAT slave side, i.e. ``app_demo_slave_pdo_handling``.  

   #. Make sure your EtherCAT Master is up and running. To start the Master on a Linux machine, execute the following command: ::

       sudo /etc/init.d/ethercat start

   #. Make sure your SOMANET node is accessible by the EtherCAT master by typing: ::

        ethercat slave 

      The output should indicate a presence of the SOMANET node and pre-operational state if the slave side software is running: ::

        0  0:0  PREOP  +  SNCN SOMANET COM ECAT

   #. Navigate with the terminal to your compiled application binary on the hard disk. Then execute the application with super user rights: ::

       sudo ./app_demo_master_pdo_handling

