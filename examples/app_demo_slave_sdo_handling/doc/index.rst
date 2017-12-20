.. _app_demo_slave_sdo_handling:

==================================
EtherCAT SDO Handling Demo (Slave)
==================================

.. contents:: In this document
    :backlinks: none
    :depth: 3


* **Minimum Number of Cores**: 2
* **Minimum Number of Tiles**: 1

Quick How-to
============
1. :ref:`Assemble your SOMANET device <assembling_somanet_node>`.
2. Wire up your device. Check how at your specific :ref:`hardware documentation <hardware>`. power supply cable, and XTAG. Power up!
3. :ref:`Set up your XMOS development tools <getting_started_xmos_dev_tools>`. 
4. Download and :ref:`import in your workspace <getting_started_importing_library>` the SOMANET Motor Control Library and its dependencies.
5. Open the **main.xc** within  the **app_demo_slave_sdo_handling**. Include the :ref:`board-support file according to your device <somanet_board_support_module>`. Also make sure to have an :ref:`appropriate target in your Makefile <somanet_board_support_module>`.
6. While editing **main.xc** you can choose which SDO example you want to run. Currently you can choose betweeen default demo and entry value monitoring demo. To choose the demo just modify the lines ::

    #define SDO_SERVICE_DEFAULT     1
    #define SDO_SERVICE_MONITOR     2
    #define SDO_SERVICE             SDO_SERVICE_DEFAULT

The value of ``SDO_SERVICE`` defines which demo to run.
7. :ref:`Run the application.` This application does not provide console outputs.
   If the ``SDO_SERVICE_DEFAULT`` is used the master application should be used :ref:`Demo Master Object Dictionary Access <Demo_Master_Object_Dictionary_Access>`
   This master demo performs simple object dictionary test (e.g. reading and writing the object).
   If the ``SDO_SERVICE_MONITOR`` is compiled and run you can see on the
   console how many values actually changed and if one changed the entry index
   and subindex is printed with the current value in this entry. A output could look like this if rapid changes happen::

      Entries updated: 2
      Object changed: 0x2002
      :0
      Value: 10
      Entries updated: 2
      Object changed: 0x5000
      :0
      Value: 1
      Entries updated: 1
      Object changed: 0x2002
      :0
      Value: 15


.. seealso:: Did everything go well? If you need further support please check out our `forum <http://forum.synapticon.com/>`_.

