import os
import logging

# Create a logger object
log = logging.getLogger()

# Create a console handler
console_handler = logging.StreamHandler()

# Define the format for the logs
format_string = '%(asctime)s\t[%(levelname)s] -- %(message)s'
console_handler.setFormatter(logging.Formatter(format_string))

# Add the console handler to the logger
log.addHandler(console_handler)

# Set the logging level based on an environment variable
log_level = os.getenv('LOG_LEVEL', 'INFO').upper()
log.setLevel(
    {
        'DEBUG': logging.DEBUG,
        'INFO': logging.INFO,
        'WARN': logging.WARN,
        'ERROR': logging.ERROR,
        'CRITICAL': logging.CRITICAL,
    }.get(log_level, logging.INFO)
)