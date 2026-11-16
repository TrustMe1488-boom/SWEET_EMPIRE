"""Three real application boots, including a shop purchase before Continue; no camera."""
import json
import msvcrt
import os
import subprocess
import time
import uuid
from run_godot_tests import GODOT, PROJECT, ensure_no_godot
from owned_process import OwnedProcess
from test_godot_result import classify


def main():
    root = PROJECT / '.local/testing/python'
    root.mkdir(parents=True, exist_ok=True)
    with (root / 'runner.lock').open('a+b') as lock:
        if lock.tell() == 0:
            lock.write(b'0'); lock.flush()
        lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        try:
            ensure_no_godot()
            directory = root / uuid.uuid4().hex
            directory.mkdir()
            script = directory / 'boot_session.gd'
            script.write_text((PROJECT / 'tests/harness_fixtures/boot_session.gd.txt').read_text(encoding='utf-8'), encoding='utf-8')
            scene = directory / 'boot_session.tscn'
            resource = 'res://' + script.relative_to(PROJECT).as_posix()
            scene.write_text(f'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="{resource}" id="1"]\n[node name="BootTest" type="Node"]\nscript = ExtResource("1")\n', encoding='utf-8')
            environment = os.environ.copy()
            environment['APPDATA'] = str(directory / 'AppData')
            environment['LOCALAPPDATA'] = str(directory / 'LocalAppData')
            results = []
            for index in range(3):
                ensure_no_godot()
                logs = directory / str(index); logs.mkdir()
                started = time.time_ns()
                ownership = None
                process = None
                code, error, timeout = None, '', False
                try:
                    with (logs/'stdout.log').open('xb') as stdout, (logs/'stderr.log').open('xb') as stderr:
                        process = subprocess.Popen([str(GODOT),'--headless','--path',str(PROJECT),'--log-file',str(logs/'godot.log'),'res://'+scene.relative_to(PROJECT).as_posix()], stdout=stdout,stderr=stderr,stdin=subprocess.DEVNULL,env=environment,shell=False,creationflags=subprocess.CREATE_NO_WINDOW|4)
                        ownership = OwnedProcess(process)
                        try:
                            code = process.wait(timeout=30)
                        except subprocess.TimeoutExpired:
                            timeout = True
                            ownership.terminate()
                            code = process.wait(timeout=5)
                except Exception as exc:
                    error = str(exc)
                finally:
                    if ownership is not None: ownership.close()
                    if process is not None and process.poll() is None:
                        process.kill(); process.wait(timeout=5)
                result = classify(stdout_path=logs/'stdout.log',stderr_path=logs/'stderr.log',log_path=logs/'godot.log',marker='BOOT_RESULT',started_ns=started,exit_code=code,timed_out=timeout,launch_error=error)
                text = (logs/'stdout.log').read_text(encoding='utf-8')
                expected = 'BOOT_RESTORED: ' + ('true' if index else 'false')
                if expected not in text:
                    result['passed'] = False
                    result['reasons'].append('Unexpected boot/restore phase')
                result['exit_code'] = code
                results.append(result)
                (logs/'result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
                print(index,result,flush=True)
            (directory/'summary.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
            print('Artifacts:',directory)
            ensure_no_godot()
            return 0 if all(r['passed'] for r in results) else 1
        finally:
            lock.seek(0)
            msvcrt.locking(lock.fileno(),msvcrt.LK_UNLCK,1)


if __name__ == '__main__':
    raise SystemExit(main())
