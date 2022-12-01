import schedule
import time
import os
import logging
logging.basicConfig(format='%(asctime)s %(message)s', filename='/var/log/ckan/scheduler.log', level=logging.INFO)

def job():
    os.system('/usr/lib/ckan/venv/bin/ckan -c /etc/ckan/ckan.ini harvester run && touch /tmp/CRONOK')
    logging.info('RAN command as ckan user: /usr/lib/ckan/venv/bin/ckan -c /etc/ckan/ckan.ini harvester run')

schedule.every(15).minutes.do(job)

while True:
    schedule.run_pending()
    time.sleep(1)