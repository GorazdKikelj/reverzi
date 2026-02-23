# Configures log formatters to log messages to the log file
import logging

logger = logging.getLogger("reverz")
logging.basicConfig(
    filename="reverz.log",
    filemode="a",
    format="%(asctime)s : %(levelname)s : %(module)s %(lineno)d : %(message)s",
    level=logging.DEBUG,
)
# logging.basicConfig(format='%(asctime)s : %(levelname)s : %(module)s %(lineno)d : %(process)d - %(thread)d : %(message)s', level=logging.DEBUG)
