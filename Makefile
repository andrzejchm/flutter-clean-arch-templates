.PHONY : check format_code unit_tests prepare_unit_tests calc_unit_test
package := picnic_app
file := test/coverage_helper_test.dart

pub_upgrade:
	@for dir in `find . -name "*hooks" -type d` ; do \
		pushd $$dir ; fvm flutter pub upgrade ; popd ; \
	done
	@pushd template_utils; fvm flutter pub upgrade; popd


