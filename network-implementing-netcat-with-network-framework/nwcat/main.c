/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
nwcat is a basic version of the standard netcat/nc tool that uses Network.framework.
 It supports TCP and UDP connections and listeners, with TLS/DTLS support.
*/

#include <Network/Network.h>

#include <err.h>
#include <getopt.h>

// Global Options
char *g_psk = NULL;			// TLS PSK
char *g_local_port = NULL;	// Local port flag
char *g_local_addr = NULL;	// Source Address
bool g_use_bonjour = false;	// Use Bonjour rather than hostnames
bool g_detached = false;	// Ignore stdin
bool g_listener = false;	// Create a listener
bool g_use_tls = false;		// Use TLS or DTLS
bool g_use_udp = false;		// Use UDP instead of TCP
bool g_verbose = false;		// Verbose
int g_family = AF_UNSPEC; 	// Required address family

nw_connection_t g_inbound_connection = NULL;

nw_listener_t create_and_start_listener(char *, char *);
nw_connection_t create_outbound_connection(const char *, const char *);
void start_connection(nw_connection_t connection);
void start_send_receive_loop(nw_connection_t connection);

#define NWCAT_BONJOUR_SERVICE_TCP_TYPE "_nwcat._tcp"
#define NWCAT_BONJOUR_SERVICE_UDP_TYPE "_nwcat._udp"
#define NWCAT_BONJOUR_SERVICE_DOMAIN "local"

void
print_usage(int ret)
{
	fprintf(stderr, "usage: nwcat [-46bdhltuv] [-k tls_psk] [-p source_port]\n");
	fprintf(stderr, "\t [-s source_ip_address] [hostname/service-name] [port]\n");
	if (ret != 0) {
		exit(ret);
	}
}

void
print_help(void)
{
	print_usage(0);
	fprintf(stderr, "\tCommand Summary:\n\
			\t-4		Use IPv4 only\n\
			\t-6		Use IPv6 only\n\
			\t-b		Use Bonjour Service rather than host/port\n\
			\t-d		Detach from stdin\n\
			\t-h		Print this help text\n\
			\t-k key\t	Use key as TLS PSK (requires -t)\n\
			\t-l		Create a listener to accept inbound connections\n\
			\t-p port\t	Use a local port for outbound connections\n\
			\t-s addr\t	Set local address for outbound connections\n\
			\t-t		Add TLS/DTLS as applicable\n\
			\t-u		Use UDP instead of TCP (and DTLS instead of TLS)\n\
			\t-v		Verbose\n"
			);
	exit(1);
}

int
main(int argc, char *argv[])
{
	int ch = 0;
	char *hostname = NULL;
	char *port = NULL;

	while ((ch = getopt(argc, argv,
						"46bdhk:lp:s:tuv")) != -1) {
		switch (ch) {
			case '4': {
				g_family = AF_INET;
				break;
			}
			case '6': {
				g_family = AF_INET6;
				break;
			}
			case 'b': {
				g_use_bonjour = true;
				break;
			}
			case 'd': {
				g_detached = true;
				break;
			}
			case 'h': {
				print_help();
				break;
			}
			case 'l': {
				g_listener = true;
				break;
			}
			case 'k': {
				g_psk = optarg;
				break;
			}
			case 'p': {
				g_local_port = optarg;
				break;
			}
			case 's': {
				g_local_addr = optarg;
				break;
			}
			case 't': {
				g_use_tls = true;
				break;
			}
			case 'u': {
				g_use_udp = true;
				break;
			}
			case 'v': {
				g_verbose = true;
				break;
			}
			case 0: {
				break;
			}
			default: {
				print_usage(1);
				break;
			}
		}
	}
	argc -= optind;
	argv += optind;

	// Validate options
	if (argv[0] && !argv[1]) {
		if (!g_listener && !g_use_bonjour) {
			warnx("Missing hostname and port");
			print_usage(1);
		}
		if (g_use_bonjour) {
			hostname = argv[0];
			port = NULL;
		} else {
			hostname = NULL;
			port = argv[0];
		}
	} else if (argv[0] && argv[1]) {
		if (!g_listener && g_use_bonjour) {
			warnx("Cannot set port for non-listening bonjour connection");
			print_usage(1);
		}
		hostname = argv[0];
		port = argv[1];
	} else {
		if (g_listener) {
			warnx("Missing port with option -l");
		}
		if (g_use_bonjour) {
			warnx("Missing bonjour name -b");
		}
		print_usage(1);
	}

	if (g_listener && g_local_addr) {
		errx(1, "Cannot use -s and -l");
	}
	if (g_listener && g_local_port) {
		errx(1, "Cannot use -p and -l");
	}

	if (g_psk && !g_use_tls) {
		errx(1, "Must use -t with -k");
	}

	if (g_listener && g_use_tls && !g_psk) {
		errx(1, "Must use -k if both -t and -l are specified");
	}

	if (g_listener) {
		nw_listener_t listener = create_and_start_listener(hostname, port);
		if (listener == NULL) {
			err(1, NULL);
		}

		dispatch_main();
	} else {
		nw_connection_t connection = connection = create_outbound_connection(hostname, port);
		if (connection == NULL) {
			err(1, NULL);
		}

		start_connection(connection);
		start_send_receive_loop(connection);
		dispatch_main();
	}

	// Unreached
}

