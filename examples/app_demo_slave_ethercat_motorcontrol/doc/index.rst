.. _ethercat_slave_demo:

==========================================
SOMANET EtherCAT Drive Slave Firmware Demo
==========================================

.. contents:: In this document
    :backlinks: none
    :depth: 3


* **Minimum Number of Cores**: 14
* **Minimum Number of Tiles**: 4

.. cssclass:: github

  `See Application on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/master/examples/app_demo_slave_ethercat_motorcontrol/>`_

Quick How-to
============

1. :ref:`Assemble your SOMANET device <assembling_somanet_node>`.
2. Wire up your device. Check how at your specific :ref:`hardware documentation <hardware>`. Connect your Hall sensor, power supply cable, and XTAG. Power up!
3. :ref:`Set up your XMOS development tools <getting_started_xmos_dev_tools>`. 
4. Download and :ref:`import in your workspace <getting_started_importing_library>` the SOMANET Motor Control Library and its dependencies.
5. Open the **main.xc** within  the **app_test_hall**. Include the :ref:`board-support file according to your device <somanet_board_support_module>`. Also set the :ref:`appropiate target in your Makefile <somanet_board_support_module>`.

.. important:: Make sure the SOMANET Motor Control Library supports your SOMANET device. For that, check the :ref:`Hardware compatibility <motor_control_hw_compatibility>` section of the library.

6. Again in your **main.xc**, set the configuration for your Hall Service. 

    .. code-block:: C

            on tile[IFM_TILE]:
            /* Hall Service */
            {
                HallConfig hall_config;
                hall_config.pole_pairs = 1;

                hall_service(hall_ports, hall_config, i_hall);
            }

    .. note:: Do not worry if you don't know how many pole pairs your motor has. You can always run the application and see on the **console outputs** how many **electrical revolutions** are contained in a mechanical motor revolution. **This number is the number of pole pairs in your motor**.

7. :ref:`Run the application enabling XScope <running_an_application>`.

.. seealso:: Did everything go well? If you need further support please check out our `forum <http://forum.synapticon.com/>`_.
        
