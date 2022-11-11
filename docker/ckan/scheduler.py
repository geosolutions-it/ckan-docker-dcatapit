import schedule
import time
import os
import logging

logging.basicConfig(format='%(asctime)s %(message)s', filename='/var/log/ckan/scheduler.log', level=logging.INFO)

def harvester_run():
    os.system('/usr/lib/ckan/venv/bin/ckan -c /etc/ckan/production.ini harvester run && touch /tmp/SCHEDULER_HARVESTER_RUN')
    logging.info('RAN command as ckan user: /usr/lib/ckan/venv/bin/ckan -c /etc/ckan/production.ini harvester run')

def report_broken_links():
    logging.info('RUNNING report broken links')
    os.system('/usr/lib/ckan/venv/bin/ckan -c /etc/ckan/production.ini report generate broken-links && touch /tmp/SCHEDULER_BROKEN_LINKS')
    logging.info('COMPLETED report broken links')

schedule.every(15).minutes.do(harvester_run)

schedule.every().day.at("01:00").do(report_broken_links)

while True:
    schedule.run_pending()
    time.sleep(1)