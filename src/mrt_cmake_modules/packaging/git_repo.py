import os
import shutil
import subprocess


class GitRepo():
    def __init__(self, repo_dir, repo_url):
        self.repo_dir = repo_dir
        self.repo_url = repo_url
        self._execute_git_command(['clone', self.repo_url, '.'])

    def switch_to_branch(self, branch_name):
        self._execute_git_command(['checkout', branch_name])

    def commit(self, message):
        self._execute_git_command(['add', '--all'])
        self._execute_git_command(['commit', '-m', message])

    def push(self):
        self._execute_git_command(['push', '--all'])
        self._execute_git_command(['push', '--tags'])

    def merge(self, branch):
        self._execute_git_command(['merge', '--no-edit', branch])

    def tag(self, tag):
        self._execute_git_command(['tag', tag])

    def clear(self):
        for f in os.listdir(self.repo_dir):
            if (f == ".git"):
                continue

            path = os.path.join(self.repo_dir, f)
            if (os.path.isfile(path)):
                os.remove(path)
            else:
                shutil.rmtree(path)

    def get_head_tag(self):
        return self._execute_git_command_get(['tag', '--points-at', 'HEAD'])

    def is_dirty(self):
        changed_files = self._execute_git_command_get(['status', '--porcelain'])
        return bool(changed_files)

    def _execute_git_command(self, command):
        subprocess.check_call(['git', '-C', self.repo_dir] + command)

    def _execute_git_command_get(self, command):
        return subprocess.check_output(['git', '-C', self.repo_dir] + command)
