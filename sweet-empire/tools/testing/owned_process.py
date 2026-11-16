"""Windows job ownership for Godot's console launcher and its engine child."""
import ctypes
from ctypes import wintypes


class OwnedProcess:
    def __init__(self, process):
        self.api = ctypes.WinDLL('kernel32', use_last_error=True)
        signatures = {
            'CreateJobObjectW': ([ctypes.c_void_p, wintypes.LPCWSTR], wintypes.HANDLE),
            'AssignProcessToJobObject': ([wintypes.HANDLE, wintypes.HANDLE], wintypes.BOOL),
            'TerminateJobObject': ([wintypes.HANDLE, wintypes.UINT], wintypes.BOOL),
            'CloseHandle': ([wintypes.HANDLE], wintypes.BOOL),
            'CreateToolhelp32Snapshot': ([wintypes.DWORD, wintypes.DWORD], wintypes.HANDLE),
            'OpenThread': ([wintypes.DWORD, wintypes.BOOL, wintypes.DWORD], wintypes.HANDLE),
            'ResumeThread': ([wintypes.HANDLE], wintypes.DWORD),
        }
        for name, (args, result) in signatures.items():
            method = getattr(self.api, name)
            method.argtypes, method.restype = args, result
        self.handle = self.api.CreateJobObjectW(None, None)
        if not self.handle:
            raise ctypes.WinError(ctypes.get_last_error())
        try:
            if not self.api.AssignProcessToJobObject(self.handle, wintypes.HANDLE(int(process._handle))):
                raise ctypes.WinError(ctypes.get_last_error())
            self._resume(process.pid)
        except BaseException:
            self.close()
            raise

    def _resume(self, pid):
        class ThreadEntry(ctypes.Structure):
            _fields_ = [('size', wintypes.DWORD), ('usage', wintypes.DWORD),
                        ('id', wintypes.DWORD), ('owner', wintypes.DWORD),
                        ('priority', wintypes.LONG), ('delta', wintypes.LONG),
                        ('flags', wintypes.DWORD)]
        for name in ('Thread32First', 'Thread32Next'):
            method = getattr(self.api, name)
            method.argtypes = [wintypes.HANDLE, ctypes.POINTER(ThreadEntry)]
            method.restype = wintypes.BOOL
        snapshot = self.api.CreateToolhelp32Snapshot(4, 0)
        if snapshot == ctypes.c_void_p(-1).value:
            raise ctypes.WinError(ctypes.get_last_error())
        try:
            entry = ThreadEntry()
            entry.size = ctypes.sizeof(entry)
            ok = self.api.Thread32First(snapshot, ctypes.byref(entry))
            while ok:
                if entry.owner == pid:
                    thread = self.api.OpenThread(2, False, entry.id)
                    if not thread:
                        raise ctypes.WinError(ctypes.get_last_error())
                    try:
                        if self.api.ResumeThread(thread) == 0xFFFFFFFF:
                            raise ctypes.WinError(ctypes.get_last_error())
                        return
                    finally:
                        self.api.CloseHandle(thread)
                ok = self.api.Thread32Next(snapshot, ctypes.byref(entry))
            raise RuntimeError('Suspended Godot main thread not found')
        finally:
            self.api.CloseHandle(snapshot)

    def terminate(self):
        if self.handle and not self.api.TerminateJobObject(self.handle, 1):
            raise ctypes.WinError(ctypes.get_last_error())

    def close(self):
        if self.handle:
            try:
                self.terminate()
            finally:
                self.api.CloseHandle(self.handle)
                self.handle = None
