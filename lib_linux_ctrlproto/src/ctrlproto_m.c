/**
 * @file ctrlproto_m.c
 * @author Synapticon GmbH <support@synapticon.com>
*/

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdarg.h>
#include <ctrlproto_m.h>
#include <canod.h>
#include <ecrt.h>




// Application parameters
#define PRIORITY 	1


/****************************************************************************/

/* application global definitions */
static int g_dbglvl = 1;

// Timer
static unsigned int sig_alarms = 0;
static unsigned int user_alarms = 0;

/****************************************************************************/


/*****************************************************************************/

static void logmsg(int lvl, const char *format, ...);

/*****************************************************************************/

void check_domain1_state(master_setup_variables_t *master_setup)
{
    ec_domain_state_t ds;

    ecrt_domain_state(master_setup->domain, &ds);

    if (ds.working_counter != master_setup->domain_state.working_counter)
        logmsg(1, "Domain1: WC %u.\n", ds.working_counter);
    if (ds.wc_state != master_setup->domain_state.wc_state)
    	logmsg(1, "Domain1: State %u.\n", ds.wc_state);

    	master_setup->domain_state = ds;
}

/****************************************************************************/

void check_master_state(master_setup_variables_t *master_setup)
{
    ec_master_state_t ms;

    ecrt_master_state(master_setup->master, &ms);

    if (ms.slaves_responding != master_setup->master_state.slaves_responding)
        logmsg(1, "%u slave(s).\n", ms.slaves_responding);
    if (ms.al_states != master_setup->master_state.al_states)
        logmsg(1, "AL states: 0x%02X.\n", ms.al_states);
    if (ms.link_up != master_setup->master_state.link_up)
        logmsg(1, "Link is %s.\n", ms.link_up ? "up" : "down");

    master_setup->master_state = ms;
}

/****************************************************************************/

/*
void check_slave_config_states(void)
{
    ec_slave_config_state_t s;

    ecrt_slave_config_state(sc_data_in, &s);

    if (s.al_state != sc_data_in_state.al_state)
        logmsg(1, "AnaIn: State 0x%02X.\n", s.al_state);
    if (s.online != sc_data_in_state.online)
        logmsg(1, "AnaIn: %s.\n", s.online ? "online" : "offline");
    if (s.operational != sc_data_in_state.operational)
        logmsg(1, "AnaIn: %soperational.\n",
                s.operational ? "" : "Not ");

    sc_data_in_state = s;
}
 */

/****************************************************************************/

/*
 * Access SDOs during cyclic operation (in real time context)
 *
 * First create the object ec_sdo_request_t and then schedule the master send
 * the SDO request.
 */

int read_sdo(ec_sdo_request_t *req)
{
	int sdo_read_value = 0;
    switch (ecrt_sdo_request_state(req)) {
        case EC_REQUEST_UNUSED: // request was not used yet
            ecrt_sdo_request_read(req); // trigger first read
            break;
        case EC_REQUEST_BUSY:
            //fprintf(stderr, "SDO still busy...\n");
            break;
        case EC_REQUEST_SUCCESS:
        	sdo_read_value = EC_READ_S32(ecrt_sdo_request_data(req));
            //logmsg(1, "SDO value read: 0x%X\n", sdo_read_value);
            ecrt_sdo_request_write(req); // trigger next write
            break;
        case EC_REQUEST_ERROR:
            //fprintf(stderr, "Failed to read SDO!\n");
            ecrt_sdo_request_read(req); // retry reading
            break;
    }
    return sdo_read_value;
}

int write_sdo(ec_sdo_request_t *req, unsigned data)
{
	EC_WRITE_S32(ecrt_sdo_request_data(req), data&0xffffffff);

	switch (ecrt_sdo_request_state(req)) {
		case EC_REQUEST_UNUSED: // request was not used yet
			ecrt_sdo_request_write(req); // trigger first read
			break;
		case EC_REQUEST_BUSY:
			//fprintf(stderr, "SDO write still busy...\n");
			//logmsg(1, "SDO value written: \n",data );
			pause();
			break;
		case EC_REQUEST_SUCCESS:
			//logmsg(1, "SDO value written: 0x%X\n", data);
			pause();
			ecrt_sdo_request_read(req); // trigger next read
			return 1;
			break;
		case EC_REQUEST_ERROR:
			fprintf(stderr, "Failed to write SDO!\n");
			ecrt_sdo_request_write(req); // retry writing
			return 0;
			break;
	}

	return 0;
}

