# CMake generated Testfile for 
# Source directory: /home/reriosto/SHiP/ej200
# Build directory: /home/reriosto/SHiP/event_display_ej204_ej230/build/ej204
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(smoke_test "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/ej200_bar_sim" "-m" "macros/test.mac")
set_tests_properties(smoke_test PROPERTIES  PASS_REGULAR_EXPRESSION "=== EJ Scintillator Bar Run Summary ===" TIMEOUT "120" _BACKTRACE_TRIPLES "/home/reriosto/SHiP/ej200/CMakeLists.txt;29;add_test;/home/reriosto/SHiP/ej200/CMakeLists.txt;0;")
add_test(edge_scan_smoke "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/ej200_bar_sim" "-m" "macros/edge_scan_smoke.mac")
set_tests_properties(edge_scan_smoke PROPERTIES  PASS_REGULAR_EXPRESSION "=== EJ Scintillator Bar Run Summary ===" TIMEOUT "1200" _BACKTRACE_TRIPLES "/home/reriosto/SHiP/ej200/CMakeLists.txt;34;add_test;/home/reriosto/SHiP/ej200/CMakeLists.txt;0;")
add_test(sslg4_properties_check "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/physics_baseline_check")
set_tests_properties(sslg4_properties_check PROPERTIES  _BACKTRACE_TRIPLES "/home/reriosto/SHiP/ej200/CMakeLists.txt;42;add_test;/home/reriosto/SHiP/ej200/CMakeLists.txt;0;")
add_test(readout_config_check "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/readout_config_check")
set_tests_properties(readout_config_check PROPERTIES  _BACKTRACE_TRIPLES "/home/reriosto/SHiP/ej200/CMakeLists.txt;47;add_test;/home/reriosto/SHiP/ej200/CMakeLists.txt;0;")
add_test(export_endtop_gdml "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/export_endtop_gdml" "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/endtop_geometry.gdml")
set_tests_properties(export_endtop_gdml PROPERTIES  _BACKTRACE_TRIPLES "/home/reriosto/SHiP/ej200/CMakeLists.txt;52;add_test;/home/reriosto/SHiP/ej200/CMakeLists.txt;0;")
add_test(endtop_gdml_check "/usr/bin/python3.12" "/home/reriosto/SHiP/ej200/tests/check_endtop_gdml.py" "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/endtop_geometry.gdml")
set_tests_properties(endtop_gdml_check PROPERTIES  DEPENDS "export_endtop_gdml" _BACKTRACE_TRIPLES "/home/reriosto/SHiP/ej200/CMakeLists.txt;56;add_test;/home/reriosto/SHiP/ej200/CMakeLists.txt;0;")
add_test(endtop_balance_smoke "/usr/bin/python3.12" "/home/reriosto/SHiP/ej200/tests/check_endtop_balance.py" "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/ej200_bar_sim" "/home/reriosto/SHiP/event_display_ej204_ej230/build/ej204/macros/endtop_smoke_center.mac")
set_tests_properties(endtop_balance_smoke PROPERTIES  TIMEOUT "300" _BACKTRACE_TRIPLES "/home/reriosto/SHiP/ej200/CMakeLists.txt;61;add_test;/home/reriosto/SHiP/ej200/CMakeLists.txt;0;")
subdirs("src/external/OPSimTool")
subdirs("src/external/SSLG4")
