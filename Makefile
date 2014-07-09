python := "$(shell { command -v python2.7 || command -v python; } 2>/dev/null)"

# Set the relative path to installed binaries under the project virtualenv.
# NOTE: Creating a virtualenv on Windows places binaries in the 'Scripts' directory.
bin_dir := $(shell $(python) -c 'import sys; bin = "Scripts" if sys.platform == "win32" else "bin"; print(bin)')
env_bin := env/$(bin_dir)
export PATH := $(env_bin):$(PATH)
venv := "./vendor/virtualenv-1.11.6.py"
test_env_files := defaults.env,tests/test.env,tests/local.env
py_test := honcho -e $(test_env_files) run py.test

env: requirements.txt requirements_tests.txt setup.py
	$(python)  $(venv)\
				--unzip-setuptools \
				--prompt="[gittip] " \
				--never-download \
				--extra-search-dir=./vendor/ \
				--distribute \
				./env/
	pip install -r requirements.txt
	pip install -r requirements_tests.txt
	pip install -e ./

clean:
	rm -rf env *.egg *.egg-info
	find . -name \*.pyc -delete

schema: env
	honcho -e defaults.env,local.env run ./recreate-schema.sh

data:
	honcho -e defaults.env,local.env run fake_data fake_data

run: env
	honcho -e defaults.env,local.env run web

py: env
	honcho -e defaults.env,local.env run python

test-schema: env
	honcho -e $(test_env_files) run ./recreate-schema.sh

pyflakes: env
	pyflakes bin gittip tests

test: test-schema pytest jstest

pytest: env
	$(py_test) --cov gittip ./tests/py/
	@$(MAKE) --no-print-directory pyflakes

retest: env
	$(py_test) ./tests/py/ --lf
	@$(MAKE) --no-print-directory pyflakes

test-cov: env
	$(py_test) --cov-report html --cov gittip ./tests/py/

tests: test

node_modules: package.json
	npm install
	@if [ -d node_modules ]; then touch node_modules; fi

jstest: node_modules
	./node_modules/.bin/grunt test