/****************************************************************************/

static motor_config sdo_motor_config_update(master_setup_variables_t *master_setup, int slave_number, motor_config motor_config_param, sdo_entries_t *request[]);

void sdo_write_configuration(master_setup_variables_t *master_setup,
        ctrlproto_slv_handle *slv_handles,
        int update_sequence, int slave_number)
{
    (void)update_sequence; /* FIXME silence compiler for now TODO remove from API */

    slv_handles[slave_number].motor_config_param = \
            sdo_motor_config_update(master_setup, slave_number, slv_handles[slave_number].motor_config_param, \
                    slv_handles[slave_number].sdo_entries);

}

#if MAKE_TIME_MEASUREMENT == 0
#include <time.h>

static double calc_mean(double mean, double current)
{
	static unsigned int counter = 0;
	double K = 1.0 / ( counter + 1);
	double new = mean + K * (current - mean);
	counter++;

	return new;
}

struct timespec timespec_diff(struct timespec *start, struct timespec *end)
{
	struct timespec temp;

	if ( (end->tv_nsec - start->tv_nsec) < 0) {
		temp.tv_sec = end->tv_sec - start->tv_sec - 1;
		temp.tv_nsec = 1000000000 + end->tv_nsec - start->tv_nsec;
	} else {
		temp.tv_sec = end->tv_sec - start->tv_sec;
		temp.tv_nsec = end->tv_nsec - start->tv_nsec;
	}

	return temp;
}
#endif /* MAKE_TIME_MEASUREMENT */

void pdo_handle_ecat(master_setup_variables_t *master_setup,
        ctrlproto_slv_handle *slv_handles,
        unsigned int total_no_of_slaves)
{
	unsigned int slv;

#if MAKE_TIME_MEASUREMENT == 1
	static struct timespec g_timer = { 0, 0 };
	static double mean = 0.0;
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	struct timespec tdiff = timespec_diff(&g_timer, &ts);
	mean = calc_mean(mean, (1.0 * tdiff.tv_nsec));
	printf("[%s] time diff %ld ns (%.2f ns)\n", __func__,  tdiff.tv_nsec, mean);
	g_timer.tv_nsec = ts.tv_nsec;
#endif /* MAKE_TIME_MEASUREMENT */

	if(sig_alarms == user_alarms) pause();
	while (sig_alarms != user_alarms)
	{
		/* sync the dc clock of the slaves */
		//	ecrt_master_sync_slave_clocks(master);

		// receive process data
		ecrt_master_receive(master_setup->master);
		ecrt_domain_process(master_setup->domain);

		// check process data state (optional)
		//check_domain1_state(master_setup);

		// check for master state (optional)
		//check_master_state(master_setup);

		// check for islave configuration state(s) (optional)
		// check_slave_config_states();


		for(slv=0;slv<total_no_of_slaves;++slv)
		{
			/* Read process data */
			slv_handles[slv].motorctrl_status_in = EC_READ_U16(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[0]);
			slv_handles[slv].operation_mode_disp = EC_READ_U8(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[1]);
			slv_handles[slv].position_in = EC_READ_U32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[2]);
			slv_handles[slv].speed_in = EC_READ_U32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[3]);
			slv_handles[slv].torque_in = EC_READ_U16(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[4]);
			/* Read user PDOs */
			slv_handles[slv].user1_in = EC_READ_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[5]);
			slv_handles[slv].user2_in = EC_READ_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[6]);
			slv_handles[slv].user3_in = EC_READ_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[7]);
			slv_handles[slv].user4_in = EC_READ_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_in[8]);
		}

