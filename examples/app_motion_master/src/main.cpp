/**
 * @file main.c
 * @brief Example Master App for Cyclic Synchronous Position (on PC)
 * @author Synapticon GmbH (www.synapticon.com)
 */

#include <thread>
#include <string>
#include <iostream>
#include <unistd.h>
#include "motion_control_protos.pb.h"
#include <google/protobuf/text_format.h>

#include <zmq.hpp>

#include <ctrlproto_m.h>
#include <ecrt.h>
#include <stdio.h>
#include <stdbool.h>
#include <profile.h>
#include <drive_function.h>
#include <motor_define.h>
#include <sys/time.h>
#include <time.h>
#include "ethercat_setup.h"

enum {ECAT_SLAVE_0};

int position = 0;

void server() {
	std::cout << std::endl << "Initializing ZeroMQ connection..." << std::endl;
    
    zmq::context_t context (1);
    zmq::socket_t socket (context, ZMQ_PAIR);

    try {
    	socket.bind("tcp://127.0.0.1:5555");
    } catch (const zmq::error_t& e) {
    	std::cout << e.what() << std::endl;
        exit(1);
    }
    
    std::cout << "ZeroMQ connection established successfully" << std::endl;

    // Server loop
    while (true) {
        zmq::message_t request;

        //  Wait for next request from client
        try {
        	socket.recv (&request);
        } catch (const zmq::error_t& e) {
        	std::cout << "ZeroMQ receive: " << e.what() << std::endl << std::endl;
            exit(1);
        }

     	// Parse the received message into a motion control structure
        com::synapticon::motioncontrolprotos::MotionControl motionControl;
        motionControl.ParseFromArray(request.data(), request.size());

        // Print out the motion control structure
        std::string text_str;
        google::protobuf::TextFormat::PrintToString(motionControl, &text_str);
        std::cout << text_str << std::endl;

        // Set the requested position
        if (motionControl.type() == com::synapticon::motioncontrolprotos::MotionControl_Type_PID) {
            if (motionControl.pid().pid_command() == com::synapticon::motioncontrolprotos::Pid_PidCommand_POSITION_TARGET) {
            	position = motionControl.pid().parameter();
            	std::cout << position << std::endl;
            }
        }
    }
}

int main() {
    int target_position = 32000; // ticks
    int acceleration = 2000; // rpm/s
    int deceleration = 2000; // rpm/s
    int velocity = 2000; // rpm

    int actual_position = 0; // ticks
    int actual_velocity = 0; // rpm
    float actual_torque; // mNm
    int relative_target_position = 0; // ticks
    int steps = 0;
    int position_ramp = 0;
    int direction = 1;
    int n_init_ticks = 3;

    /* Initialize EtherCAT Master */
    init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize torque parameters */
    initialize_torque(ECAT_SLAVE_0, slv_handles);

    /* Initialize all connected nodes with Mandatory Motor Configurations (specified in config)*/
    init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize the node specified with ECAT_SLAVE_0 with CSP configurations (specified in config)*/
    set_operation_mode(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Enable operation of node in CSP mode */
    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Initialize position profile parameters */
    initialize_position_profile_limits(ECAT_SLAVE_0, slv_handles);

    // Start the ZeroMQ server in a separate thread
    std::thread zeroMqServerThread(server);

    /* Getting actual position */
    actual_position = get_position_actual_ticks(ECAT_SLAVE_0, slv_handles);
    printf("our actual position: %i ticks\n",actual_position);

    while(true) {
    	/* Update the process data (EtherCat packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        if (position != 0) {
            if (master_setup.op_flag) { // Check if the master is active
                /* Send target position for the node specified by ECAT_SLAVE_0 */
                set_position_ticks(position, ECAT_SLAVE_0, slv_handles);
                std::cout << "Position set!" << std::endl;
                position = 0;
            }
        }
    }

    printf("\n");

    /* Quick stop position mode (for emergency) */
    quick_stop_position(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Regain control of node to continue after quick stop */
    renable_ctrl_quick_stop(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES); //after quick-stop

    set_operation_mode(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Shutdown node operations */
    shutdown_operation(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    // Wait for the ZeroMQ server thread to finish
    zeroMqServerThread.join();

    return 0;
}

