.. _app_demo_slave_sdo_handling:

==================================
EtherCAT SDO Handling Demo (Slave)
==================================

.. contents:: In this document
    :backlinks: none
    :depth: 3


* **Minimum Number of Cores**: 2
* **Minimum Number of Tiles**: 1

.. cssclass:: github

  `See Application on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/master/examples/app_demo_slave_sdo_handling/>`_

Quick How-to
============
1. :ref:`Assemble your SOMANET device <assembling_somanet_node>`.
2. Wire up your device. Check how at your specific :ref:`hardware documentation <hardware>`. power supply cable, and XTAG. Power up!
3. :ref:`Set up your XMOS development tools <getting_started_xmos_dev_tools>`. 
4. Download and :ref:`import in your workspace <getting_started_importing_library>` the SOMANET Motor Control Library and its dependencies.
5. Open the **main.xc** within  the **app_demo_slave_sdo_handling**. Include the :ref:`board-support file according to your device <somanet_board_support_module>`. Also make sure to have an :ref:`appropriate target in your Makefile <somanet_board_support_module>`.
6. :ref:`Run the application.` This application does not provide console outputs.
    It is inteded to be used with :ref:`Demo_Master_Object_Dictionary_Access`_

.. seealso:: Did everything go well? If you need further support please check out our `forum <http://forum.synapticon.com/>`_.

