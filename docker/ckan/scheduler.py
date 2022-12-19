import schedule
import time
import os
import logging
logging.basicConfig(format='%(asctime)s %(message)s', filename='/var/log/ckan/scheduler.log', level=logging.INFO)

def harvester_run():
    logging.info('Running command as ckan user: /usr/lib/ckan/venv/bin/ckan -c /etc/ckan/ckan.ini harvester run')
    os.system('/usr/lib/ckan/venv/bin/ckan -c /etc/ckan/ckan.ini harvester run && touch /tmp/SCHEDULER_harvester_run')
    logging.info('Completed command as ckan user: /usr/lib/ckan/venv/bin/ckan -c /etc/ckan/ckan.ini harvester run')

schedule.every(15).minutes.do(harvester_run)

def pycsw_synch():
    logging.info('Running pycsw sync')
    os.system('/usr/lib/ckan/pycsw-venv/bin/python /ckan_pycsw.py load -p /etc/pycsw/pycsw.cfg --ckan_url http://ckan:5000/  && touch /tmp/SCHEDULER_pycsw_synch')
    logging.info('Completed pycsw sync')

schedule.every(15).minutes.do(pycsw_synch)

while True:
    schedule.run_pending()
    time.sleep(1*60)  # argument in seconds