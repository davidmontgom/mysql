

"""
                                uuid is_alive    status is_not_running is_not_configured io_not_running sql_not_running io_error sql_error
------------------------------------ -------- --------- -------------- ----------------- -------------- --------------- -------- ---------
6993d13d-b886-11e5-891c-040199a33801        1   PRIMARY              0                 0              0               0    False     False
8288ef6c-b95b-11e5-8c16-04019a190501        1 SECONDARY              0                 0              0               0    False     False


                         server_uuid            address    status       mode weight
------------------------------------ ------------------ --------- ---------- ------
6993d13d-b886-11e5-891c-040199a33801 198.211.97.48:3306   PRIMARY READ_WRITE    1.0
8288ef6c-b95b-11e5-8c16-04019a190501 208.68.36.188:3306 SECONDARY  READ_ONLY    1.0



"""


import subprocess
#s=subprocess.check_output(["mysqlfabric group lookup_servers druid"])

status = """
                         server_uuid            address    status       mode weight
------------------------------------ ------------------ --------- ---------- ------
6993d13d-b886-11e5-891c-040199a33801 198.211.97.48:3306   PRIMARY READ_WRITE    1.0
8288ef6c-b95b-11e5-8c16-04019a190501 208.68.36.188:3306 SECONDARY  READ_ONLY    1.0
"""

primary = status.split('\n')[3]
primary = primary.split(' ')[1].split(':')[0].strip()
print primary