/*
 * create_outbound_connection()
 * Returns a retained connection to a remote hostname and port.
 * Sets up TLS and local address/port as necessary.
 */
nw_connection_t
create_outbound_connection(const char *name, const char *port)
{
	// If we are using bonjour to connect, treat the name as a bonjour name
	// Otherwise, treat the name as a hostname
	nw_endpoint_t endpoint = (g_use_bonjour ?
							  nw_endpoint_create_bonjour_service(name,
																 (g_use_udp ? NWCAT_BONJOUR_SERVICE_UDP_TYPE : NWCAT_BONJOUR_SERVICE_TCP_TYPE),
																 NWCAT_BONJOUR_SERVICE_DOMAIN) :
							  nw_endpoint_create_host(name, port));
	nw_parameters_t parameters = NULL;

	nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
	if (g_use_tls) {
		if (g_psk) {
			configure_tls = ^(nw_protocol_options_t tls_options) {
				sec_protocol_options_t sec_options = nw_tls_copy_sec_protocol_options(tls_options);
				dispatch_data_t psk = dispatch_data_create(g_psk, strlen(g_psk), nil, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
				sec_protocol_options_add_pre_shared_key(sec_options, psk, psk);
				dispatch_release(psk);
				sec_protocol_options_add_tls_ciphersuite(sec_options, (SSLCipherSuite)TLS_PSK_WITH_AES_128_GCM_SHA256);
				nw_release(sec_options);
			};
		} else {
			configure_tls = NW_PARAMETERS_DEFAULT_CONFIGURATION;
		}
	}

	if (g_use_udp) {
		// Create a UDP connection
		parameters = nw_parameters_create_secure_udp(configure_tls,
													 NW_PARAMETERS_DEFAULT_CONFIGURATION);
	} else {
		// Create a TCP connection
		parameters = nw_parameters_create_secure_tcp(configure_tls,
													 NW_PARAMETERS_DEFAULT_CONFIGURATION);
	}

	nw_protocol_stack_t protocol_stack = nw_parameters_copy_default_protocol_stack(parameters);
	if (g_family == AF_INET || g_family == AF_INET6) {
		nw_protocol_options_t ip_options = nw_protocol_stack_copy_internet_protocol(protocol_stack);
		if (g_family == AF_INET) {
			// Force IPv4
			nw_ip_options_set_version(ip_options, nw_ip_version_4);
		} else if (g_family == AF_INET6) {
			// Force IPv6
			nw_ip_options_set_version(ip_options, nw_ip_version_6);
		}
		nw_release(ip_options);
	}
	nw_release(protocol_stack);

	// Bind to local address and port
	if (g_local_addr || g_local_port) {
		nw_endpoint_t local_endpoint = nw_endpoint_create_host(g_local_addr ? g_local_addr : "::", g_local_port ? g_local_port : "0");
		nw_parameters_set_local_endpoint(parameters, local_endpoint);
		nw_release(local_endpoint);
	}

	nw_connection_t connection = nw_connection_create(endpoint, parameters);
	nw_release(endpoint);
	nw_release(parameters);

	return connection;
}

/*
 * start_connection()
 * Schedule a connection on the main queue, process events, and
 * start the connection.
 */
void
start_connection(nw_connection_t connection)
{
	nw_connection_set_queue(connection, dispatch_get_main_queue());

	nw_retain(connection); // Hold a reference until cancelled
	nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
		nw_endpoint_t remote = nw_connection_copy_endpoint(connection);
		errno = error ? nw_error_get_error_code(error) : 0;
		if (state == nw_connection_state_waiting) {
			warn("connect to %s port %u (%s) failed, is waiting",
				 nw_endpoint_get_hostname(remote),
				 nw_endpoint_get_port(remote),
				 g_use_udp ? "udp" : "tcp");
		} else if (state == nw_connection_state_failed) {
			warn("connect to %s port %u (%s) failed",
				 nw_endpoint_get_hostname(remote),
				 nw_endpoint_get_port(remote),
				 g_use_udp ? "udp" : "tcp");
		} else if (state == nw_connection_state_ready) {
			if (g_verbose) {
				fprintf(stderr, "Connection to %s port %u (%s) succeeded!\n",
						nw_endpoint_get_hostname(remote),
						nw_endpoint_get_port(remote),
						g_use_udp ? "udp" : "tcp");
			}
		} else if (state == nw_connection_state_cancelled) {
			// Release the primary reference on the connection
			// that was taken at creation time
			nw_release(connection);
		}
		nw_release(remote);
	});

	nw_connection_start(connection);
}

