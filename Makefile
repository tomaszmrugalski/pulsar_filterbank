TARGETS=pulsar_filterbank_gps.py pulsar_filterbank_ntp.py pulsar_filterbank_none.py
PY=fb_helper.py
SOURCES=pulsar_filterbank.grc
DESTDIR=/usr/local/bin


all: $(TARGETS)

#
# First, build the UHD-sourced "branch" of the .GRC file
#
pulsar_filterbank_uhd.grc: pulsar_filterbank.grc
	./grc_parser.py pulsar_filterbank.grc pulsar_filterbank_uhd.grc uhd_edits.txt

#
# Then the OSMO-sourced "branch" of the .GRC file
#
pulsar_filterbank_osmo.grc: pulsar_filterbank.grc
	./grc_parser.py pulsar_filterbank.grc pulsar_filterbank_osmo.grc osmo_edits.txt

#
# Then the corresponding .py files
#
pulsar_filterbank_uhd.py: pulsar_filterbank_uhd.grc

	-grcc -d . pulsar_filterbank_uhd.grc

pulsar_filterbank_osmo.py: pulsar_filterbank_osmo.grc
	-grcc -d . pulsar_filterbank_osmo.grc

#
# Now edit the resulting .py code to include appropriate time-sync primitives
#
pulsar_filterbank_gps.py: pulsar_filterbank_uhd.py
	cp pulsar_filterbank_uhd.py pulsar_filterbank_gps.py
# Insert the synchronization code (if it's a UHD source)
	-./insert_sync_code pulsar_filterbank_gps.py gps uhd_radio
# Insert the update-header code right after 'tb.wait' in the flow-graph
#  Should probably have something that does automatic indent detection and
#  arranges for the inserted code to follow the existing indent.
#
	-./insert_arbitrary_code pulsar_filterbank_gps.py '    tb.wait()'    '    fb_helper.update_header(None, None)'

pulsar_filterbank_ntp.py: pulsar_filterbank_uhd.py
	cp pulsar_filterbank_uhd.py pulsar_filterbank_ntp.py
# Insert the synchronization code (if it's a UHD source)
	-./insert_sync_code pulsar_filterbank_ntp.py host uhd_radio
# Insert the update-header code right after 'tb.wait' in the flow-graph
#  Should probably have something that does automatic indent detection and
#  arranges for the inserted code to follow the existing indent.
#
	-./insert_arbitrary_code pulsar_filterbank_ntp.py '    tb.wait()'    '    fb_helper.update_header(None, None)'

#
# No sync code for this, and might as well just build for osmo source, since
#  USRP is accessible through OSMO as well, just no sync primitives
#
pulsar_filterbank_none.py: pulsar_filterbank_osmo.py
	cp pulsar_filterbank_osmo.py pulsar_filterbank_none.py
#
# Insert the update-header code right after 'tb.wait' in the flow-graph
#  Should probably have something that does automatic indent detection and
#  arranges for the inserted code to follow the existing indent.
#
	-./insert_arbitrary_code pulsar_filterbank_none.py '    tb.wait()'    '    fb_helper.update_header(None, None)'


install: $(TARGETS) $(PY)
	cp $(TARGETS) $(PY) $(DESTDIR)

clean:
	rm -f pulsar_filterbank*.py
	rm -f pulsar_filterbank_uhd.grc pulsar_filterbank_osmo.grc
	rm -f *.header *.fil *.csv