/*		printf("\n%x", 	slv_handles[slv].motorctrl_status_in);
		printf("\n%x",  slv_handles[slv].operation_mode_disp);
		printf("\n%x",  slv_handles[slv].position_in);
		printf("\n%x",  slv_handles[slv].speed_in);
		printf("\n%x",  slv_handles[slv].torque_in);
*/

		for(slv=0;slv<total_no_of_slaves;++slv)
		{
			EC_WRITE_U16(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[0], (slv_handles[slv].motorctrl_out)&0xffff);
			EC_WRITE_U8(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[1], (slv_handles[slv].operation_mode)&0xff);
			EC_WRITE_U16(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[2], (slv_handles[slv].torque_setpoint)&0xffff);
			EC_WRITE_U32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[3], slv_handles[slv].position_setpoint);
			EC_WRITE_U32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[4], slv_handles[slv].speed_setpoint);
			/* Write user PDOs */
			EC_WRITE_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[5], slv_handles[slv].user1_out);
			EC_WRITE_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[6], slv_handles[slv].user2_out);
			EC_WRITE_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[7], slv_handles[slv].user3_out);
			EC_WRITE_S32(master_setup->domain_pd + slv_handles[slv].__ecat_slave_out[8], slv_handles[slv].user4_out);
		}

		// send process data
		ecrt_domain_queue(master_setup->domain);
		ecrt_master_send(master_setup->master);

		//Check for master und domain state
		ecrt_master_state(master_setup->master, &master_setup->master_state);
		ecrt_domain_state(master_setup->domain, &master_setup->domain_state);

		if (master_setup->domain_state.wc_state == EC_WC_COMPLETE && !master_setup->op_flag)
		{
			//printf("System up!\n");
			master_setup->op_flag = 1;
		}
		else
		{
			if(master_setup->domain_state.wc_state != EC_WC_COMPLETE && master_setup->op_flag)
			{
				//printf("System down!\n");
				master_setup->op_flag = 0;
			}
		}

		user_alarms++;
	}
}
/****************************************************************************/

void signal_handler(int signum) {
    switch (signum) {
        case SIGALRM:
            sig_alarms++;
            break;
    }
}

/****************************************************************************/

static void logmsg(int lvl, const char *format, ...)
{
	if (lvl > g_dbglvl)
		return;

	va_list ap;
	va_start(ap, format);
	vprintf(format, ap);
	va_end(ap);
}



void motor_config_request(ec_slave_config_t *slave_config, sdo_entries_t *request[]);

void init_master(master_setup_variables_t *master_setup, ctrlproto_slv_handle *slv_handles, unsigned int total_no_of_slaves)
{
    unsigned int slv;

    master_setup->master = ecrt_request_master(0);
    if (!master_setup->master)
        exit(-1);

    master_setup->domain = ecrt_master_create_domain(master_setup->master);
    if (!master_setup->domain)
        exit(-1);

	for (slv = 0; slv < total_no_of_slaves; ++slv)
	{
		if (!( slv_handles[slv].slave_config = ecrt_master_slave_config(   //sc_data_in
						master_setup->master, slv_handles[slv].slave_alias, slv_handles[slv].slave_pos , slv_handles[slv].slave_vendorid, slv_handles[slv].slave_productid))) {
			fprintf(stderr, "Failed to get slave configuration.\n");
			exit(-1);
		}

		//logmsg(1, "Configuring PDOs...\n");
		if (ecrt_slave_config_pdos(slv_handles[slv].slave_config, EC_END, slv_handles[slv].__sync_info)) { //slave_0_syncs
		  fprintf(stderr, "Failed to configure PDOs.\n");
		  exit(-1);
		}

	//#if PARAMETER_UPDATE
		motor_config_request(slv_handles[slv].slave_config, slv_handles[slv].sdo_entries);
	//#endif
	}

    if (ecrt_domain_reg_pdo_entry_list(master_setup->domain, master_setup->domain_regs)) {
        fprintf(stderr, "PDO entry registration failed!\n");
        exit(-1);
    }

	if (ecrt_master_set_send_interval(master_setup->master, FREQUENCY) != 0) {
		fprintf(stderr, "failed to set send interval\n");
		exit(-1);
	}

    logmsg(0, "Master configured, about to configure slaves\n");
}

