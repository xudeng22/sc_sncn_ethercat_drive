SOMANET EtherCAT Software Package
=================================

:Latest release: 1.1.3
:Maintainer: Synapticon
:Description: Top level applications and demonstrations for the SOMANET Motion Control Kit


Key features
------------

   * EtherCAT Slave Controller Demos
   * EtherCAT Master Controller Demos
   * CiA 402 device profile for drives and motion control compliance

Firmware overview
-----------------

The Package includes a collection of Motor Control applications that can be used together with the SOMANET/XMOS EtherCAT evaluation kit. Applications having the word master included into their names are meant to be running on a Linux host PC that has an EtherCAT driver from EtherLab installed. Applications having only slave word in their names can run standalone and do not require an EtherCAT communication. 

Known Issues
------------

none

Support
-------

Issues may be submitted via the Issues tab in this GitHub repository. Response to any issues submitted is at the discretion of the maintainer for this line.

Documentation
=============
`Extensive documentation`_

.. _Extensive documentation: http://85.214.233.250:90/codedocs/develop/sw_sncn_motorcontrol_ethercat_kit/index.html

Required software (dependencies)
================================

  * sc_pwm (https://github.com/synapticon/sc_pwm.git)
  * sc_sncn_motorcontrol (https://github.com/synapticon/sc_sncn_motorcontrol.git)
  * sc_somanet-base (git@github.com:djpwilk/sc_somanet-base.git)
  * sc_sncn_ethercat (git@github.com:synapticon/sc_sncn_ethercat.git)
  * sc_sncn_ctrlproto (https://github.com/synapticon/sc_sncn_ctrlproto.git)

