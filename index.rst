SOMANET EtherCAT Drive
======================

.. toctree::
	:maxdepth: 1
	:hidden:

	EtherCAT Drive Module <module_ethercat_drive/doc/index>	
	Communication Protocol Library for Linux <lib_linux_ctrlproto/doc/index>	
	Motor Drive Library for Linux <lib_linux_motor_drive/doc/index>	

The **SOMANET EtherCAT Drive Library** offers the services and utilities required to perform BLDC/BDC Motor Control over EtherCAT using SOMANET devices.
It implements a CiA 402-compliant Motor Control protocol that gathers all the functionalities offered by the **SOMANET Motor Control Library** and gives 
flexibility for application-specific requirements.

Minimum Hardware requirements: 
- 1x SOMANET **COM**,.
- 1x SOMANET **Core**.
- 1x SOMANET **IFM**.
Hardware Compatibility:
- SOMANET COM: **EtherCAT**.
- SOMANET Core: **C22**.
- SOMANET IFM: **DC 100**, **DC 300**, **DC 1000**, **DC 5000**.


.. cssclass:: downloadable-button 

  `Download Library <https://github.com/synapticon/sc_sncn_ethercat_drive/archive/master.zip>`_

.. cssclass:: github

  `Visit Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/>`_

Modules
-------

.. toctree::
	:maxdepth: 1
	:hidden:

	EtherCAT Drive Module <module_ethercat_drive/doc/index>



Examples
--------

.. toctree::
	:hidden:
	:maxdepth: 1

	EtherCAT Drive Slave Firmware <examples/app_demo_slave_ethercat_motorcontrol/doc_quickstart/quickstart>
	
	EtherCAT Cyclic Position Control Demo <examples/app_demo_master_cyclic_position/doc_quickstart/quickstart>
	EtherCAT Cyclic Velocity Control Demo <examples/app_demo_master_cyclic_velocity/doc_quickstart/quickstart>
	EtherCAT Cyclic Torque Control Demo <examples/app_demo_master_cyclic_torque/doc_quickstart/quickstart>

	EtherCAT Profile Position Control Demo <examples/app_demo_master_profile_position/doc/index>
	EtherCAT Profile Velocity Control Demo <examples/app_demo_master_profile_velocity/doc/index>
	EtherCAT Profile Torque Control Demo <examples/app_demo_master_profile_torque/doc/index>

	EtherCAT Multi-node Cyclic Position Control Demo <examples/app_demo_master_cyclic_position_2_nodes/doc_quickstart/quickstart>
	EtherCAT Multi-node Cyclic Velocity Control Demo <examples/app_demo_master_cyclic_velocity_2_nodes/doc_quickstart/quickstart>
	EtherCAT Multi-node Cyclic Torque Control Demo <examples/app_demo_master_cyclic_torque_2_nodes/doc_quickstart/quickstart>

* **Slave examples (for SOMANET devices):**

        * `EtherCAT Drive Slave Firmware <app_demo_slave_ethercat_motorcontrol/doc_quickstart/quickstart>`_: Ethercat Drive slave firmware for your SOMANET device.


* **Master examples (for Linux machines):**

	* `EtherCAT Cyclic Position Control Demo <examples/app_demo_master_cyclic_position/doc_quickstart/quickstart>`_: Example to do cyclic position control on one axis over EtherCAT.
	* `EtherCAT Cyclic Velocity Control Demo <examples/app_demo_master_cyclic_velocity/doc_quickstart/quickstart>`_: Example to do cyclic velocity control on one axis over EtherCAT.
	* `EtherCAT Cyclic Torque Control Demo <examples/app_demo_master_cyclic_torque/doc_quickstart/quickstart>`_: Example to do cyclic torque control on one axis over EtherCAT.

	* `EtherCAT dual-node Cyclic Position Control Demo <examples/app_demo_master_cyclic_position_2_nodes/doc_quickstart/quickstart>`_: Example to do cyclic position control on two axis over EtherCAT.
	* `EtherCAT dual-node Cyclic Velocity Control Demo <examples/app_demo_master_cyclic_velocity_2_nodes/doc_quickstart/quickstart>`_: Example to do cyclic velocity control on two axis over EtherCAT.

	* `EtherCAT dual-node Cyclic Torque Control Demo <examples/app_demo_master_cyclic_torque_2_nodes/doc_quickstart/quickstart>`_: Example to do cyclic torque control on two axis over EtherCAT.

	* `EtherCAT Profile Position Control Demo <examples/app_demo_master_profile_position/doc/index>`_: Example to generate position ramps and control one axis over EtherCAT.
	* `EtherCAT Profile Velocity Control Demo <examples/app_demo_master_profile_velocity/doc/index>`_: Example to generate velocity ramps and control one axis over EtherCAT.
	* `EtherCAT Profile Torque Control Demo <examples/app_demo_master_profile_torque/doc/index>`_: Example to generate torque ramps and control one axis over EtherCAT.

Quick Guides
------------



Dependencies
------------

To run **Ethercat Drive applications** it is neccesary to include additionally the following libraries:

* :ref:`SOMANET Motor Control <somanet_motor_control>`

	.. cssclass:: downloadable-button 

	 `Download SOMANET Motor Control Library <https://github.com/synapticon/sc_sncn_motorcontrol/archive/master.zip>`_

	.. cssclass:: github

	  `Visit SOMANET Motor Control Public Repository <https://github.com/synapticon/sc_sncn_motorcontrol>`_

* :ref:`SOMANET EtherCAT <somanet_ethercat>`

	.. cssclass:: downloadable-button 

	 `Download SOMANET EtherCAT Library  <https://github.com/synapticon/sc_sncn_ethercat/archive/master.zip>`_

	.. cssclass:: github

	  `Visit SOMANET EtherCAT Public Repository <https://github.com/synapticon/sc_sncn_ethercat>`_

* :ref:`SOMANET Base <somanet_base>`

	.. cssclass:: downloadable-button 

	  `Download SOMANET Base Library <https://github.com/synapticon/sc_somanet-base/archive/master.zip>`_

	.. cssclass:: github

	  `Visit SOMANET Base Public Repository <https://github.com/synapticon/sc_somanet-base>`_


.. important:: To be able to **run** Ethercat Drive Master applications in your Linux machine, you first have to install all necessary **drivers**.
	
	Visit our :ref:`IgH EtherCAT Master for Linux Documentation <ethercat_master_software_linux>` for further information. 
