#!/usr/bin/env python
# This Python file uses the following encoding: utf-8

import argparse
import os
import sys
import subprocess

from catkin.test_results import ensure_junit_result_exist, remove_junit_result

def main(argv=sys.argv[1:]):
    parser = argparse.ArgumentParser(description='Runs the test command passed as an argument and verifies that the expected result file has been generated.')
    parser.add_argument('results', help='The path to the xunit result file')
    parser.add_argument('command', nargs='+', help='The test command to execute')
    parser.add_argument('--working-dir', nargs='?', help='The working directory for the executed command')
    parser.add_argument('--coverage-dir', nargs='?', help='The directory where coverage data should be generated')
    parser.add_argument('--return-code', action='store_true', help='Set the return code based on the success of the test command')
    parser.add_argument('--redirect-stderr', action='store_true', help='Redirect stderr to stdout')
    args = parser.parse_args(argv)

    remove_junit_result(args.results)

    try:
        os.mkdir(os.path.dirname(args.results))
    except OSError:
        pass

    work_dir_msg = ' with working directory "%s"' % args.working_dir if args.working_dir is not None else ''
    cmds_msg = ''.join(['\n  %s' % cmd for cmd in args.command])
    print('-- run_test.py: execute commands%s%s' % (work_dir_msg, cmds_msg))

    if args.coverage_dir:
        env = os.environ.copy()
        print("Coverage goes to {}".format(args.coverage_dir))
        env['GCOV_PREFIX'] = args.coverage_dir
        if not os.path.exists(args.coverage_dir):
            os.mkdir(args.coverage_dir)
        #strip = os.path.commonprefix([args.coverage_dir, args.results]).count('/')
        #env['GCOV_PREFIX_STRIP'] = str(strip)
    else:
        env = os.environ

    rc = 0
    for cmd in args.command:
        stderr = sys.stderr if not args.redirect_stderr else sys.stdout
        rc = subprocess.call(cmd, cwd=args.working_dir, shell=True, env=env, stderr=stderr)
        if rc:
            break

    print('-- run_test.py: verify result "%s"' % args.results)
    no_errors = ensure_junit_result_exist(args.results)
    if not no_errors:
        rc = 1

    if args.return_code:
        return rc
    return 0


if __name__ == '__main__':
    sys.exit(main())