/*
 * create_and_start_listener()
 * Returns a retained listener on a local port and optional address.
 * Sets up TLS as necessary.
 * Schedules listener on main queue and starts it.
 */
nw_listener_t
create_and_start_listener(char *name, char *port)
{
	nw_parameters_t parameters = NULL;

	nw_parameters_configure_protocol_block_t configure_tls = NW_PARAMETERS_DISABLE_PROTOCOL;
	if (g_use_tls) {
		if (g_psk) {
			configure_tls = ^(nw_protocol_options_t tls_options) {
				sec_protocol_options_t sec_options = nw_tls_copy_sec_protocol_options(tls_options);
				dispatch_data_t psk = dispatch_data_create(g_psk, strlen(g_psk), nil, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
				sec_protocol_options_add_pre_shared_key(sec_options, psk, psk);
				dispatch_release(psk);
				sec_protocol_options_add_tls_ciphersuite(sec_options, (SSLCipherSuite)TLS_PSK_WITH_AES_128_GCM_SHA256);
				nw_release(sec_options);
			};
		} else {
			configure_tls = NW_PARAMETERS_DEFAULT_CONFIGURATION;
		}
	}

	if (g_use_udp) {
		// Create a UDP listener
		parameters = nw_parameters_create_secure_udp(configure_tls,
													 NW_PARAMETERS_DEFAULT_CONFIGURATION);
	} else {
		// Create a TCP listener
		parameters = nw_parameters_create_secure_tcp(configure_tls,
													 NW_PARAMETERS_DEFAULT_CONFIGURATION);
	}

	nw_protocol_stack_t protocol_stack = nw_parameters_copy_default_protocol_stack(parameters);
	if (g_family == AF_INET || g_family == AF_INET6) {
		nw_protocol_options_t ip_options = nw_protocol_stack_copy_internet_protocol(protocol_stack);
		if (g_family == AF_INET) {
			// Force IPv4
			nw_ip_options_set_version(ip_options, nw_ip_version_4);
		} else if (g_family == AF_INET6) {
			// Force IPv6
			nw_ip_options_set_version(ip_options, nw_ip_version_6);
		}
		nw_release(ip_options);
	}
	nw_release(protocol_stack);

	// Bind to local address and port
	const char *address = g_use_bonjour ? NULL : name; // Treat name as local address if not bonjour
	if (address || port) {
		nw_endpoint_t local_endpoint = nw_endpoint_create_host(address ? address : "::", port ? port : "0");
		nw_parameters_set_local_endpoint(parameters, local_endpoint);
		nw_release(local_endpoint);
	}

	nw_listener_t listener = nw_listener_create(parameters);
	nw_release(parameters);

	if (g_use_bonjour && name != NULL) {
		// Advertise name over Bonjour
		nw_advertise_descriptor_t advertise = nw_advertise_descriptor_create_bonjour_service(name,
																							 (g_use_udp ? NWCAT_BONJOUR_SERVICE_UDP_TYPE : NWCAT_BONJOUR_SERVICE_TCP_TYPE),
																							 NWCAT_BONJOUR_SERVICE_DOMAIN);
		nw_listener_set_advertise_descriptor(listener, advertise);
		nw_release(advertise);

		nw_listener_set_advertised_endpoint_changed_handler(listener, ^(nw_endpoint_t _Nonnull advertised_endpoint, bool added) {
			if (g_verbose) {
				fprintf(stderr, "Listener %s on %s (%s.%s.%s)\n",
						added ? "added" : "removed",
						nw_endpoint_get_bonjour_service_name(advertised_endpoint),
						nw_endpoint_get_bonjour_service_name(advertised_endpoint),
						(g_use_udp ? NWCAT_BONJOUR_SERVICE_UDP_TYPE : NWCAT_BONJOUR_SERVICE_TCP_TYPE),
						NWCAT_BONJOUR_SERVICE_DOMAIN);
			}
		});
	}

	nw_listener_set_queue(listener, dispatch_get_main_queue());

	nw_retain(listener); // Hold a reference until cancelled
	nw_listener_set_state_changed_handler(listener, ^(nw_listener_state_t state, nw_error_t error) {
		errno = error ? nw_error_get_error_code(error) : 0;
		if (state == nw_listener_state_waiting) {
			if (g_verbose) {
				fprintf(stderr, "Listener on port %u (%s) waiting\n",
						nw_listener_get_port(listener),
						g_use_udp ? "udp" : "tcp");
			}
		} else if (state == nw_listener_state_failed) {
			warn("listener (%s) failed",
				 g_use_udp ? "udp" : "tcp");
		} else if (state == nw_listener_state_ready) {
			if (g_verbose) {
				fprintf(stderr, "Listener on port %u (%s) ready!\n",
						nw_listener_get_port(listener),
						g_use_udp ? "udp" : "tcp");
			}
		} else if (state == nw_listener_state_cancelled) {
			// Release the primary reference on the listener
			// that was taken at creation time
			nw_release(listener);
		}
	});

	nw_listener_set_new_connection_handler(listener, ^(nw_connection_t connection) {
		if (g_inbound_connection != NULL) {
			// We only support one connection at a time, so if we already
			// have one, reject the incoming connection.
			nw_connection_cancel(connection);
		} else {
			// Accept the incoming connection and start sending
			// and receiving on it.
			g_inbound_connection = connection;
			nw_retain(g_inbound_connection);

			start_connection(g_inbound_connection);
			start_send_receive_loop(g_inbound_connection);
		}
	});

	nw_listener_start(listener);

	return listener;
}

/*
 * receive_loop()
 * Perform a single read on the supplied connection, and write data to
 * stdout as it is received.
 * If no error is encountered, schedule another read on the same connection.
 */
void
receive_loop(nw_connection_t connection)
{
	nw_connection_receive(connection, 1, UINT32_MAX, ^(dispatch_data_t content, nw_content_context_t context, bool is_complete, nw_error_t receive_error) {

		nw_retain(context);
		dispatch_block_t schedule_next_receive = ^{
			// If the context is marked as complete, and is the final context,
			// we're read-closed.
			if (is_complete &&
				(context == NULL || nw_content_context_get_is_final(context))) {
				exit(0);
			}

			// If there was no error in receiving, request more data
			if (receive_error == NULL) {
				receive_loop(connection);
			}
			nw_release(context);
		};

		if (content != NULL) {
			// If there is content, write it to stdout asynchronously
			schedule_next_receive = Block_copy(schedule_next_receive);
			dispatch_write(STDOUT_FILENO, content, dispatch_get_main_queue(), ^(__unused dispatch_data_t _Nullable data, int stdout_error) {
				if (stdout_error != 0) {
					errno = stdout_error;
					warn("stdout write error");
				} else {
					schedule_next_receive();
				}
				Block_release(schedule_next_receive);
			});
		} else {
			// Content was NULL, so directly schedule the next receive
			schedule_next_receive();
		}
	});
}

/*
 * send_loop()
 * Start reading from stdin on a dispatch source, and send any bytes on the given connection.
 */
void
send_loop(nw_connection_t connection)
{
	if (!g_detached) {
		dispatch_read(STDIN_FILENO, 8192, dispatch_get_main_queue(), ^(dispatch_data_t _Nonnull read_data, int stdin_error) {
			if (stdin_error != 0) {
				errno = stdin_error;
				warn("stdin read error");
			} else if (read_data == NULL) {
				// NULL data represents EOF
				// Send a "write close" on the connection, by sending NULL data with the final message context marked as complete.
				// Note that it is valid to send with NULL data but a non-NULL context.
				nw_connection_send(connection, NULL, NW_CONNECTION_FINAL_MESSAGE_CONTEXT, true, ^(nw_error_t  _Nullable error) {
					if (error != NULL) {
						errno = nw_error_get_error_code(error);
						warn("write close error");
					}
					// Stop reading from stdin, so don't schedule another send_loop
				});
			} else {
				// Every send is marked as complete. This has no effect with the default message context for TCP,
				// but is required for UDP to indicate the end of a packet.
				nw_connection_send(connection, read_data, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, true, ^(nw_error_t  _Nullable error) {
					if (error != NULL) {
						errno = nw_error_get_error_code(error);
						warn("send error");
					} else {
						// Continue reading from stdin
						send_loop(connection);
					}
				});
			}
		});
	}
}

/*
 * start_send_receive_loop()
 * Start reading from stdin (when not detached) and from the given connection.
 * Every read on stdin becomes a send on the connection, and every receive on the
 * connection becomes a write on stdout.
 */
void
start_send_receive_loop(nw_connection_t connection)
{
	// Start reading from stdin
	send_loop(connection);

	// Start reading from connection
	receive_loop(connection);
}