void master_activate_operation(master_setup_variables_t *master_setup)
{
    struct sigaction sa;
    struct itimerval tv;


    logmsg(1, "Activating master...\n");
    if (ecrt_master_activate(master_setup->master))
        exit(-1);

    if (!(master_setup->domain_pd = ecrt_domain_data(master_setup->domain))) {
        exit(-1);
    }
    pid_t pid = getpid();
    if (setpriority(PRIO_PROCESS, pid, -19))
        fprintf(stderr, "Warning: Failed to set priority: %s\n",
                strerror(errno));

    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    if (sigaction(SIGALRM, &sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }

    //logmsg(1, "Starting timer...\n");
    tv.it_interval.tv_sec = 0;
    tv.it_interval.tv_usec = 1000000 / FREQUENCY;
    tv.it_value.tv_sec = 0;
    tv.it_value.tv_usec = 1000;
    if (setitimer(ITIMER_REAL, &tv, NULL)) {
        fprintf(stderr, "Failed to start timer: %s\n", strerror(errno));
        exit(-1);
    }

    logmsg(0, "Started.\n");
}

/****************************************************************************/
sdo_entries_t* _config_sdo_request(ec_slave_config_t *slave_config, sdo_entries_t *request, int index, int sub_index, int bytes)
{
    request = malloc(sizeof(sdo_entries_t));
    request->slave_config = slave_config;
    request->index = index;
    request->subindex = sub_index;
    request->bytecount = bytes;

	return request;
}

void motor_config_request(ec_slave_config_t *slave_config, sdo_entries_t *request[])
{
	request[0] = _config_sdo_request(slave_config, request[0], CIA402_GEAR_RATIO, 0, 2);
	request[1] = _config_sdo_request(slave_config, request[1], CIA402_MAX_ACCELERATION, 0, 4);
	request[2] = _config_sdo_request(slave_config, request[2], CIA402_MOTOR_SPECIFIC, 1, 4);  //nominal current
	request[3] = _config_sdo_request(slave_config, request[3], CIA402_MOTOR_SPECIFIC, 4, 4);	//nominal speed
	request[4] = _config_sdo_request(slave_config, request[4], CIA402_POLARITY, 0, 4);
	request[5] = _config_sdo_request(slave_config, request[5], CIA402_MOTOR_SPECIFIC, 3, 4);  //pole pairs
	request[6] = _config_sdo_request(slave_config, request[6], CIA402_POSITION_ENC_RESOLUTION, 0, 2);
	request[7] = _config_sdo_request(slave_config, request[7], CIA402_SENSOR_SELECTION_CODE, 0, 2);

	request[8] = _config_sdo_request(slave_config, request[8], CIA402_VELOCITY_GAIN, 1, 4);
	request[9] = _config_sdo_request(slave_config, request[9], CIA402_VELOCITY_GAIN, 2, 4);
	request[10] = _config_sdo_request(slave_config, request[10], CIA402_VELOCITY_GAIN, 3, 4);

	request[11] = _config_sdo_request(slave_config, request[11], CIA402_POSITION_GAIN, 1, 4);
	request[12] = _config_sdo_request(slave_config, request[12], CIA402_POSITION_GAIN, 2, 4);
	request[13] = _config_sdo_request(slave_config, request[13], CIA402_POSITION_GAIN, 3, 4);

	request[14] = _config_sdo_request(slave_config, request[14], CIA402_SOFTWARE_POSITION_LIMIT, 1, 4); //min
	request[15] = _config_sdo_request(slave_config, request[15], CIA402_SOFTWARE_POSITION_LIMIT, 2, 4); // max

	request[16] = _config_sdo_request(slave_config, request[16], CIA402_MAX_PROFILE_VELOCITY, 0, 4);
	request[17] = _config_sdo_request(slave_config, request[17], CIA402_PROFILE_VELOCITY, 0, 4);
	request[18] = _config_sdo_request(slave_config, request[18], CIA402_PROFILE_ACCELERATION, 0, 4);
	request[19] = _config_sdo_request(slave_config, request[19], CIA402_PROFILE_DECELERATION, 0, 4);
	request[20] = _config_sdo_request(slave_config, request[20], CIA402_QUICK_STOP_DECELERATION, 0, 4);

	request[21] = _config_sdo_request(slave_config, request[21], CIA402_MOTOR_SPECIFIC, 6, 4); //motor torque constant
	request[22] = _config_sdo_request(slave_config, request[22], CIA402_MAX_TORQUE, 0, 4);
	request[23] = _config_sdo_request(slave_config, request[23], CIA402_TORQUE_SLOPE, 0, 4);

	request[24] = _config_sdo_request(slave_config, request[24], CIA402_CURRENT_GAIN, 1, 4);
	request[25] = _config_sdo_request(slave_config, request[25], CIA402_CURRENT_GAIN, 2, 4);
	request[26] = _config_sdo_request(slave_config, request[26], CIA402_CURRENT_GAIN, 3, 4);

	request[27] = _config_sdo_request(slave_config, request[27], COMMUTATION_OFFSET_CLKWISE, 0, 2);
	request[28] = _config_sdo_request(slave_config, request[28], COMMUTATION_OFFSET_CCLKWISE, 0, 2);
	request[29] = _config_sdo_request(slave_config, request[29], MOTOR_WINDING_TYPE, 0, 1);

	request[30] = _config_sdo_request(slave_config, request[30], CIA402_HOMING_METHOD, 0, 1);
	request[31] = _config_sdo_request(slave_config, request[31], LIMIT_SWITCH_TYPE, 0, 1);
	request[32] = _config_sdo_request(slave_config, request[32], SENSOR_POLARITY, 0, 2);

}

int _motor_config_update(ec_sdo_request_t *request, int update, int value, int sequence)
{
    int sdo_update_value;
    if(update==0)
    {
        write_sdo(request, value);
        sdo_update_value = read_sdo(request);
        if(sdo_update_value == value)
        {
            update = 1;
            printf("%d ", sequence);
            fflush(stdout);
        }
    }
    return update;
}

/* Write the configuration to the slave and check if the download was successfull.
 * FIXME rename parameters to make more sense.
 */
static int sdo_download(ec_master_t *master, int slave_number, sdo_entries_t *request, uint32_t value)
{
    uint32_t abort_code = 0;
    uint8_t *val_ptr = (uint8_t *)(&value);

    ecrt_master_sdo_download(master, slave_number, request->index, request->subindex, val_ptr, request->bytecount, &abort_code);

    if (abort_code != 0) {
        fprintf(stderr, "ERROR %s: could not download to object: 0x%04x ... giving up\n", __func__, request->index);
        return -1;
    }

    /* Test if the value is transfered correctly */
    uint8_t result[4] = { 0 }; /* max of 4 byte words supported */
    size_t result_size = 4;
    size_t read_size = 0;

    ecrt_master_sdo_upload(master, slave_number, request->index, request->subindex, result, result_size, &read_size, &abort_code);

    if (abort_code != 0) {
        fprintf(stderr, "ERROR %s: could not upload object: 0x%04x ... abort code %d\n", __func__, request->index, abort_code);
        return -1;
    }

    uint32_t *r = (uint32_t *)result;
    if (*r != value) {
        fprintf(stderr, "ERROR %s: set object 0x%04x failed!\n", __func__, request->index);
        fprintf(stderr,      "expected %d - received after send %d\n", value, *r);
        return -1;
    }

    return 0;
}

static motor_config sdo_motor_config_update(master_setup_variables_t *master_setup, int slave_number, motor_config motor_config_param, sdo_entries_t *request[])
{
    sdo_download(master_setup->master, slave_number, request[0],  motor_config_param.s_gear_ratio.gear_ratio);
    sdo_download(master_setup->master, slave_number, request[1],  motor_config_param.s_max_acceleration.max_acceleration);
    sdo_download(master_setup->master, slave_number, request[5],  motor_config_param.s_pole_pair.pole_pair);
    sdo_download(master_setup->master, slave_number, request[6],  motor_config_param.s_position_encoder_resolution.position_encoder_resolution);
    sdo_download(master_setup->master, slave_number, request[7],  motor_config_param.s_sensor_selection_code.sensor_selection_code);
    sdo_download(master_setup->master, slave_number, request[4],  motor_config_param.s_polarity.polarity);
    sdo_download(master_setup->master, slave_number, request[21], motor_config_param.s_motor_torque_constant.motor_torque_constant);
    sdo_download(master_setup->master, slave_number, request[3],  motor_config_param.s_nominal_motor_speed.nominal_motor_speed);
    sdo_download(master_setup->master, slave_number, request[27], motor_config_param.s_commutation_offset_clk.commutation_offset_clk);
    sdo_download(master_setup->master, slave_number, request[28], motor_config_param.s_commutation_offset_cclk.commutation_offset_cclk);
    sdo_download(master_setup->master, slave_number, request[29], motor_config_param.s_motor_winding_type.motor_winding_type);
    sdo_download(master_setup->master, slave_number, request[31], motor_config_param.s_limit_switch_type.limit_switch_type);
    sdo_download(master_setup->master, slave_number, request[30], motor_config_param.s_homing_method.homing_method);
    sdo_download(master_setup->master, slave_number, request[14], motor_config_param.s_software_position_min.software_position_min);
    sdo_download(master_setup->master, slave_number, request[15], motor_config_param.s_software_position_max.software_position_max);
    sdo_download(master_setup->master, slave_number, request[32], motor_config_param.s_sensor_polarity.sensor_polarity);
    sdo_download(master_setup->master, slave_number, request[22], motor_config_param.s_max_torque.max_torque);
    sdo_download(master_setup->master, slave_number, request[2],  motor_config_param.s_nominal_current.nominal_current);
    sdo_download(master_setup->master, slave_number, request[24], motor_config_param.s_torque_p_gain.p_gain);
    sdo_download(master_setup->master, slave_number, request[25], motor_config_param.s_torque_i_gain.i_gain);
    sdo_download(master_setup->master, slave_number, request[26], motor_config_param.s_torque_d_gain.d_gain);
    sdo_download(master_setup->master, slave_number, request[8],  motor_config_param.s_velocity_p_gain.p_gain);
    sdo_download(master_setup->master, slave_number, request[9],  motor_config_param.s_velocity_i_gain.i_gain);
    sdo_download(master_setup->master, slave_number, request[10], motor_config_param.s_velocity_d_gain.d_gain);
    sdo_download(master_setup->master, slave_number, request[11], motor_config_param.s_position_p_gain.p_gain);
    sdo_download(master_setup->master, slave_number, request[12], motor_config_param.s_position_i_gain.i_gain);
    sdo_download(master_setup->master, slave_number, request[13], motor_config_param.s_position_d_gain.d_gain);
    sdo_download(master_setup->master, slave_number, request[23], motor_config_param.s_torque_slope.torque_slope);
    sdo_download(master_setup->master, slave_number, request[16], motor_config_param.s_max_profile_velocity.max_profile_velocity);
    sdo_download(master_setup->master, slave_number, request[20], motor_config_param.s_quick_stop_deceleration.quick_stop_deceleration);
    sdo_download(master_setup->master, slave_number, request[18], motor_config_param.s_profile_acceleration.profile_acceleration);
    sdo_download(master_setup->master, slave_number, request[19], motor_config_param.s_profile_deceleration.profile_deceleration);
    sdo_download(master_setup->master, slave_number, request[16], motor_config_param.s_max_profile_velocity.max_profile_velocity);
    sdo_download(master_setup->master, slave_number, request[17], motor_config_param.s_profile_velocity.profile_velocity);
    sdo_download(master_setup->master, slave_number, request[18], motor_config_param.s_profile_acceleration.profile_acceleration);
    sdo_download(master_setup->master, slave_number, request[19], motor_config_param.s_profile_deceleration.profile_deceleration);
    sdo_download(master_setup->master, slave_number, request[20], motor_config_param.s_quick_stop_deceleration.quick_stop_deceleration);

    return motor_config_param;
}


